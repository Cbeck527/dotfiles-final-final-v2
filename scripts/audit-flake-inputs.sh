#!/usr/bin/env bash
# Compare flake.lock revisions between last commit and working tree.
# For each GitHub input with a changed rev, prints a compare URL.
#
# Usage: scripts/audit-flake-inputs.sh
#        make audit

set -euo pipefail

if ! git diff --quiet HEAD -- flake.lock 2>/dev/null; then
  old_lock=$(git show HEAD:flake.lock)
else
  echo "flake.lock has no uncommitted changes -- nothing to audit."
  exit 0
fi

new_lock=$(cat flake.lock)

# Collect all input names from both old and new locks
inputs=$(echo "$old_lock" "$new_lock" \
  | jq -r '.nodes | to_entries[] | select(.value.locked?) | .key' \
  | sort -u)

changed=0

for input in $inputs; do
  old_rev=$(echo "$old_lock" | jq -r ".nodes.\"$input\".locked.rev // empty")
  new_rev=$(echo "$new_lock" | jq -r ".nodes.\"$input\".locked.rev // empty")

  # Skip if either side is missing (new or removed input)
  if [[ -z "$old_rev" ]]; then
    echo "$input: new input (no previous rev to compare)"
    changed=1
    continue
  fi
  if [[ -z "$new_rev" ]]; then
    echo "$input: removed"
    changed=1
    continue
  fi

  # Skip unchanged
  [[ "$old_rev" == "$new_rev" ]] && continue

  changed=1

  old_short=${old_rev:0:8}
  new_short=${new_rev:0:8}

  # Build a GitHub compare URL if the input is github-type
  type=$(echo "$new_lock" | jq -r ".nodes.\"$input\".locked.type // empty")
  if [[ "$type" == "github" ]]; then
    owner=$(echo "$new_lock" | jq -r ".nodes.\"$input\".locked.owner")
    repo=$(echo "$new_lock" | jq -r ".nodes.\"$input\".locked.repo")
    echo "$input: $old_short..$new_short"
    echo "  https://github.com/$owner/$repo/compare/$old_rev...$new_rev"
  else
    echo "$input: $old_short..$new_short (non-GitHub, no compare URL)"
  fi
done

if [[ $changed -eq 0 ]]; then
  echo "All input revisions are unchanged."
fi
