---
name: hello
description: |
  A simple greeting skill. Use as a template for creating new skills.
  Triggers: /mesh-hello
---

## What this skill does

This is a minimal skill template. When you run `/mesh-hello`, it will:

1. Print a greeting
2. Show current context (branch, project)

## Usage

```
/mesh-hello [name]
```

## Example

```
/mesh-hello world
```

## Creating your own skill

1. Copy this directory: `cp -r hello my-skill`
2. Edit `SKILL.md` with your skill logic
3. Run `./setup` to reinstall
