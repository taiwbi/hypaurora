#!/usr/bin/env python3

import re
import sys

MAX_LENGTH = 120

CLASS = re.compile(r"""(?<![\w:.-])class\s*=\s*(["'])(.*?)\1""")
DYNAMIC = re.compile(r"{{|{!!|<\?|@[A-Za-z_]")


def format_text(text):
    out = []

    for raw in text.splitlines(keepends=True):
        line = raw.rstrip("\r\n")
        ending = raw[len(line):]
        matches = list(CLASS.finditer(line))

        # Leave template code, multiline attributes, and ambiguous
        # lines with multiple class attributes alone.
        if (
            len(line) <= MAX_LENGTH
            or len(matches) != 1
            or DYNAMIC.search(line)
        ):
            out.append(raw)
            continue

        match = matches[0]
        classes = match.group(2).split()

        if not classes:
            out.append(raw)
            continue

        prefix = line[:match.start(2)]
        suffix = line[match.end(2):]
        continuation = re.match(r"^[ \t]*", line).group() + "    "

        wrapped = []
        current = prefix
        has_class = False

        for index, cls in enumerate(classes):
            candidate = current + (" " if has_class else "") + cls

            # Include the closing quote and remaining HTML when
            # checking the final class.
            tail = suffix if index == len(classes) - 1 else ""

            if has_class and len(candidate + tail) > MAX_LENGTH:
                wrapped.append(current)
                current = continuation + cls
            else:
                current = candidate

            has_class = True

        wrapped.append(current + suffix)
        out.append((ending or "\n").join(wrapped) + ending)

    return "".join(out)


sys.stdout.write(format_text(sys.stdin.read()))
