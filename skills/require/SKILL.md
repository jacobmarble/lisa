---
name: require
description: "Generate a Software Requirements Document for any software artifact (feature, bug fix, refactor, performance improvement, new API, new tool, etc.). Use when planning detailed requirements before implementation. Triggers on: create requirements for, write requirements for, require, requirements doc."
---

# Requirements Generator

Create detailed Software Requirements Documents that are clear, actionable, and suitable for implementation by AI agents. Works for any kind of software artifact — features, bug fixes, refactors, performance improvements, new APIs, new tools, and more.

---

## The Job

1. Receive an artifact description from the user
2. Interview the user in two phases with the AskUserQuestion tool
3. Generate a structured requirements document based on answers
4. Save to `.lisa/require-[doc-title].md`

**Important:** Do NOT start implementing. Just create the requirements document.

---

## Step 1: Two-Phase Interview

Use the AskUserQuestion tool throughout.

### Phase 1: Discover the Artifact

Determine the kind of work being planned. Ask about:

- **What kind of artifact is this?** Feature, bug fix, refactor, performance improvement, new API, new tool, migration, infrastructure change, etc.
- **Problem/Goal:** What problem does this solve or what outcome is desired?
- **Scope/Boundaries:** What is in scope and what is explicitly out?

### Phase 2: Kind-Relevant Deep Dive

Based on the artifact kind, ask follow-up questions from the relevant topics below. Not all topics apply to every artifact — skip what is irrelevant.

- **Existing code context:** Files, patterns, conventions already in the codebase
- **Constraints:** Performance, compatibility, security, operational, reliability
- **Interfaces:** APIs, CLIs, file formats, protocols
- **Data:** Schema changes, migrations, storage
- **Actors:** Who or what interacts with this system (users, services, operators, jobs)
- **Success criteria:** How do we know it is done?
- **Testing approach:** Unit, integration, end-to-end, manual verification

### Interview Guidance

- **Batch questions.** Ask 2–4 related questions per round, not one at a time.
- **Ask leading questions toward best practices**, but accept the user's override if they disagree.
- **Stop when you have enough information** to write unambiguous requirements. Do not over-interview.

---

## Step 2: Document Structure

Generate the requirements document with these sections:

### 1. Overview
Brief description of the artifact, the problem it solves, and the system context it fits into. State the artifact kind (feature, bug fix, refactor, etc.).

### 2. Goals
Bullet list of measurable objectives. Each must be specific and achievable.

### 3. Actors (If Applicable)
List all entities that interact with this system:
- **Users** (e.g., "End user searches via the CLI")
- **Internal services** (e.g., "Ingestion pipeline calls this API")
- **Operators** (e.g., "On-call engineers use this to diagnose issues")
- **Scheduled jobs** (e.g., "Nightly cleanup process invokes...")

Omit this section if there are no meaningful actor distinctions.

### 4. Requirements

Group requirements under **logical headings** (e.g., "Core Search", "Output Formatting", "Error Handling") rather than by type.

Each requirement needs:

- **ID:** REQ-001, REQ-002, etc.
- **Type label:** One of: functional, non-functional, technical, performance, interface, data, operational, security, reliability, testing, or a custom label
- **Title:** Short descriptive name
- **Description:** What the system must do, written as "The system will..."
- **Progress checkbox:** One `- [ ]` at the top of the requirement for tracking progress through requirements analysis
- **Acceptance Criteria:** Verifiable checklist of what "done" means

Optional sub-sections (include only when they add clarity):
- **Inputs/Outputs:** Specific data flowing in and out
- **Constraints:** Limits or boundaries for this requirement
- **Code References:** Existing files, functions, or patterns to follow
- **Examples:** Concrete input/output examples

**Format:**
````markdown
#### REQ-001: [Title]
**Type:** functional

- [ ] Requirements analysis complete

**Description:** The system will [specific behavior].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Tests pass
- [ ] Typecheck passes
````

**Important:** Acceptance criteria must be verifiable, not vague. "Works correctly" is bad. "Returns exit code 1 and prints error to stderr when input file does not exist" is good.

### 5. Non-Goals
What this artifact will NOT include. Critical for managing scope.

### 6. API Contracts (If Applicable)
Define interfaces this system exposes or consumes:
- Endpoint signatures or CLI argument specs
- Request/response schemas
- Error codes and conditions

### 7. Data Model (If Applicable)
- New tables, columns, or schema changes
- Data types and constraints
- Migration considerations

### 8. Technical Considerations
- Known constraints or dependencies
- Integration points with existing systems
- Failure modes and error handling approach

### 9. Open Questions
Remaining questions or areas needing clarification.

---

## Writing for Implementation

The requirements reader may be a junior developer or AI agent. Therefore:

- Be explicit and unambiguous
- Use precise technical language but explain domain-specific terms
- Provide enough detail to understand purpose and expected behavior
- Number all requirements for easy reference
- Where helpful, include concrete examples of inputs, outputs, and error conditions
- Specify exact error codes, status codes, and message formats

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `.lisa/`
- **Filename:** `require-[doc-title].md` (kebab-case)

---

## Example Requirements Document

````markdown
# Requirements: Log Search CLI Tool

## Overview

Build a CLI tool that searches structured log files by timestamp range, severity level, and text pattern. This is a **new tool** to replace manual `grep` workflows for incident response.

## Goals

- Search logs by time range, severity, and regex pattern in a single command
- Output results in human-readable and machine-parseable formats
- Handle files up to 10 GB without excessive memory usage
- Complete searches in under 5 seconds for typical 1 GB log files

## Actors

- **On-call engineers:** Primary users during incident response, need fast results under pressure
- **CI pipelines:** Invoke the tool in automated test log analysis jobs

