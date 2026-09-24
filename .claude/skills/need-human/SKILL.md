---
name: need-human
description: Ask the human for a decision or an action only they can take. Use when blocked by permissions or credentials, when a step is irreversible or costly, when there are several reasonable paths, or when a check fails the same way on every retry. Defines when to ask and the exact format of the ask.
---

# /need-human — ask well, ask once, then act on the answer

## When to ask, and when not to

| Situation | What to do |
| --- | --- |
| Reversible, cheap, one obvious path | Don't ask. Make the most reasonable assumption, state it in one line, and proceed. |
| Irreversible, costs money, touches production or the public record (merge, publish, pushing personal media to a public repo) | Ask first. |
| Two or more reasonable paths with different trade-offs | Ask with a triage table. Do not pick for the user. |
| A blocker that gives the same result on every retry (auth 403, missing repo authorization, OS permission prompt) | Stop after one confirming retry and ask. Do not loop. |
| A capability is missing (no TTS, no speech recognition, a network host is blocked) | Say so plainly, do the part you can, and offer the alternatives in a triage table. |

Before asking, do everything that does not depend on the answer: prepare the branch or commit, package the files, draft the text. The human's action should be the last missing piece.

## Format of the ask

Reply in the user's language (Chinese by default for this maintainer). Structure:

1. **One sentence:** what is blocked and why, with the concrete cause (for example "push returns 403: the repo is not in this session's authorized set").
2. **What is safe:** where the work is right now (for example "commit `91efae1` is on the local branch; the full patch is attached").
3. **Risks the user should know first**, if any (for example "the voice recording becomes public and stays in git history").
4. **Triage table**, ordered by urgency:

| # | Item | Urgency | Who can do it (me / you) | Cost and risk | Recommendation |
|---|---|---|---|---|---|
| 1 | … | High | You authorize, I execute | … | ✅ Recommended |

   - Mark items that only the human can do, and give the exact entry point: a URL, a prefilled link, or a settings location. Say plainly when a UI location is not verified.
   - Options may be combined (for example "1+4").
5. **Closing line:** `Reply with the numbers.`

When there is only one sensible next step, skip the table and state it in one sentence.

## After the answer

- Do only the selected items. Treat unselected items as declined.
- If the user says an action is done, verify it before continuing: retry the push, list the PR, or read the file. Do not assume it worked.
- If it still fails, report the exact new evidence and why (for example "session sources are fixed when the session starts; installing the app does not change this session"). Then give the smallest next step, such as a prefilled new-session link. Don't repeat the whole table.
- Automated reminders (stop hooks, "unpushed commits") do not count as new information. Retry once to confirm, then answer briefly with the same blocker. Don't escalate or rebuild the plan.

## Anti-patterns

- Burying the decision in a paragraph, or asking several questions at once without numbering.
- Asking before doing the preparatory work you could have done.
- Guessing UI paths and presenting them as fact.
- Working around a denied permission through another channel the user did not approve.
- Asking the user for tokens, OAuth codes, or secrets.
