---
name: shellcheck
description: |
  Shell script static analysis with shellcheck. Run shellcheck on .sh files
  and fix all warnings and errors before considering code complete.
  Use when asked to lint, check, or review shell scripts.
---

# ShellCheck

Run `shellcheck` on every script:

```bash
shellcheck -x -s bash privacity
```

If not installed:

```bash
sudo apt install shellcheck    # Linux
brew install shellcheck        # macOS
```

## Common SC issues in privacity

| Code | Issue | Fix |
|---|---|---|
| SC2086 | Double quote to prevent globbing | `"$var"` |
| SC2155 | Declare and assign separately | `local var; var=$(cmd)` |
| SC2181 | Check exit code directly | `if cmd; then` not `if [ $? -eq 0 ]` |
| SC2236 | Use `-n` instead of `! -z` | `[[ -n "$var" ]]` |
| SC2206 | Word-splitting in array assignment | Use `mapfile` or `read -a` |
| SC2046 | Word-splitting in command substitution | Quote `$(...)` |

## CI integration

```bash
shellcheck -s bash --severity=warning privacity
```

Exit code is non-zero on any finding above the severity threshold.
