#!/usr/bin/env python3

import sys
import subprocess
import json
import os
import requests
from pathlib import Path

# --- Configuration ---
# Fallback API key file if OPENROUTER_API_KEY is not set
API_KEY_FILE = Path.home() / ".keys" / "OPENROUTER"
MODEL_NAME = "openai/gpt-oss-20b"
API_URL = "https://openrouter.ai/api/v1/chat/completions"


# --- Helper Functions ---
def print_error(message):
    print(f"[ERROR] {message}", file=sys.stderr)


def check_dependency(command):
    try:
        subprocess.run([command, "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_error(f"Required command '{command}' not found. Please install it.")
        sys.exit(1)


def load_api_key():
    try:
        with open(API_KEY_FILE, "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        print_error(f"API key file not found: {API_KEY_FILE}")
        sys.exit(1)


def generate_openrouter_response(prompt, user_input="", temperature=0.0):
    api_key = os.environ.get("OPENROUTER_API_KEY") or load_api_key()

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": prompt},
            {"role": "user", "content": user_input},
        ],
        "temperature": temperature,
        "top_p": 1,
        "max_tokens": 2048,
        "reasoning": {"enabled": True},
    }

    try:
        response = requests.post(
            API_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            data=json.dumps(payload),
            timeout=60,
        )
        response.raise_for_status()

        data = response.json()

        if "choices" in data and len(data["choices"]) > 0:
            text = data["choices"][0]["message"].get("content", "")
            return text.strip()
        else:
            print_error("Failed to parse response or response was empty.")
            if "error" in data:
                print_error(
                    f"API Error: {data['error'].get('message', 'Unknown error')}"
                )
            print("Raw API Response:")
            print(json.dumps(data, indent=2))
            sys.exit(1)

    except requests.exceptions.RequestException as e:
        print_error(f"API request failed: {e}")
        sys.exit(1)


def is_git_repository():
    try:
        subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            capture_output=True,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def get_staged_diff():
    result = subprocess.run(["git", "diff", "--staged"], capture_output=True, text=True)
    return result.stdout


def commit_mode(user_description=""):
    check_dependency("git")

    if not is_git_repository():
        print_error("Not inside a git repository.")
        sys.exit(1)

    git_diff = get_staged_diff()

    if not git_diff:
        print_error("No staged changes found. Stage changes with 'git add' first.")
        sys.exit(1)

    commit_prompt = """You are a Git commit message generator.
Generate a short and concise conventional commit message based on the git diff and user description below.

```
<type>(scope): <description>
[optional body]
[optional footer(s)]
```

# Commit Types

- **✨ feat:** Introduces a new feature to the codebase.`.
- **💥 fix:** Patches a bug in the codebase.`.
- **🔨 build:** Changes that affect the build system or external dependencies.`.
- **🔧 chore:** Regular maintenance tasks that don't modify src or test files.`.
- **🤖 ci:** Changes to CI configuration files and scripts.`.
- **📚 docs:** Changes to documentation only.`.
- **💄 style:** Changes that don't affect code meaning (white-space, formatting, etc.).`.
- **♻️ refactor:** Code changes that neither fix a bug nor add a feature, just improving the code structure.`.
- **⚡ perf:** Changes that improve performance.`.
- **🧪 test:** Adding or correcting tests.`.

Keep the emojies near type in message.

# Scopes

Adds context about where the change happened, like auth, api, ui/ux, db, the name of the app configuration changed, etc...

# Description format

The **description** is a short, concise summary of the change that follows the `<type>(scope):` prefix. It should be written in the **imperative mood**, meaning it should read like an instruction or command, as if saying what the commit will do when applied. Keep the description to a maximum of 70 character line.

## Optional body format

The **body** provides additional context and details about the change in a bullet list format. It should elaborate on **what changed** and **why**, when the commit type and description alone are not sufficient to explain the full impact. It should NOT just duplicate the point of description and should be avoided if it's not necessary.

Guidelines for writing the body:

- Use the **imperative**, **present tense**: "change" not "changed" or "changes".
- Leave one blank line between the description and the body.
- Wrap lines at approximately 70 characters for readability.
- Include motivation for the change and contrast it with previous behavior if necessary.
- Use dash points for bullet lists when writing the body.

## Optional footer format

If your commit introduces a breaking change (i.e., changes that are not backward compatible), use the following format in the footer:

```
BREAKING CHANGE: <description>
```
"""

    user_message = "Here's the git diff:\n\n" + git_diff

    if user_description:
        user_message += f"\n\nThis is a description of what I've changed and what was my purpose: {user_description}"

    print("Generating commit message from staged changes...")
    commit_message = generate_openrouter_response(commit_prompt, user_message, 0.3)

    # Remove code fences if present
    commit_message = commit_message.replace("```", "").replace("`", "").strip()

    print("-------------------------------------")
    print("Suggested commit message:")
    print(commit_message)
    print("-------------------------------------")

    confirmation = (
        input("Do you want to commit with this message? (yes/no): ").strip().lower()
    )

    if confirmation in ["yes", "y"]:
        print("Committing changes...")
        try:
            subprocess.run(["git", "commit", "-m", commit_message], check=True)
            print("Changes committed successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Commit failed with exit code {e.returncode}.")
    else:
        print("Commit canceled.")


def command_mode(user_input):
    predefined_prompt = """You are a helpful assistant expert in Fedora Linux shell commands.
Given the user's request below, provide ONLY the single, runnable shell command that achieves the task.
Do not include explanations, code fences (like ```), introductory phrases (like 'Here is the command:'), or any text other than the command itself.
Only if the request is really ambiguous or absolutely cannot be reasonably fulfilled with a single command or a chain of commands together,
respond with 'Error: Cannot determine a single command for this request.'
User request:"""

    print("Asking OpenRouter...")
    suggested_command = generate_openrouter_response(predefined_prompt, user_input, 0.3)

    if (
        suggested_command
        == "Error: Cannot determine a single command for this request."
    ):
        print(suggested_command)
        return

    print(f"$ {suggested_command}")

    confirmation = (
        input("Do you want to run this command in the current directory? (y/n): ")
        .strip()
        .lower()
    )

    if confirmation in ["yes", "y"]:
        print("")
        result = subprocess.run(suggested_command, shell=True)
        if result.returncode != 0:
            print(f"Command finished with exit code {result.returncode}.")
    else:
        print("Command not executed.")


def show_help():
    script_name = Path(sys.argv[0]).name
    print(f"Usage:")
    print(
        f'  {script_name} command "command request"      Generate a shell command based on your request'
    )
    print(
        f"  {script_name} commit [description]           Generate a conventional commit message from staged changes"
    )
    print(f"  {script_name} --help                         Show this help message")


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["--help", "-h"]:
        show_help()
        sys.exit(0)

    if sys.argv[1] == "commit":
        user_description = sys.argv[2] if len(sys.argv) > 2 else ""
        commit_mode(user_description)
    elif sys.argv[1] == "command":
        if len(sys.argv) < 3:
            print("No input received. Use --help for usage information.")
            sys.exit(0)
        user_input = sys.argv[2]
        command_mode(user_input)


if __name__ == "__main__":
    main()
