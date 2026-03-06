# Lisa

Lisa is an autonomous agent runner for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It breaks requirements documents into small tasks and implements them one at a time, each in a fresh Claude context.

## How it works

1. `/require` — interview-driven skill that produces a requirements doc (`.lisa/require-*.md`)
2. `/backlog` — converts requirements into ordered tasks (`.lisa/requirements.json`)
3. `lisa.sh` — loops Claude iterations, one task per iteration, until everything passes

Each iteration is stateless. The agent reads `.lisa/requirements.json`, finds the first incomplete task, implements it, verifies it (typecheck/lint/test), commits, and stops. The runner detects completion and either starts the next iteration or exits.

## Setup

Clone the repo:

```sh
git clone git@github.com:jacobmarble/lisa.git
cd lisa
```

Symlink the skills into your Claude Code skills directory:

```sh
mkdir -p ~/.claude/skills
ln -s "$(pwd)/skills/require" ~/.claude/skills/require
ln -s "$(pwd)/skills/backlog" ~/.claude/skills/backlog
ln -s "$(pwd)/skills/prd" ~/.claude/skills/prd
ln -s "$(pwd)/skills/frd" ~/.claude/skills/frd
```

Optionally, symlink `lisa.sh` somewhere on your PATH:

```sh
ln -s "$(pwd)/lisa.sh" /usr/local/bin/lisa
```

## Usage

From your project directory:

```sh
# 1. Generate requirements (interactive)
/require

# 2. Convert to task backlog (interactive)
/backlog

# 3. Run the agent loop
lisa.sh        # default: 10 iterations
lisa.sh 25     # or specify a max
```

## Skills

| Skill | Purpose |
|-------|---------|
| `/require` | Generate a structured requirements document through a user interview |
| `/backlog` | Convert a requirements doc into `.lisa/requirements.json` task list |
| `/prd` | Generate a Product Requirements Document |
| `/frd` | Generate a Functional Requirements Document |

## Project state

All Lisa state lives in `.lisa/` inside your target project:

| File | Purpose |
|------|---------|
| `.lisa/require-*.md` | Requirements documents |
| `.lisa/requirements.json` | Task backlog with pass/fail status |
| `.lisa/progress.txt` | Iteration log and codebase patterns |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (used by `lisa.sh` to check task completion)
