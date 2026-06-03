---
name: bash-testing
description: |
  Strategies and patterns for testing bash scripts.
  Use when writing or executing tests for .sh files in the project.
---

# Bash Testing

## Quick smoke tests

Verify the script parses without error:

```bash
bash -n privacity
```

Run individual functions by sourcing and calling them:

```bash
bash -c '
  source privacity
  get_external_ip
  echo "IP: $?"
'
```

## bats (Bash Automated Testing System)

```bash
sudo apt install bats    # or: npm install -g bats
```

Example test file (`tests/privacity.bats`):

```bash
setup() {
  load '../privacity'
}

@test "parse_servers rejects empty input" {
  run parse_servers /dev/null
  [ "$status" -eq 0 ]
}
```

## What to test

- **Parsing** — CSV with 0, 1, 50+ lines; quoted commas in fields; missing fields
- **Network** — `get_external_ip` with mock endpoints; `get_ping` with unreachable host
- **Config** — `write_config` strips dangerous directives; base64 decode failure
- **Error paths** — missing deps; failed download; timeout on tunnel wait
- **Portability** — `_stat_mtime` on Linux and BSD-style paths

## pytest-like helpers for bats

```bash
assert_success() { [ "$status" -eq 0 ]; }
assert_failure() { [ "$status" -ne 0 ]; }
assert_output_contains() { [[ "$output" == *"$1"* ]]; }
```
