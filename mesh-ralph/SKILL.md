---
name: mesh-ralph
description: A complete project execution workflow that orchestrates three skills in sequence - first grills the user on requirements (grill-me), then breaks the plan into actionable issues (to-issues), then executes until completion (ralph). Use when user wants end-to-end project delivery, mentions "mesh-ralph", or wants to create something from scratch with full verification. This skill combines interview, planning, and execution into one seamless pipeline.
argument-hint: "[--e2e] <project description or task>"
level: 4
---

# Mesh Ralph - End-to-End Project Execution Pipeline

A three-phase orchestration that takes a project idea from concept to completion through structured interview, planning, and execution.

## When to Use

- User wants to create something from scratch with full verification
- User says "mesh-ralph" or "/mesh-ralph"
- User wants a complete "idea to implementation" workflow
- User needs requirements clarification before execution
- User wants verified, tested, complete delivery

## Workflow Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Phase 1    │     │  Phase 2    │     │  Phase 3    │
│  grill-me   │ ──► │  to-issues  │ ──► │   ralph     │
│  Interview  │     │   Plan      │     │  Execute    │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Phase 1: Requirements Interview (grill-me)

**Goal:** Achieve shared understanding of the project requirements.

**Process:**
1. Invoke the `grill-me` skill via Skill tool: `Skill("grill-me")`
2. Interview the user relentlessly about every aspect of the project
3. Walk down each branch of the decision tree, resolving dependencies one-by-one
4. For each question, provide your recommended answer
5. Continue until all ambiguities are resolved and a clear specification emerges

**Output:** A complete, unambiguous project specification that both you and the user understand.

## Phase 2: Issue Breakdown (to-issues)

**Goal:** Convert the specification into actionable, independent issues.

**Process:**
1. Invoke the `to-issues` skill via Skill tool: `Skill("to-issues")`
2. Break the specification into vertical slices (tracer bullets)
3. Each slice should be a thin vertical cut through ALL integration layers
4. Mark slices as HITL (requires human interaction) or AFK (autonomous)
5. Add `testType` field to each issue: `unit` (required), `integration` (default), `e2e` (critical flows only)
   - If `--e2e` flag is set, mark ALL issues as `e2e` in addition to their primary test type
6. Quiz the user on the breakdown and iterate until approved
7. Publish issues to the issue tracker

**Output:** A set of independently-grabbable issues ready for execution.

## Phase 3: Execution (ralph)

**Goal:** Execute all issues until complete with verification.

**Process:**
1. Invoke the `ralph` skill via Skill tool: `Skill("ralph")`
2. Work through each issue in dependency order
3. Verify acceptance criteria for each issue
4. Continue until all issues pass verification
5. Run architect/code review for final approval

**Output:** A complete, tested, verified implementation.

## PRD.json Schema

The `prd.json` file is the single source of truth for project execution. Structure:

```json
{
  "project": "Project Name",
  "version": "1.0.0",
  "created": "2024-01-15T10:00:00Z",
  "updated": "2024-01-15T14:30:00Z",
  "stories": [
    {
      "id": "story-001",
      "title": "User authentication",
      "priority": 1,
      "testType": ["unit", "integration"],
      "acceptance": [
        "User can register with email and password",
        "User can login with valid credentials"
      ],
      "passes": false,
      "blockedBy": [],
      "notes": "Optional implementation notes"
    }
  ]
}
```

**Field definitions:**
- `id`: Unique story identifier (format: `story-NNN`)
- `priority`: Execution order (1 = highest, executed first)
- `testType`: Array of test types to write [`unit`|`integration`|`e2e`]
- `acceptance`: Array of acceptance criteria
- `passes`: Set to `true` only after verification passes
- `blockedBy`: Array of story IDs that must complete first
- `notes`: Optional context for implementation

## Phase Context Passing

Each phase produces structured output for the next phase:

### Phase 1 → Phase 2 Output
```
grill-me produces:
- requirements.json (or project spec document)
- Key decisions log
- Constraints and preferences
```

