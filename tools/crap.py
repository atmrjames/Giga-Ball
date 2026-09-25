#!/usr/bin/env python3
"""
CRAP index for Giga-Ball: which functions are complex *and* untested.

    CRAP(f) = cc(f)^2 * (1 - coverage(f))^3 + cc(f)

Coverage comes from an .xcresult bundle made with `-enableCodeCoverage YES`; cyclomatic
complexity is measured here, from the source, by counting decision points in each function's
body. A score over 30 is the usual line for "change this with care".

Usage:
    python3 tools/crap.py path/to/run.xcresult [--top 40] [--csv out.csv]

Two lessons from rounds 311 and 313 are built in:

- **Implicit closures and the level tables are held out.** A closure's declaration sits inside a
  statement, so a brace walk measures the statement around it (three closures once scored
  2,862 apiece off one line); and a `loadLevelN` is a level drawn as range checks, where a
  mistake is visible the first time anyone opens it.
- **A report is only true of the build its coverage came from.** Any source file edited after
  the bundle was written is named, because its complexity is measured from today's text against
  yesterday's coverage.
"""

import argparse
import csv
import json
import os
import re
import subprocess
import sys

DECISIONS = re.compile(
    r"\bif\b|\bguard\b|\bwhile\b|\bfor\b|\bcase\b|\bcatch\b|&&|\|\||(?<![?!.])\?\s(?!\?)")
# `? ` is the ternary; `?.`, `??` and `!` are not decisions. `else if` counts once, as the if.


def strip_code(line: str) -> str:
    """The line without its comment and string literals, so words in either do not count."""
    out, i, in_string = [], 0, False
    while i < len(line):
        c = line[i]
        if in_string:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if line.startswith("//", i):
            break
        out.append(c)
        i += 1
    return "".join(out)


def function_body(lines, start_index):
    """The lines of the function whose declaration starts at `start_index` (0-based)."""
    depth, opened, body = 0, False, []
    in_block_comment = False
    for index in range(start_index, len(lines)):
        raw = lines[index]
        if in_block_comment:
            if "*/" in raw:
                in_block_comment = False
                raw = raw.split("*/", 1)[1]
            else:
                continue
        if "/*" in raw and "*/" not in raw:
            in_block_comment = True
            raw = raw.split("/*", 1)[0]
        code = strip_code(raw)
        body.append(code)
        for c in code:
            if c == "{":
                depth += 1
                opened = True
            elif c == "}":
                depth -= 1
        if opened and depth <= 0:
            break
        if index - start_index > 3000:
            break
    return body


def complexity(body):
    return 1 + sum(len(DECISIONS.findall(line)) for line in body)


def coverage_report(bundle):
    raw = subprocess.run(["xcrun", "xccov", "view", "--report", "--json", bundle],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(raw)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle")
    parser.add_argument("--top", type=int, default=40)
    parser.add_argument("--csv")
    args = parser.parse_args()

    report = coverage_report(args.bundle)
    bundle_time = os.path.getmtime(args.bundle)
    rows, stale = [], set()
    source_cache = {}

    for target in report.get("targets", []):
        if not target.get("name", "").startswith("Giga-Ball"):
            continue
        for entry in target.get("files", []):
            path = entry.get("path", "")
            if "/Levels/" in path or not path.endswith(".swift"):
                continue
            if os.path.getmtime(path) > bundle_time:
                stale.add(os.path.relpath(path))
            if path not in source_cache:
                with open(path, encoding="utf-8", errors="replace") as handle:
                    source_cache[path] = handle.read().split("\n")
            lines = source_cache[path]
            for function in entry.get("functions", []):
                name = function.get("name", "")
                if "closure" in name or function.get("executableLines", 0) == 0:
                    continue
                start = max(0, function.get("lineNumber", 1) - 1)
                cc = complexity(function_body(lines, start))
                cov = function.get("lineCoverage", 0.0)
                score = cc * cc * (1 - cov) ** 3 + cc
                rows.append((score, cc, cov, name, os.path.relpath(path),
                             function.get("lineNumber", 0)))

    rows.sort(reverse=True)
    over = sum(1 for row in rows if row[0] > 30)
    print(f"{len(rows)} functions scored; {over} over 30.\n")
    print(f"{'CRAP':>8} {'cc':>4} {'cov':>6}  function")
    for score, cc, cov, name, path, line in rows[:args.top]:
        print(f"{score:8.0f} {cc:4d} {cov*100:5.1f}%  {name}  ({os.path.basename(path)}:{line})")
    if stale:
        print("\nEdited since this coverage was taken, so their rows describe different code:")
        for path in sorted(stale):
            print("  " + path)
    if args.csv:
        with open(args.csv, "w", newline="") as handle:
            writer = csv.writer(handle)
            writer.writerow(["crap", "cc", "coverage", "function", "file", "line"])
            for row in rows:
                writer.writerow([f"{row[0]:.1f}", row[1], f"{row[2]:.3f}", row[3], row[4], row[5]])


if __name__ == "__main__":
    sys.exit(main())
