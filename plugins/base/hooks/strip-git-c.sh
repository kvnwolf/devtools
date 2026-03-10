#!/usr/bin/env bash
# PreToolUse hook: strips `git -C <path>` → `git` so commands run in the current directory.
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')

if [[ "$command" =~ ^git[[:space:]]+-C[[:space:]] ]]; then
  new_command=$(echo "$command" | sed -E 's/^(git)\s+-C\s+("[^"]*"|\S+)\s*/\1 /')
  echo "$input" | jq --arg cmd "$new_command" '{tool_input: (.tool_input | .command = $cmd)}'
fi
