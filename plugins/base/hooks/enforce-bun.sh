#!/usr/bin/env bash
# PreToolUse hook: replaces npm/npx with bun/bunx in commands.
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')

if [[ "$command" =~ ^npm[[:space:]] ]]; then
  new_command=$(echo "$command" | sed -E 's/^npm /bun /')
  jq -n --arg cmd "$new_command" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: {
        command: $cmd
      }
    }
  }'
elif [[ "$command" =~ ^npx[[:space:]] ]]; then
  new_command=$(echo "$command" | sed -E 's/^npx /bunx /')
  jq -n --arg cmd "$new_command" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: {
        command: $cmd
      }
    }
  }'
fi
