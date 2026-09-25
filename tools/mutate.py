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
`git diff` for it at the end.
"""

import argparse
import os
import re
import shutil
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
    command = ["xcodebuild", "-project", "Megaball.xcodeproj", "-scheme", "Megaball",
               "-destination", args.destination, "-derivedDataPath", args.derived_data, "test"]
    for name in args.tests.split(","):
        command += ["-only-testing:GigaBallTests/" + name.strip()]
    env = dict(os.environ, DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer")
    result = subprocess.run(command, capture_output=True, text=True, env=env)
    output = result.stdout + result.stderr
    if "** TEST SUCCEEDED **" in output:
        return "survived"
    if "error:" in output and "Testing started" not in output:
        return "stillborn"
    return "killed"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("--tests", required=True)
    parser.add_argument("--lines")
    parser.add_argument("--max", type=int, default=30)
    parser.add_argument("--destination", default="id=6C4F510D-FAC7-42B0-98CE-258809ABA4B7")
    parser.add_argument("--derived-data", default="build/mutation")
    args = parser.parse_args()

    with open(args.file, encoding="utf-8") as handle:
        original = handle.read()
    lines = original.split("\n")
    first, last = 1, len(lines)
    if args.lines:
        first, last = (int(x) for x in args.lines.split("-"))

    backup = args.file + ".mutation-backup"
    shutil.copyfile(args.file, backup)
    results = {"killed": [], "survived": [], "stillborn": []}
    try:
        print("baseline:", run_tests(args), flush=True)
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
        shutil.copyfile(backup, args.file)
        os.remove(backup)

    diff = subprocess.run(["git", "diff", "--stat", "--", args.file],
                          capture_output=True, text=True).stdout.strip()
    counted = len(results["killed"]) + len(results["survived"])
    score = 100.0 * len(results["killed"]) / counted if counted else 0
    print(f"\nkilled {len(results['killed'])}, survived {len(results['survived'])}, "
          f"stillborn {len(results['stillborn'])}; mutation score {score:.0f}%")
    for number, label, before in results["survived"]:
        print(f"  SURVIVED line {number}: {label}   {before[:90]}")
    print("file restored" + ("" if not diff else " - BUT git sees a change: " + diff))


if __name__ == "__main__":
    sys.exit(main())
