#!/usr/bin/env python3
"""
Mutation testing for Giga-Ball: would the tests notice if this line were wrong?

Each mutant is one small deliberate bug in one line of one file - a comparison turned round,
`&&` for `||`, `true` for `false`, `min` for `max`, `+` for `-`. The chosen test classes are run
against it. A failing run means the tests **killed** it; a passing run means they did not
notice, and the line it names is one no test is really pinning. A mutant that does not compile
is **stillborn** and counts for nothing.

Usage:
    python3 tools/mutate.py FILE --tests Class1,Class2 [--lines 120-200] [--max 30]
        [--destination id=...] [--derived-data PATH]

Expensive, by design: every mutant is an incremental build and a test run, around half a
minute each on a quiet machine. Point it at small, pure logic with fast tests. Round 311 found
its first real hole this way (`DailyStreak.isTheDayAfter`'s failure branch, never asked about).

The original file is always put back, including on an error or Ctrl-C, and the script checks
`git diff` for it at the end. **Close the file in Xcode first** (or quit Xcode): an open editor
can save its own copy back over the restore, which is the likeliest reason round 345's second
run ended with a mutant in the working tree while Xcode had the project open.
"""

import argparse
import os
import re
import shutil
import signal
import subprocess
import sys
import time

SWAPS = [
    (r"(?<![=!<>])==(?!=)", "!="),
    (r"!=(?!=)", "=="),
    (r"(?<![-<])<=", "<"),
    (r"(?<![-=>])>=", ">"),
    (r" < ", " <= "),
    (r" > ", " >= "),
    (r"&&", "||"),
    (r"\|\|", "&&"),
    (r"\btrue\b", "false"),
    (r"\bfalse\b", "true"),
    (r"\bmin\(", "max("),
    (r"\bmax\(", "min("),
    (r" \+ ", " - "),
    (r" - (?=\w)", " + "),
]

SKIP = re.compile(r"^\s*(//|///|\*|import\b|@|case\s+\w+\s*(=|$))")


def mutants(lines, first, last):
    for number in range(first, last + 1):
        line = lines[number - 1]
        if SKIP.match(line) or "->" in line and "func " in line:
            continue
        code = line.split("//", 1)[0]
        if '"' in code:
            continue
        for pattern, replacement in SWAPS:
            for match in re.finditer(pattern, code):
                mutated = code[:match.start()] + replacement + code[match.end():]
                rest = line[len(code):]
                yield number, line, mutated + rest, f"{match.group(0).strip()} -> {replacement.strip()}"


