#!/usr/bin/env python3
# The slow test classes, from a full run's log - the list `tools/test.sh quick` leaves out.
#
#   tools/test-times.py FULL_RUN.log [SECONDS] > tools/slow-tests.txt
#
# One line per class that took at least SECONDS (10 unless given): seconds, tests, class.
# Refresh it after a full run whenever a class has been added or has grown; a slow class
# left off the list only makes `quick` slower, never wrong.
import re
import sys

log = open(sys.argv[1], errors="ignore").read().split("\n")
cutoff = float(sys.argv[2]) if len(sys.argv) > 2 else 10
found = []
for i, line in enumerate(log[:-1]):
    suite = re.search(r"Test Suite '([A-Za-z0-9_]+)' (passed|failed) at", line)
    ran = re.search(r"Executed (\d+) tests?, .* \(([0-9.]+)\) seconds", log[i + 1])
    if suite and ran and suite.group(1) != "GigaBallTests":
        found.append((float(ran.group(2)), int(ran.group(1)), suite.group(1)))
for seconds, tests, name in sorted(found, reverse=True):
    if seconds >= cutoff:
        print(f"{seconds:.1f} {tests} {name}")
