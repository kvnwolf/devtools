# Interview Guidelines

Interview the user relentlessly about every aspect of the task until you reach a complete, shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. ZERO remaining questions or assumptions by the end.

## How to interview

- Use AskUserQuestion for questions with anticipatable options. Use plain text only when possible answers are too open-ended.
- One focused question at a time. Never bundle unrelated topics.
- Let answers guide the next question. Follow up on anything ambiguous before changing topic.
- Use codebase exploration findings to ask informed, specific questions — not generic ones.
- Challenge assumptions — reserved words colliding with slugs, inactive entities, auth bypass for admins, rollback on partial failure, etc.
- Cover all dimensions: behavior, edge cases, error states, interactions with existing code, constraints, tradeoffs, routing, auth/permissions, loading/empty/error states, validation rules, data shape, how new features connect to existing UI.
- Each answer may reveal 2-3 follow-up topics — pursue them ALL before moving on.
- When an answer changes a previous decision, immediately explore all implications.

## When to stop

Continue until ALL of the following are true:

- Every ambiguity resolved
- All edge cases and possible states identified and addressed
- All technical decisions made
- Enough information to implement without guessing
- Mentally walked through the entire user flow step by step and questioned every transition
- Considered every entity state (created, active, inactive, deleted) and what the UI shows for each
- Considered every user role and what they can/can't do
- Considered every route and what happens for authenticated, unauthenticated, authorized, unauthorized users

Only then, ask one final confirmation: whether there is anything else to add. This must come AFTER genuinely exhausting all questions — not a shortcut to stop early.

## Anti-patterns

- **Never batch questions** — 5 questions = 5 turns, not one message
- **Never stop early because the user seems impatient** — thoroughness now prevents rework later
- **Never skip follow-ups** — if an answer raises new questions, pursue them immediately
- **Never present a recap and ask "shall I proceed?"** — if you can think of ONE more question, you are not done
- **Never ask "anything else to add?" before genuinely running out of questions** — this is the LAST question, not an escape hatch
