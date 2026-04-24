---
name: update
description: |
  Update mesh-pilot to the latest version from git.
  Triggers: /mesh-update
---

## What this skill does

Checks for updates and pulls the latest version of mesh-pilot.

## Usage

```
/mesh-update
```

## Steps

1. Check current version
2. Git pull from source
3. Re-run setup if updated
4. Report new version
