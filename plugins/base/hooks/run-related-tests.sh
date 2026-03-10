#!/bin/bash
# PostToolUse hook: runs vitest related on edited files.

[ ! -f "vitest.config.ts" ] && exit 0

file_path=$(jq -r '.tool_input.file_path // empty')

if [[ "$file_path" =~ \.(ts|tsx)$ ]]; then
  bun vitest related "$file_path" --run --coverage || exit 2
fi
