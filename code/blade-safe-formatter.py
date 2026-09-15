#!/usr/bin/env python3

import hashlib
import re
import subprocess
import sys
import uuid

# Recognize quoted PHP strings inside Blade/PHP expressions.
STRING = r"""(?:'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")"""


def template_block(start, end):
    return (
        re.escape(start)
        + "(?:"
        + STRING
        + "|(?!"
        + re.escape(end)
        + """)[^'"])*"""
        + re.escape(end)
    )


TEMPLATE = "|".join(
    template_block(start, end)
    for start, end in [
        ("{{", "}}"),
        ("{!!", "!!}"),
        ("<?", "?>"),
    ]
)

CLASS = re.compile(
    r"""(?<![\w:.-])class\s*=\s*(?:"(?P<double>(?:"""
    + TEMPLATE
    + r"""|[^"])*)"|'(?P<single>(?:"""
    + TEMPLATE
    + r"""|[^'])*)')""",
    re.DOTALL,
)


def run(command, text):
    result = subprocess.run(
        command,
        input=text.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if result.stderr:
        sys.stderr.buffer.write(result.stderr)

    if result.returncode:
        raise RuntimeError(f"{command[0]} exited with status {result.returncode}")

    return result.stdout.decode("utf-8")


def format_once(source):
    saved = {}
    namespace = "hcw" + hashlib.sha256(source.encode("utf-8")).hexdigest()[:32]

    while namespace in source:
        namespace += "x"

    def protect(match):
        group = "double" if match.group("double") is not None else "single"
        value = match.group(group)

        needs_protection = any(
            marker in value for marker in ("\n", "\r", "{{", "{!!", "<?", "@")
        )

        if not needs_protection:
            return match.group(0)

        token = f"{namespace}_{len(saved)}_end"
        saved[token] = value

        start = match.start(group) - match.start()
        end = match.end(group) - match.start()
        attribute = match.group(0)

        return attribute[:start] + token + attribute[end:]

    text = CLASS.sub(protect, source)

    text = run(
        [
            "blade-formatter",
            "--stdin",
            "--sort-tailwindcss-classes",
            "--indent-inner-html",
            "--wrap-attributes",
            "preserve",
        ],
        text,
    )

    # Use the revised wrapper from the previous answer.
    # Protected attributes still contain only a single placeholder.
    text = run(["html-class-wrapper"], text)

    for token, value in saved.items():
        if text.count(token) != 1:
            raise RuntimeError(
                "A formatter changed a protected class placeholder; "
                "refusing to output the result."
            )

        text = text.replace(token, value, 1)

    # Preserve the original trailing-newline state.
    trailing = re.search(r"[\r\n]*\Z", source).group()
    text = text.rstrip("\r\n") + trailing

    return text


def main():
    text = sys.stdin.buffer.read().decode("utf-8")
    seen = {text}

    for _ in range(8):
        formatted = format_once(text)

        if formatted == text:
            sys.stdout.buffer.write(formatted.encode("utf-8"))
            return

        if formatted in seen:
            raise RuntimeError(
                "Formatter pipeline oscillates between layouts; no output was written."
            )

        seen.add(formatted)
        text = formatted

    raise RuntimeError(
        "Formatter pipeline did not stabilize after 8 passes; no output was written."
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, UnicodeError) as error:
        print(f"blade-class-safe: {error}", file=sys.stderr)
        sys.exit(1)
