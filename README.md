# mesh-pilot

Personal Claude Code skill pack for quick planning, updates, and common workflows.

## Installation

### Method 1: Claude Code Plugin Market (Recommended)

```bash
# In Claude Code, run:
/install-plugin leoli003/mesh-pilot
```

### Method 2: Manual Installation

```bash
git clone https://github.com/leoli003/MeshPilot.git
cd MeshPilot
./setup
```

## Skills

| Skill | Description |
|-------|-------------|
| `/mesh-hello` | Greeting skill (template) |
| `/mesh-quick-plan` | Quick planning without intermediate confirmation |
| `/mesh-quick-do` | Execute plans or tasks without user confirmation |
| `/mesh-update` | Update mesh-pilot |

## Adding New Skills

1. Create a new directory: `mkdir my-skill`
2. Add `SKILL.md` file with YAML frontmatter
3. Run `./setup` to reinstall

## Skill Template

```markdown
---
name: my-skill
description: |
  What this skill does.
---

## What this skill does

[Description]

## Usage

\`\`\`
/mesh-my-skill [args]
\`\`\`

## Steps

1. Step 1
2. Step 2
```

## Updating

```bash
cd mesh-pilot
git pull
./setup
```

## Uninstalling

```bash
rm -rf ~/.claude/skills/mesh-pilot
rm -rf ~/.mesh-pilot
```

## Config

Config stored at `~/.mesh-pilot/config.json`.

```bash
# Get config value
mesh-pilot-config get prefix

# Set config value
mesh-pilot-config set prefix "mesh-"
```
