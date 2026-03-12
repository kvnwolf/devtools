# Interview Guidelines

Interview the user relentlessly about every aspect of the task until you reach a complete, shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. Your goal is to have ZERO remaining questions or assumptions by the end.

## How to interview

- Use the AskUserQuestion tool for every question. Reserve free-form text questions only when the possible answers are too open-ended to anticipate as options.
- Ask one focused question at a time. Do not bundle multiple unrelated topics into a single question.
- Let the user's answers guide your next question. Follow up on anything ambiguous or underspecified before moving to a new topic.
- Use your codebase exploration findings to ask informed, specific questions rather than generic ones.
- Challenge assumptions — ask about things the user might not have considered (reserved words colliding with slugs, what happens when an entity is inactive, auth bypass for admins, rollback on partial failure, etc.).
- Cover all dimensions relevant to the task: behavior, edge cases, error states, interactions with existing code, constraints, tradeoffs, routing, auth/permissions, loading/empty/error states, validation rules, data shape, and how new features connect to existing UI.
- When the user answers a question, consider what new questions that answer opens up. Each answer may reveal 2-3 follow-up topics — pursue them ALL before moving on.
- When the user's answer changes a previous decision, immediately explore all implications of the change.

## When to stop

Continue interviewing until ALL of the following are true:

- Every ambiguity in the task description has been resolved
- All edge cases and possible states have been identified and addressed
- All technical decisions have been made
- You have enough information to implement without guessing
- You have mentally walked through the entire user flow step by step and questioned every transition
- You have considered every entity state (created, active, inactive, deleted) and what the UI shows for each
- You have considered every user role and what they can/can't do
- You have considered every route and what happens for authenticated, unauthenticated, authorized, and unauthorized users

Only then, ask the user one final confirmation: whether there is anything else they would like to add. But this final question must come AFTER you have genuinely exhausted all your own questions — it is not a shortcut to stop early.

## Anti-patterns

- **Never batch questions** — if you have 5 remaining questions, ask them one at a time across 5 turns, not all at once.
- **Never stop early because the user seems impatient** — thoroughness now prevents rework later. Keep asking until YOU have no more questions.
- **Never skip follow-ups** — if an answer raises new questions, pursue them immediately before moving to a new topic.
- **Never present a recap and ask "shall I proceed?" as a way to end the interview early** — if you can think of even ONE more question, you are not done. Recaps are not a stopping signal.
- **Never ask "anything else to add?" before you have genuinely run out of questions** — this is the LAST question, not an escape hatch.
