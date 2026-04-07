#!/bin/bash
# PostToolUse hook: runs vitest related on edited files.
# Uses JSON reporter and extracts only failed test names to reduce noise.

[ ! -f "vitest.config.ts" ] && exit 0

file_path=$(jq -r '.tool_input.file_path // empty')

if [[ "$file_path" =~ \.(ts|tsx)$ ]]; then
  # Resolve source file for coverage (strip .test. or .browser.test. keeping extension)
  if [[ "$file_path" =~ \.(browser\.)?test\.(ts|tsx)$ ]]; then
    source_file=$(echo "$file_path" | sed -E 's/\.(browser\.)?test\.(ts|tsx)$/.\2/')
  else
    source_file="$file_path"
  fi

  output=$(bun vitest related "$file_path" --run \
    --reporter=json \
    --coverage --coverage.reporter=json --coverage.include="$source_file" \
    2>&1)
  rc=$?

  if [ $rc -ne 0 ]; then
    # vitest may emit non-JSON lines before the JSON blob — extract last valid JSON object
    json=$(echo "$output" | sed -n '/^{/,/^}$/p' | tail -1)
    message=""
    if [ -n "$json" ]; then
      message=$(echo "$json" | jq -r '
        if .numFailedTests == 0 then empty
        else
          [.testResults[].assertionResults[] |
            select(.status == "failed") |
            .failureMessages[0] as $reason |
            "  \(.fullName) - \($reason | split("\n")[0] // "unknown failure")"
          ] | if length > 0 then "test failures:\n" + join("\n") else empty end
        end
      ' 2>/dev/null)
    fi

    # Fallback: if JSON parsing produced nothing, show raw output (stripped of ANSI)
    if [ -z "$message" ]; then
      message=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
    fi

    echo -e "$message" >&2
    exit 2
  fi
fi
