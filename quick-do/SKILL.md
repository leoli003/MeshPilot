---
name: quick-do
description: |
  Execute plans or tasks quickly without user confirmation during execution.
  Triggers when user wants to execute, run, or implement something: "quick do", "快速执行", "执行plan", "run plan", "implement this".
  Use this skill when user says: /mesh-quick-do, "执行", "do it", "make it happen".
---

## What this skill does

Executes plans or tasks in a single flow without intermediate confirmations. Automatically detects whether input is a plan or a task, generates plans if needed, and coordinates agent execution.

## Usage

```
/mesh-quick-do                    # Execute plan from context
/mesh-quick-do <plan>             # Execute the specified plan
/mesh-quick-do <task description> # Generate plan then execute
```

## Workflow

### Step 1: Parse Input

1. **No arguments** → Check context for existing plan
   - Check `.claude/plans/` for recent plans
   - Check conversation history for plan content
   - If no plan found: Tell user "未找到可执行的 plan，请提供任务或 plan"

2. **Has arguments** → Classify input
   - If input contains structured steps (numbered list, `## Steps`, etc.) → It's a **plan**, execute directly
   - If input is a description/request → It's a **task**, generate plan first

### Step 2: Generate Plan (if needed)

If input is a task, invoke `/mesh-quick-plan` to generate plan, then proceed to execution.

### Step 3: Execute Plan

Parse plan steps and assign to appropriate agents:

| Step Type | Agent |
|-----------|-------|
| Code implementation, refactoring | ecc:planner |
| Build/compile issues | ecc:build-error-resolver |
| Code review | ecc:code-reviewer |
| Testing | ecc:tdd-guide |
| Security | ecc:security-reviewer |
| Performance | ecc:performance-optimizer |
| Database | ecc:database-reviewer |
| Documentation | ecc:doc-updater |
| General/unknown | ecc:planner |

### Step 4: Coordinate Execution

Execute steps sequentially or in parallel where possible:

1. For each step, spawn appropriate agent with the task
2. Wait for completion, capture results
3. Pass context to next step if needed
4. Continue until all steps complete

**No user confirmation during execution** - run to completion.

### Step 5: Report Results

After all steps complete:
```
✓ Plan executed successfully

Completed steps:
1. [Step 1 description] ✓
2. [Step 2 description] ✓
...

Files modified: [list of files]
```

## Input Classification

### Plan Indicators (execute directly)
- Contains `## Steps` or numbered list
- Contains `1.`, `2.`, `3.` step markers
- Contains `Overview`, `Dependencies`, `Risks` sections
- Structured markdown with clear sections

### Task Indicators (generate plan first)
- Single sentence or paragraph
- Describes what to do, not how
- No structured steps
- Request format: "add X", "implement Y", "create Z"

## Context Plan Detection

Check for plans in this order:
1. `.claude/plans/*.md` - most recent file
2. Conversation history - look for plan-formatted content
3. Current session - check if plan was just generated

## Agent Coordination

### Sequential Execution
Steps that depend on previous results run sequentially:
```
Step 1 → wait → Step 2 → wait → Step 3
```

### Parallel Execution
Independent steps can run in parallel:
```
Step 1 ─┐
Step 2 ─┼→ wait → combine results
Step 3 ─┘
```

### Dependency Detection
- If step mentions "after X" or "using result from Y" → sequential
- If step modifies same files as another → sequential
- Otherwise → can parallelize

## Example 1: Execute from Context

```
User: /mesh-quick-do

[Check context, find plan in .claude/plans/auth-plan.md]

Executing plan: User Authentication

Step 1: Create auth module structure
  → ecc:planner: "Create auth module structure at src/auth/"
  → ✓ Created src/auth/, src/auth/types.ts

Step 2: Implement JWT handling
  → ecc:planner: "Implement JWT token management"
  → ✓ Created src/auth/jwt.ts

Step 3: Add login endpoint
  → ecc:planner: "Create login API endpoint"
  → ✓ Created src/api/auth.ts

✓ Plan executed successfully

Files created:
- src/auth/types.ts
- src/auth/jwt.ts
- src/api/auth.ts
```

## Example 2: Execute Task

```
User: /mesh-quick-do 添加用户登录功能

[Input is task, not plan → generate plan first]

Generating plan...
Plan generated with 3 steps.

Executing plan...

Step 1: Create auth module → ✓
Step 2: Implement JWT → ✓
Step 3: Add endpoint → ✓

✓ Plan executed successfully
```

## Example 3: Execute Provided Plan

```
User: /mesh-quick-do
# Plan: File Watcher

## Steps
1. Create watcher module
2. Implement file monitoring
3. Add logging
---

[Input is plan → execute directly]

Executing plan...

Step 1: Create watcher module → ✓
Step 2: Implement monitoring → ✓
Step 3: Add logging → ✓

✓ Plan executed successfully
```

## Error Handling

- If step fails: Log error, attempt recovery, continue if possible
- If critical failure: Stop, report what completed and what failed
- Never ask user for confirmation during execution

## Notes

- This skill prioritizes speed over interactivity
- All confirmations happen upfront (plan review) or at end (results)
- For complex multi-agent coordination, steps run in optimal order
- Agent selection can be overridden by step annotations (e.g., `[use: architect]`)
