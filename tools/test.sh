#!/bin/bash
# Runs the tests in tiers, so a change is checked by what it could break rather than by all
# 3,300 tests every time (James, round 397: "we should have smaller test suites, or pieces of
# the test suite that run when needed. We then run the full test suite before a big build or
# every so often").
#
#   tools/test.sh quick              everything but tools/slow-tests.txt - about 10 minutes
#   tools/test.sh match WORD...      every class whose name contains a WORD, any case:
#                                    `match Mirror Safety` while working on the paddle twins
#   tools/test.sh only CLASS...      exactly these classes
#   tools/test.sh sweeps             the whole-family sweeps (see CLAUDE.md) - about 12 minutes
#   tools/test.sh full               everything - about 20 minutes; before a build goes to
#                                    Xcode Cloud for review, after shared code changes, and
#                                    every few rounds regardless. Two runs at once: everything
#                                    but the sweeps on the iPhone 16 Pro, split across clones of
#                                    it by Xcode's parallel testing, and the sweeps - single
#                                    tests of minutes each, which do not share processors well -
#                                    on their own on the iPhone 17 Pro (round 398)
#   tools/test.sh serial             everything, one test at a time, on the iPhone 16 Pro - the
#                                    old way, about 40 minutes, for when a parallel failure needs
#                                    ruling out
#
# Full runs on the iPhone 16 Pro (iOS 18.5) and the rest on the iPhone 17 Pro (iOS 26.5), each
# with its own derived data, so a targeted run can go on beside a full one. Never install the
# app on one simulator while the other is running tests (CLAUDE.md).
#
# Writes the log to $TEST_LOG_DIR (default /tmp/gigaball-tests) and reads it the way CLAUDE.md
# says to: the count of `passed` lines, the `Failing tests:` list and the relaunch count, not
# the summary's total. Stops xcodebuild itself once the run has finished, because it sometimes
# sits there afterwards for ever.
set -u
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
FULL_DEST='id=6C4F510D-FAC7-42B0-98CE-258809ABA4B7'
WORK_DEST='id=5E5D91D9-3BAE-4A61-AE34-CBFD2361FBB9'
SWEEPS="DrawnWhereSolidTests PaddlePowerUpsEndCleanlyTests BricksDrawnWhereSolidTests
EveryPowerUpShowsSavesAndEndsTests EveryPowerUpIsHeardTests EveryBrickHitIsHeardTests
LongPlaySessionTests EveryDailyTwistPlaysTests BricksSaveAndResumeTests
MenuScreensFitEverySizeTests ResumeIsTheSameGameTests EveryFallingPowerUpSurvivesAResumeTests"
LOG_DIR=${TEST_LOG_DIR:-/tmp/gigaball-tests}
mkdir -p "$LOG_DIR"

mode=${1:-quick}
shift || true
dest=$WORK_DEST
data="$LOG_DIR/derived-work"
picked=()

all_classes() {
    grep -hoE '^(final )?class [A-Za-z0-9_]+: XCTestCase' GigaBallTests/*.swift \
        | sed -E 's/^(final )?class ([A-Za-z0-9_]+):.*/\2/' | sort -u
}

# Runs one xcodebuild into a log, and stops it once its tests are over - it sometimes sits there
# afterwards for ever
run() {
    local log=$1; shift
    xcodebuild -project Megaball.xcodeproj -scheme Megaball "$@" test > "$log" 2>&1 &
    local build=$!
    while kill -0 "$build" 2>/dev/null; do
        if grep -qE "\*\* TEST (SUCCEEDED|FAILED) \*\*|\*\* BUILD FAILED \*\*" "$log"; then
            sleep 5; kill "$build" 2>/dev/null; break
        fi
        if grep -qE "Test Suite '(All tests|Selected tests)' (passed|failed) at" "$log"; then
            sleep 20; kill "$build" 2>/dev/null; break
        fi
        sleep 5
    done
    wait "$build" 2>/dev/null
}

