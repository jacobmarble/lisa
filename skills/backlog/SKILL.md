---
name: backlog
description: "Convert PRDs or FRDs to requirements.json format for the Lisa autonomous agent system. Use when you have an existing PRD or FRD and need to convert it to Lisa's task format. Triggers on: convert this prd, convert this frd, turn this into lisa format, create requirements.json from this, create backlog from this."
---

# Lisa Backlog Converter

Converts existing PRDs (Product Requirements Documents) or FRDs (Functional Requirements Documents) to the requirements.json format that Lisa uses for autonomous execution. Requirements from either document type become entries in the `tasks` array.

---

## The Job

1. Find the input requirements document (see Step 0)
2. Interview the user to clarify implementation details using the AskUserQuestion tool
3. Convert to `.lisa/requirements.json` in the **target project's directory** (where the code lives)

**Important:** Do NOT skip the interview. Details that seem obvious in a requirements doc often become ambiguous when breaking work into concrete tasks.

---

## Step 0: Find the Input Document

If the user provides a specific file or document, use that.

If the user provides **no additional prompt** (bare `/backlog` invocation), auto-discover the input:

1. Glob for `.lisa/require-*.md` files in the current project
2. **If exactly one match:** use it as the input document. Tell the user which file you're using.
3. **If multiple matches:** use AskUserQuestion to ask which document to convert. List each filename as an option.
4. **If no matches:** tell the user no requirements documents were found in `.lisa/` and ask them to provide one or run the `/require` skill first.

---

## Step 1: Interview

After reading the source document, interview the user using the AskUserQuestion tool. The goal is to surface ambiguities and implementation details that affect how tasks are split, ordered, and verified.

### What to Ask About

Pick questions relevant to the document. Not all topics apply every time.

- **Target project:** Where does the code live? What is the tech stack, framework, and language? What are the build/test/typecheck commands?
- **Task granularity:** Are there requirements the user considers trivial (combine into one task) or large (need extra splitting)?
- **Implementation order:** Are there dependencies between requirements that aren't obvious from the document? Does the user want a specific ordering?
- **Scope adjustments:** Are there requirements to defer, skip, or deprioritize for this run?
- **Existing patterns:** Are there existing files, components, or conventions the tasks should follow? Code to reference or reuse?
- **Verification:** Beyond typecheck, what verification matters? Specific test commands, linting, browser checks?
- **Branch naming:** Does the user have a preferred branch name, or should one be derived from the feature?

### Interview Guidance

- **Batch questions.** Ask 2–4 related questions per round, not one at a time.
- **Ask leading questions toward best practices**, but accept the user's override if they disagree.
- **Stop when you have enough information** to produce unambiguous, right-sized tasks. Do not over-interview.
- **Use what you learn** to inform task splitting, ordering, acceptance criteria, and descriptions.

---

## Step 2: Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "lisa/[feature-name-kebab-case]",
  "description": "[Feature description from PRD/FRD title/intro]",
  "tasks": [
    {
      "id": "T-001",
      "title": "[Task title]",
      "description": "[What needs to be done and why]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Task Size: The Number One Rule

**Each task must be completable in ONE Lisa iteration (one context window).**

Lisa spawns a fresh Claude instance per iteration with no memory of previous work. If a task is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized tasks:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" → Split into: schema, queries, UI components, filters
- "Add authentication" → Split into: schema, middleware, login UI, session handling
- "Refactor the API" → Split into one task per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Task Ordering: Dependencies First

Tasks execute in priority order. Earlier tasks must not depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**Wrong order:**
1. UI component (depends on schema that does not exist yet)
2. Schema change

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something Lisa can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Tests pass"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include as final criterion:
```
"Typecheck passes"
```

For tasks with testable logic, also include:
```
"Tests pass"
```

### For tasks that change UI, also include:
```
"Verify in browser using dev-browser skill"
```

Frontend tasks are NOT complete until visually verified. Lisa will use the dev-browser skill to navigate to the page, interact with the UI, and confirm changes work.

---

## Conversion Rules

1. **Each requirement becomes one JSON entry** in the `tasks` array
2. **IDs**: Sequential (T-001, T-002, etc.)
3. **Priority**: Based on dependency order, then document order
4. **All tasks**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name, kebab-case, prefixed with `lisa/`
6. **Always add**: "Typecheck passes" to every task's acceptance criteria

---

## Splitting Large Requirements

If a PRD/FRD has big features, split them:

**Original:**
> "Add user notification system"

**Split into:**
1. T-001: Add notifications table to database
2. T-002: Create notification service for sending notifications
3. T-003: Add notification bell icon to header
4. T-004: Create notification dropdown panel
5. T-005: Add mark-as-read functionality
6. T-006: Add notification preferences page

Each is one focused change that can be completed and verified independently.

---

## Example

**Input PRD:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Output requirements.json:**
```json
{
  "project": "TaskApp",
  "branchName": "lisa/task-status",
  "description": "Task Status Feature - Track task progress with status indicators",
  "tasks": [
    {
      "id": "T-001",
      "title": "Add status field to tasks table",
      "description": "Add database column to store task status.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "T-002",
      "title": "Display status badge on task cards",
      "description": "Show visual indicator of task status on each card.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    },
    {
      "id": "T-003",
      "title": "Add status toggle to task list rows",
      "description": "Allow changing task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 3,
      "passes": false,
      "notes": ""
    },
    {
      "id": "T-004",
      "title": "Filter tasks by status",
      "description": "Allow filtering the list to show only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 4,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Checklist Before Saving

Before writing `.lisa/requirements.json`, verify:

- [ ] Completed interview with AskUserQuestion tool
- [ ] Incorporated user's answers into task design
- [ ] Each task is completable in one iteration (small enough)
- [ ] Tasks are ordered by dependency (schema → backend → UI)
- [ ] Every task has "Typecheck passes" as criterion
- [ ] UI tasks have "Verify in browser using dev-browser skill" as criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No task depends on a later task
