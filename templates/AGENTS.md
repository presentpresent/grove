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
change, **stop and report it**. Do not change it and carry on. Other sessions
are implementing against the same contract, and a silent change breaks them in
ways that surface much later.

Whoever owns the plan updates PLAN.md, and every session picks the change up
from there.

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
