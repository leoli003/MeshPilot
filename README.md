# mesh-pilot

Personal Claude Code skill pack.

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/mesh-pilot.git
cd mesh-pilot
./setup
```

## Skills

| Skill | Description |
|-------|-------------|
| `/mesh-hello` | Greeting skill (template) |
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
