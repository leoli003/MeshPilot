---
name: mesh-ralph-tdd-doc
description: End-to-end project execution with Test-Driven Development and document-informed requirements. Orchestrates grill-with-docs → to-issues → ralph+TDD. Uses existing documentation as context for requirements, then implements every story with strict TDD. Use when user has existing docs/specs AND wants guaranteed quality with 80%+ test coverage, mentions "mesh-ralph-tdd-doc", or wants document-informed TDD development.
argument-hint: "[--coverage=80] [--e2e] [--no-e2e] [--docs=<path>] <project description>"
level: 4
---

# Mesh Ralph TDD Doc - Document-Informed TDD Project Execution

A three-phase orchestration that combines document-informed requirements gathering, planning, and **test-driven execution** for maximum code quality.

## When to Use

- User has existing PRDs, specs, or design documents to work from
- User wants to create something with **guaranteed test coverage**
- User says "mesh-ralph-tdd-doc" or "/mesh-ralph-tdd-doc"
- User wants rigorous test-first development with document context
- Project requires 80%+ test coverage and TDD discipline
- User needs verified, tested, complete delivery with TDD provenance

## Workflow Overview

```
┌─────────────────┐     ┌─────────────┐     ┌─────────────────┐
│    Phase 1      │     │  Phase 2    │     │    Phase 3      │
│ grill-with-docs │ ──► │  to-issues  │ ──► │  ralph + TDD    │
│  Doc Interview  │     │   Plan      │     │  Test-First     │
└─────────────────┘     └─────────────┘     └─────────────────┘
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

**Output:** A set of independently-grabbable issues with test type annotations.

## Phase 3: Execution with TDD (ralph + TDD)

**Goal:** Execute all issues using strict Test-Driven Development with verification.

**Core Principle:**
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

**Process:**
1. Invoke the `ralph` skill via Skill tool: `Skill("ralph")`
2. For each issue, follow the **TDD-Enhanced Ralph Loop** (see below)
3. Verify acceptance criteria AND test coverage for each issue
4. Continue until all issues pass verification with 80%+ coverage
5. Run architect/code review for final approval

**Output:** A complete, tested, verified implementation with TDD provenance.

## TDD-Enhanced Ralph Loop

For each story in `prd.json`:

### Step 1: Pick Next Story
Read `prd.json` and select the highest-priority story with `passes: false`.

### Step 2: TDD Cycle for Each Acceptance Criterion

For EACH acceptance criterion in the story:

#### 2.1 RED - Write Failing Test
Write one minimal test showing what should happen.

**Requirements:**
- One behavior per test
- Clear, descriptive name
- Real code (no mocks unless unavoidable)
- Test must fail for the RIGHT reason (feature missing, not typo)

#### 2.2 Verify RED - Watch It Fail
**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.
**Test errors?** Fix error, re-run until it fails correctly.

#### 2.3 GREEN - Minimal Code
Write simplest code to pass the test. Do NOT add features, refactor other code, or "improve" beyond the test.

#### 2.4 Verify GREEN - Watch It Pass
**MANDATORY.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

#### 2.5 REFACTOR - Clean Up
After green only:
- Remove duplication
- Improve names
- Extract helpers

Keep tests green. Don't add behavior.

#### 2.6 BACKTRACK - Test Design Fix (When Needed)
If during GREEN or REFACTOR you discover the test itself is flawed:
1. **Stop immediately** - do not continue with broken test design
2. **Document the issue** - why is the test wrong?
3. **Return to RED** - rewrite the test with correct assertions
4. **Re-run the cycle** - RED → GREEN → REFACTOR

Common reasons to backtrack:
- Test asserts implementation details, not behavior
- Test is too broad (tests multiple behaviors)
- Test doesn't actually verify the acceptance criterion
- Test is brittle (will break on unrelated changes)

### Step 3: Verify Story Acceptance Criteria
After all TDD cycles for the story:
1. Run all tests using project's test runner
2. Run coverage report
3. Verify coverage meets threshold (critical paths 80%+, global 60%+)
4. Mark story `passes: true` in `prd.json`

### Step 4: Check PRD Completion
- If NOT all stories complete, loop back to Step 1
- If ALL complete, proceed to Step 5 (reviewer verification)

### Step 5: Reviewer Verification
Same as ralph: architect/critic/codex verification against acceptance criteria.

### Step 6: Final Coverage Report
Generate and verify final coverage report using project's test runner.

Confirm:
- Global coverage ≥ 60% line (or configured threshold)
- Critical path coverage ≥ 80% branch
- No skipped tests without documented reason

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
3. It will be picked up in the next iteration of Step 1

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
      "skipTdd": false,
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
- `skipTdd`: If `true`, skip TDD cycle for this story (use sparingly)
- `acceptance`: Array of acceptance criteria (each becomes a test)
- `passes`: Set to `true` only after all tests pass and coverage verified
- `blockedBy`: Array of story IDs that must complete first

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
- Test coverage reports
- Verification checkpoints
```

## Test Type Configuration

Each issue can specify test types:

