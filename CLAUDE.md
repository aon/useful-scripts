# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Collection of standalone bash scripts designed to be fetched and executed via `curl | bash`. Each script is a self-contained Linux utility.

## Repository Structure

Scripts live in the `scripts/` directory. Each `.sh` file should be independently executable — no shared libraries or dependencies between scripts.

## Script Conventions

- Scripts must start with `#!/bin/bash` (or `#!/usr/bin/env bash`)
- Scripts must be self-contained: all logic in a single file, no sourcing other files
- Use `set -euo pipefail` at the top for safety
- Include a usage/help message accessible via `--help` or `-h`
- Target Linux only
- Never use `sudo` — scripts are expected to run as root

## README.md Maintenance

When adding or modifying a script, update `README.md` with an entry for it. Each entry follows this format:

```markdown
### `script-name.sh`

One-line description of what it does.

\```bash
curl -fsSL https://raw.githubusercontent.com/aon/useful-scripts/refs/heads/main/scripts/script-name.sh | bash
\```
```

Keep descriptions terse — sacrifice grammar for brevity (e.g., "Install and configure Docker on Ubuntu/Debian" not "This script will install and configure Docker on Ubuntu and Debian systems").

## Hosting

Remote: `github.com/aon/useful-scripts`. Scripts are served via GitHub raw URLs:
```
curl -fsSL https://raw.githubusercontent.com/aon/useful-scripts/refs/heads/main/scripts/<script>.sh | bash
```
