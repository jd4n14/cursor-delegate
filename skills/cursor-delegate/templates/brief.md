# Task: <short imperative title>

You are the executor of a task that was already planned. The decisions in this brief are closed:
you may make local design choices (helper extraction, naming, test structure) inside the files
listed under Scope, and nothing else. Do not reinterpret the scope, touch other files, or change
a product, data or architecture decision stated here.

Facts in this brief (counts, names, paths, expected values) are claims; verify one when it is
cheap. If the brief contradicts itself or the code, is impossible, or states a false fact:
<RISK_RULE: for critical risk (money, data repairs, migrations, auth, cross-repo contracts) use
"stop and report it in the handoff without implementing the affected part"; otherwise use
"take the narrower reading, continue, and report it under Deviations">.

## Context

- Repository: `<path>` (<stack>). Read `CLAUDE.md` and `AGENTS.md` at the repo root first and
  follow their conventions.
- Background: <why this change exists, 2-5 sentences, including the ticket id if any>
- Relevant files:
  - `<path>` — <what it does and why it matters here>
- Existing patterns to copy: `<path:line>` — <what to mimic>

## Goal

<one paragraph describing the end state>

## Steps

1. <concrete step: file, function, what to change>
2. <...>

## Scope

- You may modify: `<paths or globs>`
- You may create: `<paths>`
- Do not touch: anything else. If you believe another file must change, stop and report it.

## Acceptance criteria

- [ ] <observable behavior or test that must pass>
- [ ] <...>

## Verification

Run these from the repo root, in order. Fix failures caused by your change; report failures that
already existed before your change without fixing them.

```bash
<npm run lint>
<npm run typecheck>
<npm test -- path/to/affected.test.ts>
```

## Rules

- Never run `git commit`, `git push`, `git checkout`, `git switch`, `git reset`, `git stash`,
  `git rebase` or `git clean`. Leave all changes uncommitted in the working tree.
- Never read, print or edit `.env*` files or any secret. Never print connection strings.
- Never write to any database and never run migrations. Read-only queries only when this brief
  explicitly allows it.
- Never call production services or external APIs that change state.
- Do not install, upgrade or remove dependencies unless a step above says so.
- Match the surrounding code: naming, comment density, language (TS vs JS). No decorative
  comment banners, no abbreviations in new identifiers (`queries`, not `q`).
- Write all code, comments and test names in English.

## Handoff

Your final message MUST end with this section, filled in, and nothing after it:

## HANDOFF
- Status: done | partial | blocked
- Files changed: one line per file, `path` — what changed
- Verification: one line per command, `command` → pass | fail (first failing line if fail)
- Deviations from the brief: <every change no step required, including reformatting of untouched lines and deleted comments; or "none" only if literally true>
- Open questions / risks: <list, or "none">
