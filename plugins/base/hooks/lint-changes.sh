#!/bin/bash
# PostToolUse hook: runs biome lint --write on edited files.

[ ! -f "biome.jsonc" ] && exit 0

file_path=$(jq -r '.tool_input.file_path // empty')

if [[ "$file_path" =~ \.(js|jsx|ts|tsx|json|jsonc|css|graphql|gql)$ ]]; then
  bun run lint --write "$file_path" || exit 2
fi
