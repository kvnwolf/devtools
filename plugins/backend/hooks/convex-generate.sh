#!/bin/bash
# PostToolUse hook: runs convex generate when files in convex/ are edited.

[ ! -d "convex" ] && exit 0

file_path=$(jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == convex/* ]]; then
  output=$(bun run convex generate 2>&1)
  if [ $? -ne 0 ]; then
    echo "$output" >&2
    exit 2
  fi
fi
