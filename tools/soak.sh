#!/bin/bash
# The overnight soak (round 398b): SoakTests asked of hundreds of seeds, for as long as there is.
#
#   tools/soak.sh [hours]          default 8
#
# James, leaving for a day at work: "the suite has >8 hours to run, so make it as robust and
# thorough as possible." Two simulators at once, each built once and then run in chunks with
# `test-without-building`, so a crash or a hang costs one chunk rather than the day:
#
#   16 Pro (FULL_DEST)  testResumeSoak - play, save at a seeded moment, resume, compare -
#                       in every mode, theme and depth, and in dailies
#   17 Pro (WORK_DEST)  testDailyYearSoak over the next 365 days, then testPlaySoak - long
#                       games under PlayWatch: every Classic level, Endless, deep Mayhem, dailies
#
# Every chunk's tally, failures, relaunches and crash stacks go to one summary file, written as
# it goes, so it can be read at any point. When the time is nearly up the chunks stop and a
# fresh `tools/test.sh full` runs last. Every failure names its seed: replay one with
#   TEST_RUNNER_SOAK_FROM=<seed> TEST_RUNNER_SOAK_COUNT=1 tools/test.sh only SoakTests/<test>
set -u
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
FULL_DEST='id=6C4F510D-FAC7-42B0-98CE-258809ABA4B7'
WORK_DEST='id=5E5D91D9-3BAE-4A61-AE34-CBFD2361FBB9'
hours=${1:-8}
BASE=${TEST_LOG_DIR:-/tmp/gigaball-tests}
DIR="$BASE/soak-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DIR"
SUMMARY="$DIR/summary.txt"
start=$(date +%s)
deadline=$((start + hours*3600))
FULL_RESERVE=$((55*60))
# The full suite at the end takes about forty minutes; chunks stop early enough to leave it room
CHUNK_LIMIT=$((45*60))
# A chunk that runs longer than this is hung, and is stopped

say() { echo "$(date '+%H:%M:%S') $*" | tee -a "$SUMMARY"; }

build() {
    local dest=$1 data=$2 log=$3
    xcodebuild -project Megaball.xcodeproj -scheme Megaball -destination "$dest" \
        -derivedDataPath "$data" build-for-testing > "$log" 2>&1
    grep -q "TEST BUILD SUCCEEDED\|BUILD SUCCEEDED" "$log"
}

