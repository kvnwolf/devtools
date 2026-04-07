#!/bin/bash
# PostToolUse hook: runs playwright test on edited e2e files.

[ ! -f "playwright.config.ts" ] && exit 0

file_path=$(jq -r '.tool_input.file_path // empty')

if [[ "$file_path" =~ /e2e/ ]]; then
  bun playwright test "$file_path" || exit 2
fi
