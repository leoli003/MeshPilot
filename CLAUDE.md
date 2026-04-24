# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

mesh-pilot is a personal Claude Code plugin pack. It supports both plugin market installation and manual setup.

## Installation

### Plugin Market (Recommended)
```bash
/install-plugin leoli003/mesh-pilot
```

### Manual Setup
```bash
./setup              # Install/update skills to ~/.claude/skills/mesh-pilot/
./setup --no-prefix  # Install without mesh- prefix (skills become /hello, /update)
```

## Architecture

```
mesh-pilot/
├── .claude-plugin/
│   ├── marketplace.json   # Plugin market configuration
│   └── plugin.json        # Plugin definition (skills, agents references)
├── setup                  # Manual installation script
├── VERSION                # Current version
├── bin/                   # CLI tools (mesh-pilot-config, mesh-pilot-update)
├── <skill>/               # Each skill is a directory with SKILL.md
│   └── SKILL.md           # Skill definition with YAML frontmatter
└── agents/                # (Optional) Custom agents
    └── <agent>.md         # Agent definition
```

## Skill Structure

Each skill directory contains a `SKILL.md` file:

```markdown
---
name: skill-name
description: |
  What this skill does. Triggers when user says X, Y, Z.
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
3. Update `.claude-plugin/plugin.json` to include the new skill path
4. Run `./setup` to reinstall (or push and reinstall via plugin market)

## Adding a New Agent

1. Create `agents/` directory if not exists
2. Add `<agent-name>.md` with agent definition
3. Update `.claude-plugin/plugin.json` to add agent path:
   ```json
   "agents": ["./agents/my-agent.md"]
   ```

## Plugin Configuration Files

### marketplace.json
Defines how the plugin appears in the market:
- name, description, owner
- plugin list with source paths

### plugin.json
Defines what the plugin contains:
- `skills`: array of skill directory paths
- `agents`: array of agent file paths
- `commands`: array of command directory paths (optional)

## Config

- Location: `~/.mesh-pilot/config.json`
- Managed by: `bin/mesh-pilot-config`

```bash
mesh-pilot-config get prefix
mesh-pilot-config set prefix "mesh-"
mesh-pilot-config list
```

## Installation Paths

- Plugin cache: `~/.claude/plugins/cache/leoli003/mesh-pilot/<version>/`
- Skills: `~/.claude/skills/mesh-pilot/` (manual setup)
- Config: `~/.mesh-pilot/`
