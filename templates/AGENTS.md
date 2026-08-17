# Working in this worktree

This directory holds one task spread across several repos. Each repo lives in
its own subdirectory and they are all on the same branch.

## Read PLAN.md first

`PLAN.md` at the root of this worktree is the contract between the repos. It
says what is being built and, when more than one repo is involved, the exact
interfaces, schemas and field names that cross between them.

Read it before touching anything.

## Stay in your repo

If you were started for one repo, edit only that repo's directory. The other
repo directories are there so you can read them — never write to them.

## The contract is not yours to change

If you conclude that an interface, schema or field name in PLAN.md has to
change, **stop and raise it**. Do not change it and carry on. Other sessions
are implementing against the same contract, and a silent change breaks them in
ways that surface much later.

```bash
grove ask "need paidAt — OrderResponse.kt:42, not in the contract. May I add it?"
```

That records the question in `QUESTIONS.md` and notifies the planning session.
Use it whenever you are blocked or need a decision, not only for contract
changes — a question sitting unread in your own pane blocks the whole task.

**Keep it to one line, and cite file:line instead of explaining.** The planning
session can read this worktree's code itself, so a question is a pointer, not a
payload. Every line you send is a line of someone else's context.

## If you are the planning session

Questions arrive as `[ask/<repo>] …` with a path. Handle them like this:

1. Read `QUESTIONS.md` — other questions may have arrived without a separate
   notification (repeat notifications are suppressed for a short window).
2. Decide the answer.
3. **Changes the contract** → edit the contract section of PLAN.md. Every repo
   session is notified automatically with the diff.
4. **Does not change the contract** → `grove tell <task> --to <repo> "answer"`
   so the other sessions are not woken.

Write decisions into PLAN.md as you go, then let them leave your context. The
plan lives on disk, not in your history — `/grove-resume` rebuilds it. Rereading
one file costs less than carrying every exchange.

## Verify your own work

After implementing, find the verification this repo already has — tests, a
build, a typecheck, a linter — run it, and report what it said. "It should
work" is not a result.

## Record decisions, not narration

`PLAN.md` has a decision log. Add a line when you choose between real
alternatives, especially when the reason will not be obvious from the diff.
Don't log what the diff already shows.

## Finishing

`MERGE_REQUESTS.md` collects the PR links for this task, one per repo.
`grove rm <name>` archives PLAN.md and MERGE_REQUESTS.md, removes the
worktrees, and deletes the branches that were merged.
