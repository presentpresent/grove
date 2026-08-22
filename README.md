# grove

Plant several repos in one worktree, and give each its own AI session.

grove is for people who ship a single feature across several repositories at once — backend, BFF, mobile. It creates one worktree per repo under a shared working directory, keeps them all on the same branch, and tears the whole thing down when the work lands.

If you work in one repo, use `git worktree add` directly. grove earns its keep when there are several.

> Speaks English and Korean. Set `GROVE_LANG=ko` (or a `ko*` locale) for Korean. → [한국어 README](README.ko.md)

## Install

```bash
npm i -g @presentpresent/grove
grove init
```

`grove init` looks at how repos are laid out on this machine, reads your recent branch names, and proposes a config. Nothing is written until you confirm. To look before installing:

```bash
npx @presentpresent/grove init --dry-run
```

Pure bash — no runtime dependencies, and npm is only the delivery channel. Works on bash 3.2, so stock macOS is fine.

## Usage

```bash
grove new checkout-redesign notification-worker web-bff
```

Creates `~/Projects/worktrees/checkout-redesign/` with one worktree per repo, all on `feature/checkout-redesign`, plus a `PLAN.md` stub.

```bash
grove open checkout-redesign            # lay out panes, start the planning session
grove open checkout-redesign --exec     # start one AI session per repo
grove add checkout-redesign api-server # pull another repo in mid-flight
grove ls                        # what's currently open
grove rm checkout-redesign              # archive docs, remove worktrees, prune merged branches
```

| Command | What it does |
|---|---|
| `new` | Create worktrees and drop in a PLAN.md |
| `add` | Add a repo to existing work, inheriting its branch |
| `open` | Lay out the screen. `--exec` also starts per-repo AI sessions |
| `ls` | List active worktrees |
| `rm` | Archive → remove worktrees → delete merged branches |
| `export` | Generate a retrospective draft from finished work |
| `init` | Detect this machine's setup and write a config |
| `status` | One-screen summary: per-repo branch, commits, PR state, checklist progress |
| `tell` | Notify every repo session (or one, with `--to`) |
| `ask` | Raise a question from a repo session to the planning session |

## Knowing where things stand

```bash
grove status checkout-redesign
```

```
checkout-redesign — last touched 0 day(s) ago

REPO                     BRANCH                          AHEAD  DIRTY  PR
----------------------------------------------------------------------
api-server               feature/checkout-redesign          18     ·  #1539 merged
web-bff                  feature/checkout-redesign-p4       12     ·  #3245 merged
web-client               feature/checkout-redesign           5     3  #44 open

DOCS
  PLAN.md            43/82  (52%)  120 lines
  PITFALLS.md        538 lines

5 session(s) running
```

It counts, it does not judge. git comes first and the docs second, because the
code is the truth.

## PLAN.md is the contract

Per-repo AI sessions can't see each other. The `PLAN.md` at the worktree root is what they share: the planning session writes the contract there, and each repo session reads it and does its part. Change the plan mid-flight and every session picks it up from the same place.

`grove rm` moves that PLAN.md into an archive rather than deleting it, so months later you can still answer "why did we do it that way".

### Two channels, both automatic

The planning session and the repo sessions can't see each other's context, so
grove gives them two directions:

| | |
|---|---|
| `grove tell <task> [msg]` | plan → every repo session. `--to <repo>` for just one |
| `grove ask "<question>"` | repo → plan. Records it in `QUESTIONS.md` and notifies |

`hooks/plan-notify.sh` makes the first one automatic: edit the **contract
section** of PLAN.md and every repo session is sent the diff. Only that section
is watched — ticking a checklist should not wake five sessions.

### Split the docs before they get long

One file that mixes the living contract with accumulated history means hunting
for today's 40 lines inside several hundred. Once PLAN.md passes ~300 lines,
split it by how often each part changes:

| | |
|---|---|
| `PLAN.md` | contract, checklist, deploy order, what is still blocked — **read daily** |
| `DESIGN.md` | why these choices — written once |
| `PITFALLS.md` | traps, verification records, decision log — read when stuck |

Leave a one-line pointer where content moved out.

## Configuration

Everything lives in `~/.config/grove/config`, which `grove init` generates.

| Variable | Meaning |
|---|---|
| `GROVE_REPOS` | Where your repos are. **Colon-separated for several paths** (`~/Projects/repos:~/dev`) |
| `GROVE_ROOT` `GROVE_TREES` `GROVE_ARCHIVE` | Workspace layout |
| `GROVE_BRANCH` | Branch template. `{type}` and `{name}` are substituted |
| `GROVE_TYPE` `GROVE_TYPES` | Default work type and the allowed list |
| `GROVE_MUX` | Screen tool (herdr, …) |
| `GROVE_LANG` | `en`, `ko`, or `auto` (reads `LANG`; falls back to English) |
| `GROVE_CASEBOOK` | Where retrospectives go. Empty disables the feature |

The branch setting is a whole template rather than a prefix, so all of these fit:

```
{type}/ACME-{name}      → feature/ACME-checkout-redesign
{type}/{name}         → fix/cart-crash
alice/{name}          → alice/cart-crash
{name}-wip            → cart-crash-wip
```

Environment variables win over the config file, so a one-off override is just a prefix:

```bash
GROVE_REPOS=~/other grove ls
```

### What `grove init` infers

It reads recent remote branches across your repos and works out three things:

- whether branches carry a **type** prefix, and which vocabulary you use — a team on `feat/` is not forced onto `feature/`
- whether a **ticket key** (`ACME-`, `PROJ-`) shows up often enough to bake into the template
- which screen tool is installed

It deliberately does **not** ask GitHub for branch rules. Organization rulesets are invisible to a normal developer token — `rulesets`, `?includes_parents=true` and `rules/branches/<name>` all come back empty even when a rule is actively rejecting your pushes. Reading your own history is the more honest signal.

## AI skills

`grove init` installs two skills into `~/.claude/skills/`:

- `/grove-start` — identify the repos, agree on a name, `grove new`, draft the PLAN.md, `grove open`
- `/grove-resume` — come back to earlier work: restore what was done, what was blocked, and the screen layout

Both are written in Korean. The model reads them fine either way, but `grove init` asks before installing, so decline if you'd rather not have Korean prompts in your skills directory.

## Screen layout

`grove open`, `grove tell` and the notification half of `grove ask` drive
[herdr](https://github.com/herdrdev/herdr). Everything else — `new`, `add`,
`ls`, `rm`, `export`, `init` — is plain git and works with no herdr installed.

| | without herdr |
|---|---|
| `new` `add` `ls` `rm` `export` `init` | work normally |
| `ask` | records the question in QUESTIONS.md, skips the notification |
| `tell` `open` | fail with a clear message |

tmux and zellij are detected by `grove init` but cannot lay out panes; only
herdr can.

## Caveats

- A repo that has worktrees stores absolute paths in `.git/worktrees/*/gitdir`. **Moving the repo directory breaks them.**
- Worktree `node_modules` is symlinked to the origin repo. To change dependencies, `rm node_modules` first — otherwise you contaminate the original.
- Organization branch-name rules are enforced but unreadable through the API (see above). If a push is rejected and you can't find a rule, that's why.

## License

MIT