# Reads a log: passed, relaunches, failures and their messages. Returns 1 on any failure.
report() {
    local log=$1 name=$2
    local passed relaunches failing
    passed=$(grep -c "' passed " "$log")
    relaunches=$(grep -c "Restarting after unexpected exit" "$log")
    echo "$name: passed $passed   relaunches $relaunches"
    if grep -q "BUILD FAILED\|The following build commands failed" "$log" || { [ "$passed" -eq 0 ] && ! grep -q "' failed" "$log"; }; then
        # A test build that fails says TEST FAILED, not BUILD FAILED, and runs nothing - which
        # read as "all passed" until round 398. No test passing is never a pass
        grep -E "error: " "$log" | head -20
        echo "$name: BUILD FAILED, or nothing ran"
        return 1
    fi
    # A relaunch is the test host dying mid-test. Round 398 found the harness then *skips* the
    # test it died in - no failed line, no Failing tests entry - and this said "all passed"
    # over a real crash. So name what was running each time, with any Swift fatal error
    # printed before it: no fatal error is usually the audio trap (CLAUDE.md), and a fatal
    # error never is
    local died
    died=$(awk '
        /Test Case .* started/ { running = $0 }
        /Fatal error:/ && fatal == "" { fatal = $0 }
        /Restarting after unexpected exit/ {
            sub(/.*\[GigaBallTests\./, "", running); sub(/\].*/, "", running); sub(/ /, ".", running)
            print running (fatal != "" ? "  DIED: " substr(fatal, 1, 200) : "  (no fatal error - re-run it alone)")
            fatal = ""
        }' "$log")
    if [ -n "$died" ]; then
        echo "$name: the test host died in:"
        echo "$died" | sed 's/^/  /'
    fi
    failing=$( { grep "' failed (" "$log" | sed -E "s/.*\[GigaBallTests\.([A-Za-z0-9_]+) ([A-Za-z0-9_]+)\].*/\1.\2/"
                 grep "' failed on '" "$log" | sed -E "s/^Test case '([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)\(\)'.*/\1.\2/"
                 echo "$died" | grep "DIED" | cut -d' ' -f1; } | grep -v '^$' | sort -u)
    [ -z "$failing" ] && return 0
    echo "$name failing:"
    echo "$failing" | sed 's/^/  /'
    grep -E "error: -\[" "$log" | sed -E 's/.*\] : //' | cut -c1-240 | head -30
    local bundle
    bundle=$(grep -oE "/[^ ]+\.xcresult" "$log" | tail -1)
    if [ -n "$bundle" ] && grep -q "failed on '" "$log"; then
        xcrun xcresulttool get test-results tests --path "$bundle" 2>/dev/null | python3 -c '
import json, sys
def walk(node, failed=False):
    failed = failed or (node.get("nodeType") == "Test Case" and node.get("result") == "Failed")
    if failed and node.get("nodeType") == "Failure Message":
        print("  " + node.get("name", "")[:240])
    for child in node.get("children", []):
        walk(child, failed)
for node in json.load(sys.stdin).get("testNodes", []):
    walk(node)' | head -30
        # A parallel run does not print its assertion messages; the result bundle has them
    fi
    [ "$relaunches" -gt 0 ] && echo "(a relaunch can name a test that never failed an assertion - re-run that class alone before believing it; CLAUDE.md)"
    return 1
}

stamp=$(date +%Y%m%d-%H%M%S)
case $mode in
    quick)
        while read -r _ _ name; do picked+=("-skip-testing:GigaBallTests/$name"); done \
            < tools/slow-tests.txt ;;
    match)
        [ $# -gt 0 ] || { echo "match needs at least one word"; exit 2; }
        for word in "$@"; do
            while read -r name; do picked+=("-only-testing:GigaBallTests/$name"); done \
                < <(all_classes | grep -i -- "$word")
        done
        [ ${#picked[@]} -gt 0 ] || { echo "no test class matches: $*"; exit 2; }
        echo "classes: ${picked[*]//-only-testing:GigaBallTests\//}" ;;
    only)
        [ $# -gt 0 ] || { echo "only needs at least one class"; exit 2; }
        for name in "$@"; do picked+=("-only-testing:GigaBallTests/$name"); done ;;
    sweeps)
        for name in $SWEEPS; do picked+=("-only-testing:GigaBallTests/$name"); done ;;
    serial)
        dest=$FULL_DEST
        data="$LOG_DIR/derived-full" ;;
    full)
        rest=() sweeps=()
        for name in $SWEEPS; do
            rest+=("-skip-testing:GigaBallTests/$name")
            sweeps+=("-only-testing:GigaBallTests/$name")
        done
        main_log="$LOG_DIR/full-main-$stamp.log"
        sweep_log="$LOG_DIR/full-sweeps-$stamp.log"
        echo "running full: $main_log and $sweep_log"
        run "$main_log" -destination "$FULL_DEST" -derivedDataPath "$LOG_DIR/derived-full" \
            -parallel-testing-enabled YES -parallel-testing-worker-count 3 "${rest[@]}" &
        main=$!
        run "$sweep_log" -destination "$WORK_DEST" -derivedDataPath "$LOG_DIR/derived-work" \
            "${sweeps[@]}" &
        wait $main; wait
        status=0
        report "$main_log" "main" || status=1
        report "$sweep_log" "sweeps" || status=1
        [ $status -eq 0 ] && echo "all passed"
        exit $status ;;
    *)
        sed -n '2,32p' "$0"; exit 2 ;;
esac

log="$LOG_DIR/$mode-$stamp.log"
echo "running $mode, log: $log"
run "$log" -destination "$dest" -derivedDataPath "$data" ${picked[@]+"${picked[@]}"}
report "$log" "$mode" && echo "all passed"
