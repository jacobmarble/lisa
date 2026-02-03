#!/bin/bash
# Lisa - Long-running AI agent loop
# Usage: Run from your project directory: /path/to/lisa.sh [max_iterations]
#
# Expects in current directory:
#   - lisa.json (created via /lisa skill)
#   - progress.txt (created automatically)

set -e

# Parse arguments
MAX_ITERATIONS=${1:-10}

# SCRIPT_DIR = where lisa.sh lives (for LISA.md)
# PROJECT_DIR = current working directory (for lisa.json, progress.txt)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"

LISA_MD="$SCRIPT_DIR/LISA.md"
LISA_FILE="$PROJECT_DIR/lisa.json"
PROGRESS_FILE="$PROJECT_DIR/progress.txt"
ARCHIVE_DIR="$PROJECT_DIR/.lisa/archive"
LAST_BRANCH_FILE="$PROJECT_DIR/.lisa/.last-branch"

# Validate required files exist
if [ ! -f "$LISA_MD" ]; then
  echo "Error: LISA.md not found at $LISA_MD"
  exit 1
fi

if [ ! -f "$LISA_FILE" ]; then
  echo "Error: lisa.json not found in current directory"
  echo "Create it using the /lisa skill to convert an FRD or PRD."
  exit 1
fi

# Ensure .lisa directory exists
mkdir -p "$PROJECT_DIR/.lisa"

# Archive previous run if branch changed
if [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$LISA_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "lisa/" prefix from branch name for folder
    FOLDER_NAME="${LAST_BRANCH#lisa/}"
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$LISA_FILE" ] && cp "$LISA_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Lisa Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
CURRENT_BRANCH=$(jq -r '.branchName // empty' "$LISA_FILE" 2>/dev/null || echo "")
if [ -n "$CURRENT_BRANCH" ]; then
  echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Lisa Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Lisa - Max iterations: $MAX_ITERATIONS"
echo "Project: $PROJECT_DIR"

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "==============================================================="
  echo "  Lisa Iteration $i of $MAX_ITERATIONS"
  echo "==============================================================="

  OUTPUT=$(claude --dangerously-skip-permissions --print < "$LISA_MD" 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Lisa completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Lisa reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
