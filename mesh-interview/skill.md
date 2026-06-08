---
name: mesh-interview
description: Socratic interview for requirement clarification WITHOUT execution or file generation. Use when you want to discuss ideas, clarify requirements, and resolve ambiguities through structured Q&A. Trigger on phrases like "mesh interview", "discuss requirements", "clarify my idea", "help me think through this", "interview me about", "let's discuss".
argument-hint: "[--quick|--standard|--deep] <idea or topic>"
level: 2
---

<Purpose>
Mesh Interview implements Socratic questioning with mathematical ambiguity scoring for requirement clarification. Unlike deep-interview, it does NOT generate spec files, does NOT write to disk, and does NOT offer execution paths. It is purely for discussion, alignment, and clarity validation.
</Purpose>

<Use_When>
- User wants to discuss an idea without committing to implementation
- User says "mesh interview", "discuss requirements", "let's talk through this"
- User wants to clarify their own thinking before deciding what to build
- User wants to validate requirements with stakeholders
- User wants to explore alternatives without generating artifacts
- User wants to understand ambiguity in their requirements
</Use_When>

<Do_Not_Use_When>
- User wants to generate a spec file → use deep-interview instead
- User wants to execute or implement → use deep-interview or direct execution
- User wants to create planning artifacts → use omc-plan
- User wants a quick fix or single change → delegate to executor
</Do_Not_Use_When>

<Key_Differences_From_Deep_Interview>

| Feature | deep-interview | mesh-interview |
|---------|----------------|----------------|
| Generates spec file | ✅ .omc/specs/ | ❌ No files |
| Offers execution paths | ✅ autopilot/ralph/team | ❌ Discussion only |
| Writes to disk | ✅ State + spec | ❌ Memory only |
| Ambiguity scoring | ✅ | ✅ |
| Socratic Q&A | ✅ | ✅ |
| Topology tracking | ✅ | ✅ |
| Challenge agents | ✅ | ✅ |
| Purpose | Build-ready specs | Clarity & alignment |

</Key_Differences_From_Deep_Interview>

<Execution_Policy>
- Ask ONE question at a time -- never batch multiple questions
- Target the WEAKEST clarity dimension with each question
- Run Round 0 topology enumeration before Phase 2 scoring
- Make weakest-dimension targeting explicit every round
- Score ambiguity after every answer -- display the score transparently
- Keep everything in memory -- NO file writes
- When ambiguity ≤ threshold, summarize conclusions and END
- Allow early exit at any time
- Challenge agents activate at specific round thresholds
</Execution_Policy>

<Steps>

## Phase 0: Resolve Ambiguity Threshold

1. **Read threshold settings in precedence order**:
   - User settings: `[$CLAUDE_CONFIG_DIR|~/.claude]/settings.json`
   - Project settings: `./.claude/settings.json`
   - Default: `0.2` (20%)

2. **Resolve threshold and source**:
   - Read `omc.meshInterview.ambiguityThreshold` or fallback to `omc.deepInterview.ambiguityThreshold`
   - Default: `0.2`

3. **Announce the interview**:

```
Mesh Interview threshold: <resolvedThresholdPercent> (source: <resolvedThresholdSource>)

Starting mesh interview. We'll discuss your idea through targeted questions. I'll show clarity scores after each answer. This is a discussion only — no files will be generated.

**Your idea:** "{initial_idea}"
**Current ambiguity:** 100% (we haven't started yet)
```

## Phase 1: Initialize (Memory Only)

Store in memory (NOT to disk):

```javascript
{
  interview_id: "<uuid>",
  type: "greenfield|brownfield",
  initial_idea: "<user input>",
  rounds: [],
  current_ambiguity: 1.0,
  threshold: <resolvedThreshold>,
  topology: {
    status: "pending|confirmed",
    components: [],
    deferrals: []
  },
  challenge_modes_used: [],
  ontology_snapshots: []
}
```

## Round 0: Topology Enumeration

1. **Enumerate candidate top-level components** from the initial idea
2. **Ask confirmation**:

```
Round 0 | Topology confirmation | Ambiguity: not scored yet

I'm reading this as {N} top-level component(s):
1. {component_name}: {one_sentence_description}
2. ...

Is that topology right?
```

3. **Lock topology** in memory after confirmation

## Phase 2: Interview Loop

Repeat until `ambiguity ≤ threshold` OR user exits:

### Step 2a: Generate Next Question

Same strategy as deep-interview:
- Identify the weakest dimension across all components
- Generate a question targeting that dimension
- Questions should expose ASSUMPTIONS, not gather feature lists

### Step 2b: Ask the Question

```
Round {n} | Component: {target} | Targeting: {weakest_dimension} | Ambiguity: {score}%

{question}
```

