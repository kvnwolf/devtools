#!/usr/bin/env bash
# PreToolUse hook: replaces direct agent-browser with bunx and adds --headed to open.
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')
modified=false

# Replace all occurrences of bare agent-browser with bunx agent-browser@latest
if [[ "$command" =~ agent-browser ]] && [[ ! "$command" =~ bunx[[:space:]]agent-browser ]]; then
  command=$(echo "$command" | sed 's/^agent-browser /bunx agent-browser@latest /')
  command=$(echo "$command" | sed -E 's/(&&|[|][|]|;)([[:space:]]*)agent-browser /\1\2bunx agent-browser@latest /g')
  modified=true
fi

# Add --headed to open subcommand if missing
if [[ "$command" =~ agent-browser ]] && [[ "$command" =~ [[:space:]]open[[:space:]] ]] && [[ ! "$command" =~ --headed ]]; then
  command=$(echo "$command" | sed -E 's/([[:space:]]open[[:space:]])/\1--headed /')
  modified=true
fi

if [[ "$modified" == true ]]; then
  jq -n --arg cmd "$command" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: {
        command: $cmd
      }
    }
  }'
fi