## Requirements

### Core Search

#### REQ-001: Time range filtering
**Type:** functional

- [ ] Requirements analysis complete

**Description:** The system will filter log entries to only those within a specified start and end timestamp range.

**Acceptance Criteria:**
- [ ] Accepts `--from` and `--to` flags in ISO 8601 format
- [ ] Includes entries exactly matching boundary timestamps
- [ ] Returns empty result set (not an error) when no entries match
- [ ] Unit tests cover boundary conditions and empty results
- [ ] Typecheck passes

#### REQ-002: Severity filtering
**Type:** functional

- [ ] Requirements analysis complete

**Description:** The system will filter log entries by minimum severity level.

**Acceptance Criteria:**
- [ ] Accepts `--level` flag with values: debug, info, warn, error, fatal
- [ ] Filters to entries at the specified level or higher
- [ ] Defaults to showing all levels when flag is omitted
- [ ] Unit tests cover each severity level and the default
- [ ] Typecheck passes

#### REQ-003: Pattern matching
**Type:** functional

- [ ] Requirements analysis complete

**Description:** The system will filter log entries whose message matches a regex pattern.

**Acceptance Criteria:**
- [ ] Accepts `--pattern` flag with a regex string
- [ ] Uses RE2 syntax for safe, bounded execution
- [ ] Returns clear error message for invalid regex
- [ ] Unit tests cover matching, non-matching, and invalid patterns
- [ ] Typecheck passes

### Output Formatting

#### REQ-004: Human-readable output
**Type:** interface

- [ ] Requirements analysis complete

**Description:** The system will output search results in a human-readable format by default.

**Acceptance Criteria:**
- [ ] Default format: `[TIMESTAMP] [LEVEL] message`
- [ ] Colorized severity levels when stdout is a TTY
- [ ] No color codes when piped to another command
- [ ] Tests verify formatting for each severity level
- [ ] Typecheck passes

#### REQ-005: JSON output
**Type:** interface

- [ ] Requirements analysis complete

**Description:** The system will support JSON output for machine consumption.

**Acceptance Criteria:**
- [ ] `--format json` outputs one JSON object per line (JSON Lines)
- [ ] Each object contains: `timestamp`, `level`, `message`, `source`
- [ ] Valid JSON even when results are empty (zero lines, no wrapper)
- [ ] Tests verify JSON schema for each output line
- [ ] Typecheck passes

### Performance

#### REQ-006: Memory-bounded processing
**Type:** performance

- [ ] Requirements analysis complete

**Description:** The system will process log files using streaming I/O to avoid loading entire files into memory.

**Acceptance Criteria:**
- [ ] Peak memory usage stays under 50 MB for a 10 GB input file
- [ ] Uses line-by-line streaming, not file slurping
- [ ] Benchmark test confirms memory bound on a 1 GB fixture
- [ ] Typecheck passes

### Reliability

#### REQ-007: Graceful handling of malformed lines
**Type:** reliability

- [ ] Requirements analysis complete

**Description:** The system will skip log lines that do not match the expected format rather than crashing.

**Acceptance Criteria:**
- [ ] Malformed lines are skipped with a warning to stderr
- [ ] Warning includes the line number of the skipped line
- [ ] Search results from valid lines are still returned
- [ ] Unit test verifies behavior with mixed valid/malformed input
- [ ] Typecheck passes

### Operational

#### REQ-008: Exit codes
**Type:** operational

- [ ] Requirements analysis complete

**Description:** The system will use meaningful exit codes for scripting and CI integration.

**Acceptance Criteria:**
- [ ] Exit 0: results found
- [ ] Exit 1: no results found (successful search, empty result)
- [ ] Exit 2: error (invalid args, file not found, I/O failure)
- [ ] Tests verify each exit code scenario
- [ ] Typecheck passes

## Non-Goals

- No log ingestion or indexing — operates on raw files only
- No daemon mode or watching for new log entries
- No support for binary/non-text log formats
- No remote file access (local filesystem only)

## API Contracts

### CLI Interface

```
logsearch [OPTIONS] <FILE>

Options:
  --from <TIMESTAMP>    Start of time range (ISO 8601)
  --to <TIMESTAMP>      End of time range (ISO 8601)
  --level <LEVEL>       Minimum severity: debug|info|warn|error|fatal
  --pattern <REGEX>     Filter by message regex (RE2 syntax)
  --format <FORMAT>     Output format: text (default) | json
  -h, --help            Show help
  -V, --version         Show version
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Results found |
| 1 | No results found |
| 2 | Error (invalid args, file not found, etc.) |

## Technical Considerations

- Use streaming line reader to handle large files without memory issues
- RE2 regex engine for safe pattern matching (no catastrophic backtracking)
- Detect TTY for colorized output using `isatty` check on stdout
- Structured log format assumed: `[ISO8601] [LEVEL] message`

## Open Questions

- Should we support multiple input files or glob patterns?
- Should `--from` and `--to` support relative time expressions (e.g., `--from 1h`)?
- What log format variants need to be supported beyond the default structured format?
````

---

## Checklist

Before saving the requirements document:

- [ ] Completed Phase 1 interview (artifact kind, problem, scope)
- [ ] Completed Phase 2 interview (kind-relevant deep dive)
- [ ] Asked all questions with the AskUserQuestion tool
- [ ] Incorporated user's answers
- [ ] Every requirement has an ID (REQ-NNN), type label, title, description, progress checkbox, and acceptance criteria
- [ ] Requirements are grouped under logical headings
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] Non-goals section defines clear boundaries
- [ ] Saved to `.lisa/require-[doc-title].md`