def run_tests(args):
    """Runs the chosen tests and returns killed, survived, stillborn or timeout.

    **Decided from the output as it streams, not from the exit.** Round 345 found that when a
    test fails, `xcodebuild` goes on running for minutes after the tests themselves have finished
    - a failing class that took sixteen seconds held the process for over ten minutes - so every
    killed mutant looked like a hang. The suite's own summary line says the answer the moment the
    tests end, and the process is stopped there.
    """
    command = ["xcodebuild", "-project", "Megaball.xcodeproj", "-scheme", "Megaball",
               "-destination", args.destination, "-derivedDataPath", args.derived_data, "test"]
    for name in args.tests.split(","):
        command += ["-only-testing:GigaBallTests/" + name.strip()]
    env = dict(os.environ, DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer")
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, env=env, start_new_session=True)
    started, verdict, compile_error, testing = time.time(), None, False, False
    try:
        for line in process.stdout:
            if "Testing started" in line or "Test Suite '" in line:
                testing = True
            if ": error:" in line and not testing and "-[" not in line:
                compile_error = True
            if "Test Suite 'Selected tests' failed" in line or "** TEST FAILED **" in line:
                verdict = "killed" if testing else "stillborn"
                break
            if "Test Suite 'Selected tests' passed" in line or "** TEST SUCCEEDED **" in line:
                verdict = "survived"
                break
            if "** BUILD FAILED **" in line or "** TEST BUILD FAILED **" in line:
                verdict = "stillborn"
                break
            if time.time() - started > args.timeout:
                verdict = "timeout"
                break
    finally:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        process.wait()
    if verdict is None:
        verdict = "stillborn" if compile_error else "timeout"
    return verdict


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("--tests", required=True)
    parser.add_argument("--lines")
    parser.add_argument("--max", type=int, default=30)
    parser.add_argument("--destination", default="id=6C4F510D-FAC7-42B0-98CE-258809ABA4B7")
    parser.add_argument("--derived-data", default="build/mutation")
    parser.add_argument("--timeout", type=int, default=240,
                        help="seconds before a run counts as hung, and so as killed")
    args = parser.parse_args()

    with open(args.file, encoding="utf-8") as handle:
        original = handle.read()
    lines = original.split("\n")
    first, last = 1, len(lines)
    if args.lines:
        first, last = (int(x) for x in args.lines.split("-"))
        first, last = max(1, first), min(last, len(lines))
        # Clamped: a range written against an older copy of the file must not walk off its end

    backup = args.file + ".mutation-backup"
    shutil.copyfile(args.file, backup)
    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, lambda *_: sys.exit(1))
    # So `kill`, or the terminal closing, still runs the `finally` below. Round 345's first run
    # was stopped from outside and left a mutant in the working tree until it was put back by
    # hand from the backup - which is what the backup is for, but not what it should need
    results = {"killed": [], "survived": [], "stillborn": [], "timeout": []}
    try:
        baseline = run_tests(args)
        if baseline != "survived":
            print(f"baseline: the tests do not pass unmutated ({baseline}); nothing to measure")
            return 1
        print("baseline: the tests pass unmutated", flush=True)
        for index, (number, before, after, label) in enumerate(mutants(lines, first, last)):
            if index >= args.max:
                break
            mutated = list(lines)
            mutated[number - 1] = after
            with open(args.file, "w", encoding="utf-8") as handle:
                handle.write("\n".join(mutated))
            started = time.time()
            verdict = run_tests(args)
            results[verdict].append((number, label, before.strip()))
            print(f"{verdict:9} line {number:4} {label:14} {before.strip()[:70]}"
                  f"  ({time.time() - started:.0f}s)", flush=True)
    finally:
        with open(args.file, "w", encoding="utf-8") as handle:
            handle.write(original)
        with open(args.file, encoding="utf-8") as handle:
            restored = handle.read() == original
        if restored:
            os.remove(backup)
        else:
            print(f"RESTORE FAILED: {args.file} does not match what was read at the start; "
                  f"the original is still in {backup}")
        # **From memory, and checked** (round 345). The first version copied the backup file
        # back and trusted it, and one run ended with its last mutant still in the working tree
        # beside a message saying the file was restored. The text read at the start is the one
        # thing certain to be right, so it is what goes back - and the file is read again to
        # make sure it did. The backup stays on disk if anything disagrees.

    diff = subprocess.run(["git", "diff", "--stat", "--", args.file],
                          capture_output=True, text=True).stdout.strip()
    counted = len(results["killed"]) + len(results["survived"])
    score = 100.0 * len(results["killed"]) / counted if counted else 0
    print(f"\nkilled {len(results['killed'])}, survived {len(results['survived'])}, "
          f"stillborn {len(results['stillborn'])}, timed out {len(results['timeout'])}; "
          f"mutation score {score:.0f}%")
    for number, label, before in results["survived"]:
        print(f"  SURVIVED line {number}: {label}   {before[:90]}")
    for number, label, before in results["timeout"]:
        print(f"  TIMED OUT line {number}: {label}   {before[:90]}")
    print("file restored" + ("" if not diff else " - BUT git sees a change: " + diff))


if __name__ == "__main__":
    sys.exit(main())
