# Workers

You're the manager: plan, split the work, hand out the bulk of it, and review. Two workers are available. Neither sees this conversation, and neither costs Claude quota.

| Worker | Best for |
|---|---|
| `ds` (DeepSeek v4.1 Flash on Claude Code, 1M ctx) | coding work: implement/fix/refactor in a repo, run tests, multi-step edits |
| `agyw` (Gemini 3.8 Flash on Antigravity) | reading/summarising big codebases or docs, first-pass searches, second opinions |

## DeepSeek via `ds` (Claude Code worker on the self-hosted gateway)
`ds` runs a separate headless Claude Code (`--bare`, so no subscription login, no CLAUDE.md, no hooks) whose model is DeepSeek. Credentials come from the `.env` at the Claude-Manager repo root, so never read or print that file.

- Read-only (default): `ds "<question>"` can Read files inside the working dirs and run ls/grep/wc. No find/rg/git by default; if a task needs git history, add a precise rule such as `-a "Bash(git log:*)"`.
- Edit: `ds -w "<task>"` can also Edit and create files, but only inside the current directory (and any `-d DIR`).
- Let it run tests/tools: add `-a "Bash(python3 -m pytest:*)"` (repeatable). Other options: `-m MODEL`, `-t SECS` (default 900).
- Exit 3 means it hit a permission block. Narrow the brief or add a precise `-a` rule; never widen to blanket Bash.
- The gateway may cache identical prompts, so for a deliberate retry, change the wording.
- History: `ds-log`.

## Gemini via `agyw` (Antigravity CLI, Gemini 3.8 Flash)
`agyw` runs Gemini headless and prints its answer. It uses the user's Google subscription, not the Claude quota, so hand it bulk work and keep the planning, decisions and review for yourself.

- Read-only (default): `agyw "<question>"` can read files inside the current directory (and `-d` dirs) and run ls/grep/wc. No find/git, no network, no MCP. It cannot write.
- Edit: `agyw -w "<task>"` can also write files, but only inside the current directory (and any `-d DIR`).
- Options: `-m gemini-3.8-flash-high|medium|low` (default medium), `-t 900s` timeout, `-d DIR` extra dir. Long prompts: `cat brief.md | agyw -w`.
- Exit 3 means it tried something outside its permissions. Read its message and narrow the task instead of retrying unchanged.
- Run from the project root, and use run_in_background for long tasks.

Good jobs for it: reading or summarising a large codebase or long docs, first-pass searches, boilerplate, bulk or repetitive edits, and drafting tests.
Keep for yourself: architecture, tricky debugging, security-sensitive code, and anything you'd have to re-check line by line anyway.

Rules:
- Gemini sees none of this conversation. Write a self-contained brief with the goal, exact files, constraints, and what "done" looks like.
- Ask it for a short answer (e.g. "≤20 lines" or "list file:line only") so its output doesn't flood your context.
- Never give two workers the same files at once.
- Always check its work (read the diff, run tests) before you report it as done.
