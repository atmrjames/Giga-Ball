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
#   tools/test.sh full               everything - about 40 minutes; before a build goes to
#                                    Xcode Cloud for review, after shared code changes, and
#                                    every few rounds regardless
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
EveryPowerUpShowsSavesAndEndsTests EveryPowerUpIsHeardTests EveryBrickHitIsHeardTests"
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
    full)
        dest=$FULL_DEST
        data="$LOG_DIR/derived-full" ;;
    *)
        sed -n '2,25p' "$0"; exit 2 ;;
esac

log="$LOG_DIR/$mode-$(date +%Y%m%d-%H%M%S).log"
echo "running $mode, log: $log"
xcodebuild -project Megaball.xcodeproj -scheme Megaball -destination "$dest" \
    -derivedDataPath "$data" test ${picked[@]+"${picked[@]}"} > "$log" 2>&1 &
build=$!
while kill -0 "$build" 2>/dev/null; do
    if grep -qE "\*\* TEST (SUCCEEDED|FAILED) \*\*|\*\* BUILD FAILED \*\*" "$log"; then
        sleep 5
        kill "$build" 2>/dev/null
        break
    fi
    if grep -qE "Test Suite '(All tests|Selected tests)' (passed|failed) at" "$log"; then
        sleep 20
        kill "$build" 2>/dev/null
        break
    fi
    sleep 5
done
wait "$build" 2>/dev/null

passed=$(grep -c "' passed " "$log")
relaunches=$(grep -c "Restarting after unexpected exit" "$log")
echo "passed: $passed   relaunches: $relaunches"
if grep -q "BUILD FAILED" "$log"; then
    grep -E "error: " "$log" | head -20
    echo "BUILD FAILED"
    exit 1
fi
failing=$(grep "' failed (" "$log" | sed -E "s/.*\[GigaBallTests\.([A-Za-z0-9_]+) ([A-Za-z0-9_]+)\].*/\1.\2/" | sort -u)
if [ -n "$failing" ]; then
    echo "failing:"
    echo "$failing" | sed 's/^/  /'
    grep -E "error: -\[" "$log" | sed -E 's/.*\] : //' | cut -c1-240 | head -30
    [ "$relaunches" -gt 0 ] && echo "(a relaunch can name a test that never failed an assertion - re-run that class alone before believing it; CLAUDE.md)"
    exit 1
fi
echo "all passed"
