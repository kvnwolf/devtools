#!/bin/bash
# PostToolUse hook: runs biome lint --write on edited files.
# Uses JSON reporter and extracts only diagnostics to reduce noise.

[ ! -f "biome.jsonc" ] && exit 0

file_path=$(jq -r '.tool_input.file_path // empty')

if [[ "$file_path" =~ \.(js|jsx|ts|tsx|json|jsonc|css|graphql|gql)$ ]]; then
  output=$(bun biome check --write --reporter=json "$file_path" 2>&1)
  rc=$?

  if [ $rc -ne 0 ]; then
    message=$(echo "$output" | jq -r '
      [.diagnostics[] |
        select(.severity == "error" or .severity == "warning") |
        "  line \(.location.start.line // "?"): \(.category) - \(.message)"
      ] | if length > 0 then "lint issues:\n" + join("\n") else empty end
    ' 2>/dev/null)

    # Fallback: if JSON parsing produced nothing, show raw output (stripped of ANSI)
    if [ -z "$message" ]; then
      message=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
    fi

    echo -e "$message" >&2
    exit 2
  fi
fi