### Step 2c: Score Ambiguity

Score clarity across dimensions (same formula as deep-interview):

| Dimension | Weight (Greenfield) | Weight (Brownfield) |
|-----------|---------------------|---------------------|
| Goal Clarity | 40% | 35% |
| Constraint Clarity | 30% | 25% |
| Success Criteria | 30% | 25% |
| Context Clarity | N/A | 15% |

### Step 2d: Report Progress

```
Round {n} complete.

| Dimension | Score | Weight | Weighted | Gap |
|-----------|-------|--------|----------|-----|
| Goal | {s} | {w} | {s*w} | {gap or "Clear"} |
| Constraints | {s} | {w} | {s*w} | {gap or "Clear"} |
| Success Criteria | {s} | {w} | {s*w} | {gap or "Clear"} |
| **Ambiguity** | | | **{score}%** | |

**Ontology:** {entity_count} entities | Stability: {stability_ratio}
```

## Phase 3: Challenge Agents

Same thresholds as deep-interview:
- **Round 4+**: Contrarian Mode
- **Round 6+**: Simplifier Mode
- **Round 8+**: Ontologist Mode (if ambiguity > 0.3)

## Phase 4: Summary (No File Generation)

When ambiguity ≤ threshold (or user exits):

### Generate Discussion Summary

Display a summary in the conversation:

```markdown
## Mesh Interview Summary

### Clarity Achieved
| Dimension | Final Score | Status |
|-----------|-------------|--------|
| Goal Clarity | {s} | ✅ Clear / ⚠️ Needs work |
| Constraint Clarity | {s} | ✅ Clear / ⚠️ Needs work |
| Success Criteria | {s} | ✅ Clear / ⚠️ Needs work |
| **Final Ambiguity** | **{score}%** | ✅ Below threshold / ⚠️ Above threshold |

### Topology Confirmed
{List of components discussed}

### Key Decisions
- {decision 1}
- {decision 2}
- ...

### Constraints Identified
- {constraint 1}
- {constraint 2}
- ...

### Acceptance Criteria (Draft)
- [ ] {criterion 1}
- [ ] {criterion 2}
- ...

### Entities Identified
| Entity | Type | Key Fields |
|--------|------|------------|
| {name} | {type} | {fields} |

### Open Questions (if any)
- {unresolved question 1}
- {unresolved question 2}

---

**This was a discussion only.** No files were generated.
If you want to proceed with implementation, consider:
- Using `/deep-interview` to generate a spec file
- Using `/comet-open` to create an OpenSpec change
- Implementing directly if requirements are clear enough
```

### Final Question

```
Discussion complete! Your clarity score is {score}%.

What would you like to do next?
```

**Options:**
1. **Continue discussing** - Ask more questions
2. **Generate spec with deep-interview** - Create a buildable spec
3. **Create OpenSpec change** - Use comet-open workflow
4. **End discussion** - Just needed to think through this

</Steps>

<Tool_Usage>
- Use `AskUserQuestion` for each interview question
- Use opus model (temperature 0.1) for ambiguity scoring
- NEVER use Write tool - keep everything in memory
- NEVER invoke execution skills (autopilot, ralph, team)
- Topology and ontology tracking same as deep-interview
</Tool_Usage>

<Examples>

<Good>
```
User: /mesh-interview I want to add user authentication

Mesh Interview threshold: 20% (source: default)

Starting mesh interview. We'll discuss your idea through targeted questions...

Round 0 | Topology confirmation
I'm reading this as 1 top-level component:
1. Authentication System: User login/logout functionality

Is that right?
```

Good: Confirms topology, asks one question at a time, no files generated.
</Good>

<Good>
```
Round 3 complete.

| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|----------|
| Goal | 0.8 | 40% | 0.32 |
| Constraints | 0.6 | 30% | 0.18 |
| Success Criteria | 0.7 | 30% | 0.21 |
| **Ambiguity** | | | **29%** |

Discussion complete! Your clarity score is 29%.

What would you like to do next?
```

Good: Shows clear progress, offers options, no file generation.
</Good>

<Bad>
```
Generating spec file at .omc/specs/mesh-interview-auth.md...
```

Bad: mesh-interview should NEVER write files.
</Bad>

<Bad>
```
Launching autopilot to implement authentication...
```

Bad: mesh-interview should NEVER trigger execution.
</Bad>

</Examples>

<Configuration>

Optional settings in `.claude/settings.json`:

```json
{
  "omc": {
    "meshInterview": {
      "ambiguityThreshold": 0.2,
      "maxRounds": 20,
      "softWarningRounds": 10,
      "enableChallengeAgents": true
    }
  }
}
```

</Configuration>