# One chunk: a test, a first seed and a count, against an existing build. Reports as it ends.
chunk() {
    local dest=$1 data=$2 test=$3 from=$4 count=$5 name=$6
    local log="$DIR/$name-$test-$from.log"
    local before
    before=$(ls ~/Library/Logs/DiagnosticReports/Giga-Ball-* 2>/dev/null | wc -l)
    TEST_RUNNER_SOAK_FROM=$from TEST_RUNNER_SOAK_COUNT=$count \
        xcodebuild -project Megaball.xcodeproj -scheme Megaball -destination "$dest" \
        -derivedDataPath "$data" -only-testing:"GigaBallTests/SoakTests/$test" \
        test-without-building > "$log" 2>&1 &
    local pid=$! waited=0
    while kill -0 $pid 2>/dev/null; do
        sleep 15
        waited=$((waited + 15))
        if [ $waited -ge $CHUNK_LIMIT ]; then
            kill $pid 2>/dev/null; sleep 5; kill -9 $pid 2>/dev/null
            say "$name $test $from+$count: HUNG after $((waited/60)) minutes, stopped"
            break
        fi
    done
    wait $pid 2>/dev/null
    local ok failed relaunches
    ok=$(grep -c "^SOAK .* ok$" "$log")
    failed=$(grep -c "^SOAK .* FAILED$" "$log")
    relaunches=$(grep -c "Restarting after unexpected exit" "$log")
    say "$name $test seeds $from..$((from + count - 1)): $ok ok, $failed failed, $relaunches relaunches ($(( (waited + 0) / 60 )) min)"
    if [ "$failed" -gt 0 ] || grep -q "error: -\[" "$log"; then
        grep -E "error: -\[" "$log" | sed -E 's/.*failed - //' | cut -c1-600 >> "$SUMMARY"
        # The rest of a multi-line failure follows its first line in the log, unprefixed
        awk '/error: -\[GigaBallTests.SoakTests/{f=1; next} f && /^(Test Case|Test Suite|\t)/{f=0} f && !/^20[0-9][0-9]-[0-9]/' "$log" \
            | cut -c1-600 | head -60 >> "$SUMMARY"
    fi
    if [ "$relaunches" -gt 0 ]; then
        awk '/Test Case .* started/ { running = $0 }
             /Fatal error:/ && fatal == "" { fatal = $0 }
             /Restarting after unexpected exit/ {
                 print "  host died in: " running (fatal != "" ? "  " substr(fatal, 1, 200) : "  (no fatal error)")
                 fatal = "" }' "$log" >> "$SUMMARY"
        grep "^SOAK" "$log" | tail -1 | sed 's/^/  last seed finished: /' >> "$SUMMARY"
    fi
    local after
    after=$(ls ~/Library/Logs/DiagnosticReports/Giga-Ball-* 2>/dev/null | wc -l)
    if [ "$after" -gt "$before" ]; then
        for report in $(ls -t ~/Library/Logs/DiagnosticReports/Giga-Ball-* | head -$((after - before))); do
            cp "$report" "$DIR/"
            python3 - "$report" >> "$SUMMARY" <<'EOF'
import json, sys
text = open(sys.argv[1]).read()
head, body = text.split('\n', 1)
data = json.loads(body)
thread = next((t for t in data.get('threads', []) if t.get('triggered')), None)
images = data.get('usedImages', [])
print("  crash report " + sys.argv[1].split('/')[-1] + ":")
for frame in (thread or {}).get('frames', [])[:10]:
    name = images[frame['imageIndex']].get('name', '?') if 'imageIndex' in frame else '?'
    print("    %s %s %s:%s" % (name, frame.get('symbol', ''), frame.get('sourceFile', ''), frame.get('sourceLine', '')))
EOF
        done
    fi
}

time_left() { echo $((deadline - $(date +%s))); }

say "soak for $hours hours, until $(date -r $deadline '+%H:%M'), logs in $DIR"
say "building for both simulators"
build "$FULL_DEST" "$DIR/derived-a" "$DIR/build-a.log" || { say "build A FAILED"; exit 1; }
build "$WORK_DEST" "$DIR/derived-b" "$DIR/build-b.log" || { say "build B FAILED"; exit 1; }
say "built"

# Simulator A: the resume soak, thirty seeds a chunk, until the reserve
(
    seed=1000
    while [ "$(time_left)" -gt $((FULL_RESERVE + 20*60)) ]; do
        chunk "$FULL_DEST" "$DIR/derived-a" testResumeSoak $seed 30 A
        seed=$((seed + 30))
    done
    say "A finished at seed $seed"
) &
loopA=$!

# Simulator B: the coming year of dailies, then the play soak
(
    day=0
    while [ $day -lt 366 ] && [ "$(time_left)" -gt $((FULL_RESERVE + 20*60)) ]; do
        chunk "$WORK_DEST" "$DIR/derived-b" testDailyYearSoak $day 46 B
        day=$((day + 46))
    done
    seed=1
    while [ "$(time_left)" -gt $((FULL_RESERVE + 25*60)) ]; do
        chunk "$WORK_DEST" "$DIR/derived-b" testPlaySoak $seed 10 B
        seed=$((seed + 10))
    done
    say "B finished at play seed $seed"
) &
loopB=$!

wait $loopA $loopB
say "soak chunks done; the full suite, fresh"
TEST_LOG_DIR="$DIR" tools/test.sh full >> "$SUMMARY" 2>&1
say "all done"
grep -c " 0 failed, 0 relaunches" "$SUMMARY" | sed 's/^/clean chunks: /' | tee -a "$SUMMARY"
