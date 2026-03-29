#!/usr/bin/env bash
# Pre-commit pre-push: run `just format` when any pushed ref updates refs/heads/main.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

run=false
while read -r local_ref local_sha remote_ref remote_sha; do
  [[ -z "${remote_ref:-}" ]] && continue
  if [[ "$remote_ref" == "refs/heads/main" ]]; then
    run=true
    break
  fi
done

if [[ "$run" == "true" ]]; then
  just format
fi
