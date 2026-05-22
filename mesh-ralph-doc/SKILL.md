---
name: mesh-ralph-doc
description: End-to-end project execution with documentation-driven requirements gathering. Orchestrates grill-with-docs → to-issues → ralph. Uses existing documentation (PRDs, specs, design docs) as context for requirements interview instead of starting from scratch. Use when user has existing documentation to work from, mentions "mesh-ralph-doc", or wants document-informed project delivery.
argument-hint: "[--e2e] [--docs=<path>] <project description or task>"
level: 4
---

# Mesh Ralph Doc - Document-Informed Project Execution Pipeline

A three-phase orchestration that uses existing documentation as the foundation for requirements gathering, planning, and execution.

## When to Use

- User has existing PRDs, specs, or design documents to work from
- User says "mesh-ralph-doc" or "/mesh-ralph-doc"
- User wants document-informed "idea to implementation" workflow
- User needs requirements clarification but has documentation as starting point
- User wants verified, tested, complete delivery with doc context

## Workflow Overview

```
┌─────────────────┐     ┌─────────────┐     ┌─────────────┐
│    Phase 1      │     │  Phase 2    │     │  Phase 3    │
│ grill-with-docs │ ──► │  to-issues  │ ──► │   ralph     │
│  Doc Interview  │     │   Plan      │     │  Execute    │
└─────────────────┘     └─────────────┘     └─────────────┘
```

## Phase 1: Document-Informed Requirements Interview (grill-with-docs)

**Goal:** Achieve shared understanding of the project requirements using existing documentation as context.

**Process:**
1. Invoke the `grill-with-docs` skill via Skill tool: `Skill("grill-with-docs")`
2. The skill will:
   - Read and analyze existing documentation (PRDs, specs, design docs, READMEs)
   - Extract requirements, constraints, and design decisions from documents
   - Interview the user to fill gaps and resolve ambiguities
   - Walk down each branch of the decision tree with document context
3. For each question, provide your recommended answer based on document analysis
4. Continue until all ambiguities are resolved and a clear specification emerges

**Output:** A complete, unambiguous project specification grounded in existing documentation.

**Document Sources:**
- `--docs=<path>` argument to specify document location
- Default: looks for `prds/`, `docs/`, `specs/` directories
- Also checks for `README.md`, `DESIGN.md`, `ARCHITECTURE.md`

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
  "sourceDocs": ["prds/auth.md", "docs/architecture.md"],
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
- `sourceDocs`: Array of document paths that informed this PRD
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
grill-with-docs produces:
- requirements.json (extracted from documents)
- Document analysis summary
- Key decisions log
- Constraints from docs
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

1. **Always invoke skills in order:** grill-with-docs → to-issues → ralph
2. **Wait for phase completion:** Do not proceed to the next phase until the current phase is complete
3. **Preserve context:** Pass all learnings from each phase to the next
4. **User approval gates:** Get user approval before proceeding between phases
5. **Document-first:** Prioritize information from existing docs over assumptions

## Example Usage

```
User: /mesh-ralph-doc 实现用户认证模块

Phase 1 - grill-with-docs:
- Reading docs/prds/auth.md...
- Reading docs/architecture.md...
- Q: The PRD specifies JWT auth. Should we use RS256 or HS256?
- Q: The design doc mentions refresh tokens. Should they rotate on each use?
- Q: Password requirements from security.md: min 12 chars, special chars required. Confirm?
- ... (continue until spec is clear)

Phase 2 - to-issues:
- Issue 1: Set up user model and database schema
- Issue 2: Implement password hashing
- Issue 3: Create registration endpoint
- Issue 4: Create login endpoint
- Issue 5: Add JWT token generation
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
/mesh-ralph-doc [--e2e] [--docs=<path>] <project description>
```

**CLI Arguments:**
- `--e2e` - Force E2E tests for ALL issues (not just critical flows)
- `--docs=<path>` - Specify document location

Examples:
- `/mesh-ralph-doc 创建贪吃蛇游戏`
- `/mesh-ralph-doc --docs=prds/auth.md 实现用户认证`
- `/mesh-ralph-doc --e2e --docs=docs/ build a REST API`

## Important Notes

- This skill is an orchestration layer - it delegates actual work to the three sub-skills
- Always use `Skill()` tool to invoke sub-skills, not direct execution
- **Document-first approach:** Existing documentation takes precedence over assumptions
- The quality of the final output depends on thoroughness in Phase 1 (grill-with-docs)
- **Test commands vary by project** - adapt `npm test` to your project's test runner (`pnpm test`, `cargo test`, `pytest`, etc.)

### Existing Project Mode

For projects with existing code (not starting from scratch):
1. Phase 1 (grill-with-docs) should first scan existing code structure
2. Determine what can be reused vs. what needs new implementation
3. In Phase 3, start from "add missing functionality" not "build from scratch"

If the user already has a clear spec, you may skip Phase 1 and start from Phase 2.
If the user already has issues created, you may skip to Phase 3 directly.

## Skill Invocation Reference

```javascript
// Phase 1
Skill("grill-with-docs")

// Phase 2
Skill("to-issues")

// Phase 3
Skill("ralph")
```

## Comparison with mesh-ralph

| Feature | mesh-ralph | mesh-ralph-doc |
|---------|------------|----------------|
| Requirements Phase | grill-me (from scratch) | grill-with-docs (doc-informed) |
| Starting Point | User interview only | Documents + interview |
| Best For | New projects, greenfield | Existing specs, brownfield |
| Context | User-provided only | Document-grounded |

## Verification Checklist

Before marking work complete:

- [ ] All acceptance criteria verified
- [ ] All prd.json stories have `passes: true`
- [ ] Tests pass (using project's test runner)
- [ ] Selected reviewer verification passed
- [ ] Output pristine (no errors, warnings)
- [ ] Document sources validated (docs still match implementation)

Original task:
{{PROMPT}}
