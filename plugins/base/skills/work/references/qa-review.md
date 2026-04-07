# QA Review

Run after ALL tasks complete. CRITICAL: complete ALL test cases before launching ANY fix agents. Never investigate or fix issues mid-QA.

## Flow

1. Build a list of test cases from the plan's user flow, goals, and edge cases
2. Present test cases **one at a time** using AskUserQuestion (NEVER as plain text):
   - header: `"QA N/M"`
   - question: reproduction steps + expected result in a single paragraph (user's language)
   - options:
     1. label: "Pass", description: "\<what success looks like\>"
     2. label: "Fail", description: "Something doesn't work as expected"
     3. label: "Skip", description: "Can't test this right now"
     4. label: "Chat about this", description: ""
   - If "Chat about this" → discuss freely, then re-present the same test case
3. After each response, move to the next test case. Repeat until all reviewed.
4. Present a summary table of all results (pass/fail/skip with details)
5. If any failures, ask the user if they want to fix them
6. If yes, spawn fix teammates — one per gap or group of related gaps. Use the same scheme: team membership, Agent tool without `isolation` or `subagent_type`, no commits. Include in the prompt what failed and what the expected behavior should be.
7. After fixes complete, offer to re-run only the failed test cases (same one-at-a-time flow)
