#!/bin/bash
# PostToolUse hook: runs incremental TypeScript type-checking after edits.

file_path=$(jq -r '.tool_input.file_path // empty')

[[ ! "$file_path" =~ \.(ts|tsx)$ ]] && exit 0
[ ! -f "tsconfig.json" ] && exit 0

output=$(bunx tsc --noEmit --incremental --tsBuildInfoFile .tsbuildinfo 2>&1)
if [ $? -ne 0 ]; then
  echo "$output" >&2
  exit 2
fi
