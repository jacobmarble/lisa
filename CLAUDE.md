# Lisa Project

Lisa is an autonomous AI agent runner that implements features from FRDs/PRDs by breaking them into small, independently-completable tasks.

## Architecture

```
User creates FRD → /lisa skill converts to requirements.json → lisa.sh runs iterations → Agent implements stories
```

## Key Files

| File | Purpose |
|------|---------|
| `lisa.sh` | Main runner script. Loops Claude iterations until all stories pass or max iterations reached. |
| `LISA.md` | Agent instructions piped to Claude each iteration. Tells the agent how to find and implement stories. |
| `skills/frd/SKILL.md` | Skill for generating Functional Requirements Documents. |
| `skills/backlog/SKILL.md` | Skill for converting FRDs/PRDs to `requirements.json` format. |

## How It Works

1. **lisa.sh** runs from the target project directory
2. Each iteration pipes **LISA.md** to `claude --dangerously-skip-permissions --print`
3. Agent reads `requirements.json`, finds first task where `passes: false`
4. Agent implements the task, runs verification, commits if passing
5. Agent updates `requirements.json` to mark task complete
6. If all tasks pass, agent outputs `<promise>COMPLETE</promise>`
7. lisa.sh detects completion signal and exits, or continues to next iteration

## File Locations

When lisa.sh runs:
- **LISA.md** is read from where lisa.sh lives (this directory)
- **requirements.json**, **progress.txt** are in the target project's `.lisa/` directory

## Design Principles

- **One task per iteration**: Each Claude invocation is stateless. Tasks must be small enough to complete in one context window.
- **Dependency ordering**: Tasks are ordered so earlier ones don't depend on later ones. The agent always picks the first incomplete task.
- **Verification before commit**: Agent must pass typecheck/lint/tests before marking a task complete.
- **Progress persistence**: `progress.txt` and `requirements.json` are the only state between iterations.

## Modifying LISA.md

When editing LISA.md, remember:
- It's the entire prompt for each iteration
- The agent has no memory of previous iterations
- Must be self-contained with clear instructions
- Keep it concise - it consumes context window

## Testing Changes

To test changes to Lisa:
1. Create a simple test project with a small `requirements.json`
2. Run `./lisa.sh 1` for a single iteration
3. Check that the agent correctly identifies and attempts the first incomplete task
