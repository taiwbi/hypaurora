#!/usr/bin/env python3

import sys
import subprocess
import json
import requests
from pathlib import Path

# --- Configuration ---
API_KEY_FILE = Path.home() / ".keys" / "GEMINI"
MODEL_NAME = "models/gemini-3-flash-preview"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/{MODEL_NAME}:generateContent"

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
        with open(API_KEY_FILE, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        print_error(f"API key file not found: {API_KEY_FILE}")
        sys.exit(1)

def generate_gemini_response(prompt, user_input="", temperature=0):
    api_key = load_api_key()
    
    full_text = f"{prompt}\n{user_input}" if user_input else prompt
    
    payload = {
        "contents": [{
            "parts": [{
                "text": full_text
            }]
        }],
        "generationConfig": {
            "temperature": temperature,
            "topK": 1,
            "topP": 1,
            "maxOutputTokens": 8192
        }
    }
    
    try:
        response = requests.post(
            API_URL,
            params={"key": api_key},
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=60
        )
        response.raise_for_status()
        
        data = response.json()
        
        if "candidates" in data and len(data["candidates"]) > 0:
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            return text.strip()
        else:
            print_error("Failed to parse response or response was empty.")
            if "error" in data:
                print_error(f"API Error: {data['error'].get('message', 'Unknown error')}")
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
            check=True
        )
        return True
    except subprocess.CalledProcessError:
        return False

def get_staged_diff():
    result = subprocess.run(
        ["git", "diff", "--staged"],
        capture_output=True,
        text=True
    )
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

Each commit type helps categorize changes and makes it easier to understand the purpose of a commit at a glance. This format also enables automatic versioning and changelog generation based on commit types.

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

Keep the emojies when writing commit message.

# Scopes

Adds context about where the change happened. These are some examples of scopes you can use:

- **api:** Changes related to API endpoints, controllers, or interface specifications.
- **auth:** Authentication and authorization related changes.
- **core:** Core functionality or infrastructure of the application.
- **ui/ux:** User interface or user experience changes.
- **db:** Database schema, migrations, or query-related changes.
- **config:** Configuration files and settings. If the change is related to a specific configuration type (for example configuring a specific application), add the application name as a scope.
- **deps:** Dependency management changes.
- **i18n:** Internationalization and localization.
- **security:** Security-related changes or fixes.
- **perf:** Performance-specific scope (distinct from the perf commit type).
- **tests:** Test infrastructure (not test cases themselves).
- **docs:** Documentation-specific changes.
- **ci/cd:** Continuous integration and deployment pipeline changes.
- **utils:** Utility functions or helper code.
- **models:** Data models or schema definitions.
- **services:** Service layer functionality.
- **components:** UI components (commonly used in frontend projects).
- **store:** State management changes (like Redux).
- **middleware:** Application middleware changes.
- **analytics:** Analytics or monitoring related changes.
- **styles:** CSS, styling, or theming changes.
- Other scopes are acceptable based on the context of the changes.

# Description format

The **description** is a short, concise summary of the change that follows the `<type>[optional scope]:` prefix. It should be written in the **imperative mood**, meaning it should read like an instruction or command, as if saying what the commit will do when applied. Try to keep the description to a maximum of 70 character line if possible.

## Optional body format

The **body** provides additional context and details about the change in a bullet list format. It should elaborate on **what changed** and **why**, when the commit type and description alone are not sufficient to explain the full impact. It should not just duplicate the point of description and should be avoided if it's not necessary.

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

IMPORTANT:

Only and ONLY use provided types and formatting guidelines provided here. Do not ever create ideas out of yourself.

---

Here's the git diff:
""" + git_diff
    
    if user_description:
        commit_prompt += f"\n\nUser description of changes: {user_description}"
    
    print("Generating commit message from staged changes...")
    commit_message = generate_gemini_response(commit_prompt, "", 0.3)
    
    # Remove code fences if present
    commit_message = commit_message.replace("```", "").replace("`", "").strip()
    
    print("-------------------------------------")
    print("Suggested commit message:")
    print(commit_message)
    print("-------------------------------------")
    
    confirmation = input("Do you want to commit with this message? (yes/no): ").strip().lower()
    
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
    
    print("Asking Gemini...")
    suggested_command = generate_gemini_response(predefined_prompt, user_input)
    
    if suggested_command == "Error: Cannot determine a single command for this request.":
        print(f"Gemini: {suggested_command}")
        return
    
    print(f"$ {suggested_command}")
    
    confirmation = input("Do you want to run this command in the current directory? (yes/no): ").strip().lower()
    
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
    print(f"  {script_name} command \"command request\"      Generate a shell command based on your request")
    print(f"  {script_name} commit [description]           Generate a conventional commit message from staged changes")
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