### Phase 2 → Phase 3 Output
```
to-issues produces:
- prd.json (see schema above)
- Issue tracker references
- Dependency graph
```

### Phase 3 Execution State
```
ralph maintains:
- .omc/state/session.json (current progress)
- Verification checkpoints
```

**Context preservation rules:**
1. Never lose decisions made in earlier phases
2. If returning to earlier phase, preserve later phase work
3. Mark changed assumptions explicitly

## Incremental Build & Change Management

### Mid-Execution Requirement Change
If requirements change during execution:
1. **Pause** current story
2. **Document** the change and which stories are affected
3. **Update prd.json** - modify affected stories, add new ones
4. **Re-validate** - check if completed stories need rework
5. **Resume** from the paused story

### Blocked Story Handling
If a story is blocked and cannot proceed:
1. Mark story with `blockedBy: ["story-XXX"]`
2. Skip to next unblocked story
3. Revisit blocked story when dependency resolves

### Inserting New Stories
To add stories mid-execution:
1. Add to `prd.json` with appropriate priority
2. Set `blockedBy` if it depends on in-progress work
3. It will be picked up in the next iteration

## Execution Rules

1. **Always invoke skills in order:** grill-me → to-issues → ralph
2. **Wait for phase completion:** Do not proceed to the next phase until the current phase is complete
3. **Preserve context:** Pass all learnings from each phase to the next
4. **User approval gates:** Get user approval before proceeding between phases

## Example Usage

```
User: /mesh-ralph 创建贪吃蛇游戏

Phase 1 - grill-me:
- Q: What platform? Web, desktop, mobile?
- Q: What language/framework?
- Q: Single player or multiplayer?
- Q: What features? Leaderboard? Levels?
- ... (continue until spec is clear)

Phase 2 - to-issues:
- Issue 1: Set up project structure and game loop
- Issue 2: Implement snake movement and controls
- Issue 3: Implement food spawning and collision
- Issue 4: Add scoring and game over logic
- Issue 5: Add UI polish and sound effects
- ... (get user approval)

Phase 3 - ralph:
- Execute Issue 1 → verify → mark complete
- Execute Issue 2 → verify → mark complete
- ... (continue until all issues complete)
- Final review and delivery
```

## Arguments

The skill accepts the project description with optional configuration:

```
/mesh-ralph [--e2e] <project description>
```

**CLI Arguments:**
- `--e2e` - Force E2E tests for ALL issues (not just critical flows)

Examples:
- `/mesh-ralph 创建贪吃蛇游戏`
- `/mesh-ralph build a REST API for user authentication`
- `/mesh-ralph --e2e implement a markdown parser`

## Important Notes

- This skill is an orchestration layer - it delegates actual work to the three sub-skills
- Always use `Skill()` tool to invoke sub-skills, not direct execution
- The quality of the final output depends on thoroughness in Phase 1 (grill-me)
- **Test commands vary by project** - adapt `npm test` to your project's test runner (`pnpm test`, `cargo test`, `pytest`, etc.)

### Existing Project Mode

For projects with existing code (not starting from scratch):
1. Phase 1 (grill-me) should first ask about existing code structure
2. Determine what can be reused vs. what needs new implementation
3. In Phase 3, start from "add missing functionality" not "build from scratch"

If the user already has a clear spec, you may skip Phase 1 and start from Phase 2.
If the user already has issues created, you may skip to Phase 3 directly.

## Skill Invocation Reference

```javascript
// Phase 1
Skill("grill-me")

// Phase 2  
Skill("to-issues")

// Phase 3
Skill("ralph")
```

## Verification Checklist

Before marking work complete:

- [ ] All acceptance criteria verified
- [ ] All prd.json stories have `passes: true`
- [ ] Tests pass (using project's test runner)
- [ ] Selected reviewer verification passed
- [ ] Output pristine (no errors, warnings)

Original task:
{{PROMPT}}
