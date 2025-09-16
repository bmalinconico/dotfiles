#!/usr/bin/env bash
set -euo pipefail

# --- 1. Documentation & Help ---
print_help() {
cat << EOF
A tool for cleaning and maintaining local git branches.

USAGE:
  ./git-clean-branches.sh [options] [target_branch]

DESCRIPTION:
  This script finds local branches that have been merged into a target branch
  (e.g., main or master) and helps you clean them up. It operates in one of
  three modes.

MODES:
  Report (default)
    Automatically deletes fully merged branches, then prints a list of all
    remaining branches that could not be safely removed.

  Interactive (-i, --interactive)
    After auto-deleting merged branches, this mode prompts you to decide the
    fate of each remaining branch with the following options:
      [R]emove:        Force-delete the branch.
      [K]eep:          Do nothing and keep the branch.
      [V]iew patches:  Show the changes for each unique commit on the branch (uses 'git log -p').
      [S]ummary diff:  Show a single collapsed diff between the branch tip and target tip (uses 'git diff').
      [G]raph log:     Show a graph of the unique commits on the branch (uses 'git log --graph').

  Update (--update)
    After auto-deleting merged branches, this mode attempts to automatically
    rebase each remaining branch on top of the target branch. It will only
    succeed if the rebase is clean (no conflicts).

OPTIONS:
  [target_branch]       Optional. The branch to compare against. If omitted, the
                        script will try to auto-detect 'main' or 'master'.
  -i, --interactive     Enables Interactive Mode. Cannot be used with --update.
  --update              Enables Update Mode. Cannot be used with -i.
  -h, --help            Prints this help message and exits.

EOF
}

# --- 2. Argument Parsing ---
INTERACTIVE_MODE=false
UPDATE_MODE=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_help
      exit 0
      ;;
    -i|--interactive)
      INTERACTIVE_MODE=true
      shift # past argument
      ;;
    --update)
      UPDATE_MODE=true
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

# Validate flags
if [ "$INTERACTIVE_MODE" = true ] && [ "$UPDATE_MODE" = true ]; then
  echo "Error: --interactive (-i) and --update flags cannot be used together." >&2
  print_help
  exit 1
fi


# --- 3. Setup ---
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

# --- 4. Update & Prune ---
echo "Fetching latest changes and pruning stale remote-tracking branches..."
git fetch --prune origin
echo "Updating local target branch '$TARGET_BRANCH' to match its remote..."
git reset --hard "origin/$TARGET_BRANCH"

# --- 5. Automatic Cleanup of Fully Merged Branches ---
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

# --- 6. Process Remaining Branches (Report, Interactive, or Update) ---
echo
echo "--- Pass 2: Processing remaining branches ---"

# Collect all branches that were not deleted in Pass 1
all_branches=()
while IFS= read -r b; do all_branches+=("$b"); done < <(git for-each-ref refs/heads/ "--format=%(refname:short)")

branches_to_process=()
for branch in "${all_branches[@]}"; do
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then continue; fi # Skip if already deleted
  if [[ "$branch" =~ ^(master|main|develop)$ ]] || [ "$branch" == "$TARGET_BRANCH" ]; then continue; fi # Skip protected
  branches_to_process+=("$branch")
done


if [ ${#branches_to_process[@]} -eq 0 ]; then
  echo "No remaining branches to process."
else
  # --- UPDATE MODE --- 
  if [ "$UPDATE_MODE" = true ]; then
    echo "Attempting to cleanly rebase branches onto '$TARGET_BRANCH'..."
    for branch in "${branches_to_process[@]}"; do
      echo -n " - Processing branch '$branch': "

      set +e # Temporarily disable exit on error to catch rebase failure
      REBASE_OUTPUT=$(git checkout -q "$branch" 2>&1 && git rebase "$TARGET_BRANCH" 2>&1)
      REBASE_EXIT_CODE=$?
      set -e # Re-enable

      if [ $REBASE_EXIT_CODE -eq 0 ]; then
        echo -e "\e[32mSuccess\e[0m"
      else
        echo -e "\e[33mFailed (conflicts)\e[0m"
        git rebase --abort >/dev/null 2>&1
      fi
      git checkout -q "$TARGET_BRANCH" # Ensure we are back on target for the next loop
    done
  # --- INTERACTIVE MODE --- 
  elif [ "$INTERACTIVE_MODE" = true ]; then
    echo "The following branches will be reviewed interactively: ${branches_to_process[*]}"
    for branch in "${branches_to_process[@]}"; do
      while true; do
        # Use echo -e -n for a more portable colored prompt
        echo -e -n 'Branch \e[33m'"$branch"'\e[0m: [R]emove, [K]eep, [V]iew patches, [S]ummary diff, or [G]raph log? '
        read -n 1 -r choice
        echo
        case "$choice" in
          r|R) echo -e " -> \e[31mDeleting\e[0m branch '$branch'."; git branch -D "$branch"; break ;;
          k|K) echo -e " -> \e[32mKeeping\e[0m branch '$branch'."; break ;;
          v|V)
            echo " -> Showing patches for each commit on '$branch' ahead of '$TARGET_BRANCH'..."
            git log -p --color=always "$TARGET_BRANCH..$branch" | less -R || true
            ;;
          s|S)
            echo " -> Showing summary diff between tips of '$TARGET_BRANCH' and '$branch'..."
            git diff --patch-with-stat --color=always "$TARGET_BRANCH..$branch" | less -R || true
            ;;
          g|G)
            echo " -> Showing graph of commits on '$branch' ahead of '$TARGET_BRANCH'..."
            git log --graph --oneline --decorate --color=always "$TARGET_BRANCH..$branch" | less -R || true
            ;;
          *)
            echo "Invalid choice."
            ;;
        esac
      done
    done
  # --- REPORT MODE (DEFAULT) --- 
  else
    echo "The following branches were not automatically removable:"
    printf " - %s\n" "${branches_to_process[@]}"
    echo
    echo "To review them one by one, run this script again with the -i or --interactive flag."
    echo "To attempt to update them automatically, run with the --update flag."
  fi
fi

# --- 7. Finish ---
echo
echo "--- Cleanup complete ---"
echo "Returning to the original branch '$CURRENT_BRANCH'..."
if git show-ref --verify --quiet "refs/heads/$CURRENT_BRANCH"; then
  git checkout -q "$CURRENT_BRANCH"
else
  echo "Warning: Original branch '$CURRENT_BRANCH' was deleted. Cannot switch back."
fi

echo "Done."
