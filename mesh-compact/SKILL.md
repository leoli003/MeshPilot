---
name: mesh-compact
description: Compact the current conversation while preserving key context. Use when the conversation is getting long, context feels bloated, or you want to "clean up" without losing progress. Works like a hibernate function - save context to file, compact history, then read it back to continue seamlessly.
argument-hint: Optional focus area for the handoff summary (e.g., "focus on the auth module changes")
---

# Mesh Compact

A context management skill that compresses the conversation while preserving essential information. Like hibernating a computer: save state → clear memory → restore state → continue working.

## When to Use

- Conversation has become long and responses are slowing down
- You want to clean up context but keep important decisions and progress
- Mid-session context refresh without starting over
- Before entering a new major phase of work

## Workflow

Execute these three steps in order:

### Step 1: Generate Handoff Document

Create a handoff document summarizing the current conversation:

```bash
mktemp -t handoff-XXXXXX.md
```

Read the generated file path, then write a comprehensive summary including:

- **What was done**: Key accomplishments and changes made
- **Important decisions**: Choices made and why
- **Current state**: Where things stand now
- **Next steps**: Pending tasks or logical continuation
- **Key files**: Important file paths referenced
- **Context pointers**: References to existing artifacts (PRDs, plans, ADRs, issues, commits) — do NOT duplicate their content

If the user provided arguments, focus the summary on that area.

Save the handoff document to the temp file path.

### Step 2: Compact the Conversation

Execute the `/compact` command to compress the conversation history:

```
/compact
```

This will:
- Summarize and remove older conversation turns
- Free up context window space
- Keep only recent, essential exchanges

### Step 3: Read Back the Handoff Document

After compaction completes, read the handoff document you saved in Step 1:

```bash
# Read the file path from Step 1
```

This loads the key context back into the current session, allowing you to continue working seamlessly.

## Output Format

The handoff document should follow this structure:

```markdown
# Handoff Summary

## Completed Work
- [Brief list of what was accomplished]

## Key Decisions
- [Important choices made and rationale]

## Current State
- [Where things stand now]

## Next Steps
- [Pending tasks or natural continuation]

## Key Files
- [Important file paths]

## References
- [Links to existing artifacts: PRDs, plans, ADRs, issues, etc.]
```

## Example Usage

```
User: /mesh-compact
Assistant: 
1. Creating handoff document at /tmp/handoff-abc123.md...
2. Handoff saved. Now executing /compact...
3. Compaction complete. Reading back handoff document...
4. Context restored. Ready to continue!

Summary of preserved context:
- Completed: Authentication flow implementation
- Current state: Tests passing, ready for integration
- Next: Connect to backend API
```

## Notes

- Do NOT duplicate content from existing artifacts (PRDs, plans, commits) — reference them by path instead
- Keep the handoff document concise but comprehensive
- Focus on information that would be hard to rediscover (decisions, rationale, non-obvious context)
- The temp file will be cleaned up by the system; the context is now in the conversation
