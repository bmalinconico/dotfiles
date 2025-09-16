#!/usr/bin/env bash
set -euo pipefail

# --- git-clean-branches (Interactive) ---
# Deletes local branches that have been merged into a target branch.
# By default, it only auto-deletes fully merged branches and lists the rest.
# With the -i or --interactive flag, it interactively reviews other branches.

# --- 1. Argument Parsing ---
INTERACTIVE_MODE=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--interactive)
      INTERACTIVE_MODE=true
      shift # past argument
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# Restore positional arguments
set -- "${POSITIONAL_ARGS[@]}"


# --- 2. Setup ---
# Remember where we started so we can return at the end.
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch is '$CURRENT_BRANCH'. Will return here when done."

# Determine the branch to compare against (the "target").
# Use the first positional argument if provided.
if [ -n "${1-}" ]; then
  TARGET_BRANCH="$1"
else
  # Otherwise, try to auto-detect the default branch from the 'origin' remote.
  REMOTE_DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [ -n "$REMOTE_DEFAULT" ]; then
    TARGET_BRANCH="$REMOTE_DEFAULT"
    echo "Auto-detected target branch '$TARGET_BRANCH' from origin's HEAD."
  else
    # As a fallback, check for local 'main' or 'master'.
    if git show-ref --verify --quiet refs/heads/main; then
      TARGET_BRANCH="main"
    elif git show-ref --verify --quiet refs/heads/master; then
      TARGET_BRANCH="master"
    else
      echo "ERROR: Could not determine a target branch (like 'main' or 'master')." >&2
      echo "Please specify one, e.g., '$0 main'" >&2
      exit 1
    fi
    echo "Could not auto-detect remote default. Using local '$TARGET_BRANCH' as target."
  fi
fi

# Switch to the target branch to ensure a correct basis for comparisons.
if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
  git checkout -q "$TARGET_BRANCH"
fi

# --- 3. Update & Prune ---
echo "Fetching latest changes and pruning stale remote-tracking branches..."
git fetch --prune origin
echo "Updating local target branch '$TARGET_BRANCH' to match its remote..."
git reset --hard "origin/$TARGET_BRANCH"

# --- 4. Automatic Cleanup of Fully Merged Branches ---
echo
echo "--- Pass 1: Automatically cleaning fully merged branches ---"
MERGED_BRANCHES=$(git branch --merged "$TARGET_BRANCH" | grep -vE "^\*|master|main|develop|${TARGET_BRANCH}$" | tr -d ' *' || true)

if [ -n "$MERGED_BRANCHES" ]; then
  echo "The following branches are fully merged and will be deleted automatically:"
  echo "$MERGED_BRANCHES"
  echo "$MERGED_BRANCHES" | xargs -r git branch -d
else
  echo "No fully merged branches to clean automatically."
fi

# --- 5. Review Remaining Branches (Interactive or Report) ---
echo
echo "--- Pass 2: Reviewing remaining branches ---"

# Collect all branches into a bash array
all_branches=()
while IFS= read -r b; do all_branches+=("$b"); done < <(git for-each-ref refs/heads/ "--format=%(refname:short)")

branches_to_review=()
for branch in "${all_branches[@]}"; do
  # Check if branch still exists (wasn't deleted in Pass 1)
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    continue
  fi

  # Check against protected patterns
  if [[ "$branch" =~ ^(master|main|develop)$ ]] || [ "$branch" == "$TARGET_BRANCH" ]; then
    continue
  fi

  branches_to_review+=("$branch")
done


if [ ${#branches_to_review[@]} -eq 0 ]; then
  echo "No remaining branches to review."
else
  # If in interactive mode, loop and ask. Otherwise, just report.
  if [ "$INTERACTIVE_MODE" = true ]; then
    echo "The following branches will be reviewed interactively: ${branches_to_review[*]}"
    for branch in "${branches_to_review[@]}"; do
      while true; do # Loop indefinitely until a decision (Remove/Keep) is made.
        read -p $'Branch \e[33m'"$branch"$'\e[0m: [R]emove, [K]eep, or [V]iew diff? ' -n 1 -r choice
        echo # Move to a new line

        case "$choice" in
          r|R)
            echo -e " -> \e[31mDeleting\e[0m branch '$branch'."
            git branch -D "$branch"
            break # Exit the loop for this branch and move to the next.
            ;;
          k|K)
            echo -e " -> \e[32mKeeping\e[0m branch '$branch'."
            break # Exit the loop for this branch and move to the next.
            ;;
          v|V)
            echo " -> Showing diff for '$branch' from its divergence point..."
            MERGE_BASE=$(git merge-base "$TARGET_BRANCH" "$branch")
            git diff --patch-with-stat --color=always "$MERGE_BASE..$branch" | less -R
            ;;
          *)
            echo "Invalid choice. Please enter 'R', 'K', or 'V'."
            ;;
        esac
      done
    done
  else
    echo "The following branches were not automatically removable:"
    printf " - %s\n" "${branches_to_review[@]}"
    echo
    echo "To review them one by one, run this script again with the -i or --interactive flag."
  fi
fi

# --- 6. Finish ---
echo
echo "--- Cleanup complete ---"
echo "Returning to the original branch '$CURRENT_BRANCH'..."
if git show-ref --verify --quiet "refs/heads/$CURRENT_BRANCH"; then
  git checkout -q "$CURRENT_BRANCH"
else
  echo "Warning: Original branch '$CURRENT_BRANCH' was deleted. Cannot switch back."
fi

echo "Done."