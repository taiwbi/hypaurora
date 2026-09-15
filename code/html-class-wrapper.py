#!/usr/bin/env python3

import re
import sys

MAX_LENGTH = 120

text = sys.stdin.read()
out = []

for line in text.splitlines():
    match = re.search(r'class="([^"]*)"', line)

    if not match:
        out.append(line)
        continue

    indent = re.match(r"^\s*", line).group()
    classes = match.group(1).split()

    prefix = line[: match.start(1)]
    suffix = line[match.end(1) :]

    current = prefix
    continuation = indent + "    "

    wrapped = []

    for cls in classes:
        first = current == prefix or current == continuation
        candidate = current + ("" if first else " ") + cls

        if len(candidate) > MAX_LENGTH and not first:
            wrapped.append(current)
            current = continuation + cls
        else:
            current = candidate

    wrapped.append(current + suffix)
    out.extend(wrapped)

sys.stdout.write("\n".join(out))