| Type | Required | Description |
|------|----------|-------------|
| `unit` | Always | Individual functions, components, utilities |
| `integration` | Default | API endpoints, database operations, service interactions |
| `e2e` | Critical flows only | Full user journeys with Playwright |
| `skip-tdd` | Exceptional only | Skip TDD cycle (config changes, docs, pure UI tweaks) |

**When to use `skipTdd: true`:**
- Configuration file modifications (no logic to test)
- Documentation updates
- Pure visual tweaks (color, spacing, font)
- Third-party integration boilerplate

**CLI Arguments:**
- `--coverage=90` - Set coverage threshold (default: 80)
- `--coverage-type=line|branch` - Coverage type (default: line)
- `--e2e` - Force E2E tests for ALL issues (not just critical flows)
- `--no-e2e` - Skip E2E tests for this run
- `--docs=<path>` - Specify document location

**Coverage Policy:**
- Critical paths (auth, data, API): 80%+ branch coverage
- UI components: 60%+ line coverage acceptable
- Global minimum: 60% line coverage

## Test File Organization

```
src/
├── components/
│   └── Button/
│       ├── Button.tsx
│       └── Button.test.tsx          # Unit tests
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # Integration tests
└── e2e/
    └── markets.spec.ts               # E2E tests
```

## Execution Rules

1. **Always invoke skills in order:** grill-with-docs → to-issues → ralph (with TDD)
2. **Every story goes through TDD** - unless marked with `skipTdd: true`
3. **Watch tests fail before implementing** - this is non-negotiable
4. **Wait for phase completion** - do not proceed until current phase is complete
5. **Preserve context** - pass all learnings from each phase to the next
6. **User approval gates** - get user approval before proceeding between phases
7. **Document-first** - Prioritize information from existing docs over assumptions
8. **Allow backtracking** - if test design is wrong, return to RED and fix it

## TDD Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Keep as reference" or "adapt existing code"

**All of these mean: Delete code. Start over with TDD.**

## Example Usage

```
User: /mesh-ralph-tdd-doc 实现用户认证模块

Phase 1 - grill-with-docs:
- Reading docs/prds/auth.md...
- Reading docs/architecture.md...
- Q: The PRD specifies JWT auth. Should we use RS256 or HS256?
- Q: The design doc mentions refresh tokens. Should they rotate on each use?
- ... (continue until spec is clear)

Phase 2 - to-issues:
- Issue 1: Set up user model and database schema [unit]
- Issue 2: Implement password hashing [unit]
- Issue 3: Create registration endpoint [unit, integration]
- Issue 4: Create login endpoint [unit, integration]
- Issue 5: Add JWT token generation [unit]
- Issue 6: E2E: Full registration and login flow [e2e]
- ... (get user approval)

Phase 3 - ralph + TDD:
- Issue 1:
  - RED: Write test for user model
  - Verify RED: Watch it fail
  - GREEN: Implement user model
  - Verify GREEN: Watch it pass
  - REFACTOR: Clean up
  - Coverage check: 85%
- Issue 2:
  - RED: Write test for password hashing
  - ... (repeat TDD cycle)
- ... (continue until all issues complete)
- Final coverage: 87%
- Architect review: APPROVED
```

## Arguments

The skill accepts the project description with optional configuration:

```
/mesh-ralph-tdd-doc [--coverage=N] [--e2e] [--no-e2e] [--docs=<path>] <project description>
```

Examples:
- `/mesh-ralph-tdd-doc 创建贪吃蛇游戏`
- `/mesh-ralph-tdd-doc --coverage=90 --docs=prds/auth.md 实现用户认证`
- `/mesh-ralph-tdd-doc --e2e 创建用户认证模块` (强制所有 issue 运行 E2E)
- `/mesh-ralph-tdd-doc --no-e2e implement a markdown parser`

## Important Notes

- This skill is an orchestration layer - it delegates actual work to sub-skills
- Always use `Skill()` tool to invoke sub-skills, not direct execution
- **TDD is non-negotiable** - every story must follow the RED-GREEN-REFACTOR cycle
- **Document-first approach** - Existing documentation takes precedence over assumptions
- The quality of the final output depends on thoroughness in Phase 1 (grill-with-docs)
- If the user already has a clear spec, you may skip Phase 1 and start from Phase 2
- If the user already has issues created, you may skip to Phase 3 directly

## Skill Invocation Reference

```javascript
// Phase 1
Skill("grill-with-docs")

// Phase 2
Skill("to-issues")

// Phase 3 (ralph with TDD discipline)
Skill("ralph")
// Then enforce TDD cycle for each story
```

## Comparison with Related Skills

| Feature | mesh-ralph | mesh-ralph-doc | mesh-ralph-tdd | mesh-ralph-tdd-doc |
|---------|------------|----------------|----------------|-------------------|
| Requirements Phase | grill-me | grill-with-docs | grill-me | grill-with-docs |
| TDD Enforcement | No | No | Yes | Yes |
| Starting Point | Interview only | Docs + interview | Interview only | Docs + interview |
| Best For | New projects | Existing specs | Quality-first | Spec + quality |

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered
- [ ] Coverage ≥ 80% (or configured threshold)
- [ ] All prd.json stories have `passes: true`
- [ ] Selected reviewer verification passed

Original task:
{{PROMPT}}
