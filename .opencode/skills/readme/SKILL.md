---
name: readme
description: |
  Writing and updating README files for CLI tools and bash projects.
  Use when asked to create, update, or review README.md files.
  Covers: structure, installation, usage, examples, badges, layout.
---

# README Skill

## Structure

```
# Project Name

One-line description of what it does.

## Features       (optional — bullet list of key selling points)

## Install        (how to install — commands, deps, platform reqs)

## Usage          (command examples with expected output)

## Requirements   (runtime deps: openvpn, curl, sudo, etc.)

## How it works   (high-level flow, 3-6 steps)

## Directory layout   (where config/data/cache lives)

## Development    (optional — how to contribute, run tests)

## License
```

## Guidelines

- Keep it short — README is the front page, not the manual
- Use fenced code blocks with language tags for commands
- Show real subcommands, not placeholders
- Document the data directory (XDG, config paths)
- Link to the license file, don't embed the full text
- Include a `## Development` section if the project has tests
- Badges are optional; only use them if they add real info (CI, version)

## For privacity

This project uses:
- `bash -n` for syntax checks
- `shellcheck` for static analysis
- `bats` for unit tests
- `python3` (csv module) for CSV parsing

Mention these in a Development section so contributors know the toolchain.
