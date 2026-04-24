# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

mesh-pilot is a personal Claude Code skill pack. Skills are installed to `~/.claude/skills/mesh-pilot/` and can be invoked with `/mesh-<skill-name>`.

## Commands

```bash
./setup              # Install/update skills to ~/.claude/skills/mesh-pilot/
./setup --no-prefix  # Install without mesh- prefix (skills become /hello, /update)
```

## Architecture

```
mesh-pilot/
├── setup            # Installation script (copies entire repo to ~/.claude/skills/mesh-pilot/)
├── VERSION          # Current version
├── bin/             # CLI tools (mesh-pilot-config, mesh-pilot-update)
└── <skill>/         # Each skill is a directory with SKILL.md
    └── SKILL.md     # Skill definition with YAML frontmatter
```

## Skill Structure

Each skill directory contains a `SKILL.md` file:

```markdown
---
name: skill-name
description: |
  What this skill does.
---

## What this skill does
[Implementation details]

## Usage
/mesh-skill-name [args]

## Steps
1. Step 1
2. Step 2
```

## Adding a New Skill

1. Create directory: `mkdir my-skill`
2. Add `SKILL.md` with YAML frontmatter (copy from `hello/` as template)
3. Run `./setup` to reinstall

## Config

- Location: `~/.mesh-pilot/config.json`
- Managed by: `bin/mesh-pilot-config`

```bash
mesh-pilot-config get prefix
mesh-pilot-config set prefix "mesh-"
mesh-pilot-config list
```

## Installation Paths

- Skills: `~/.claude/skills/mesh-pilot/`
- Config: `~/.mesh-pilot/`
