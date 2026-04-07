#!/bin/bash
# PostToolUse hook: runs incremental TypeScript type-checking after edits.
# Parses tsc output to show only compact error lines.

file_path=$(jq -r '.tool_input.file_path // empty')

[[ ! "$file_path" =~ \.(ts|tsx)$ ]] && exit 0
[ ! -f "tsconfig.json" ] && exit 0

output=$(bunx tsc --noEmit --incremental --tsBuildInfoFile .tsbuildinfo 2>&1)
rc=$?

if [ $rc -ne 0 ]; then
  # Extract only error lines in compact format: file(line): TScode - message
  message=$(echo "$output" | grep -oE '[^/\\( ]+\.[^(]+\([0-9]+,[0-9]+\): error TS[0-9]+: .+' \
    | sed -E 's/\(([0-9]+),[0-9]+\): error (TS[0-9]+): (.+)/(\1): \2 - \3/' \
    | sed 's/^/  /')

  if [ -n "$message" ]; then
    echo -e "typecheck errors:\n$message" >&2
  fi
  exit 2
fi
