# cursor-delegate

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that hands implementation to
[Cursor Agent](https://docs.cursor.com/en/cli/overview) running Grok 4.7 in headless mode, while
Claude only plans, reviews and verifies. Claude tokens go to judgment (what to change, whether it
is correct); Cursor tokens go to typing (reading code, editing, running commands, iterating on
failures).

## How it works

1. **Plan.** Claude closes every decision and writes a self-contained brief from
   `templates/brief.md`: goal, steps, allowed files, acceptance criteria, verification commands,
   rules, and a required `## HANDOFF` section.
2. **Dispatch.** `scripts/run-cursor.sh` runs one `cursor-agent` round and stores the raw result,
   the handoff, stderr, the session id and the base commit next to the brief in
   `<repo>/.ai/cursor/<slug>/` (git-excluded automatically).
3. **Review.** Claude checks the handoff and its deviations, compares changed files with the
   allowed list, reads the logic hunks, and re-runs the verification commands itself. A
   self-reported pass from the executor never counts.
4. **Fix rounds.** Issues go into `templates/fix-round.md` with `path:line` and the expected
   result, and the same Cursor session is resumed. After 3 rounds without converging, Claude stops
   and reports.
5. **Close.** Cursor never commits. Claude commits only when the user asks.

## Requirements

- Claude Code
- `cursor-agent` CLI, signed in, with access to the `grok-4.7-*` models
- `jq`

## Installation

```bash
git clone https://github.com/jd4n14/cursor-delegate.git
mkdir -p ~/.claude/skills
cp -R cursor-delegate/skills/cursor-delegate ~/.claude/skills/
```

Then ask Claude Code to "hand this to Cursor" or run `/cursor-delegate`.

## Safety

The runner passes `--force --trust`, so Cursor runs shell commands without asking. The Rules
section of the brief (no git writes, no secrets, no database writes, no production calls) is the
only guardrail: keep it verbatim, and never put credentials in a brief.

## With orchestrated-development

In the [orchestrated-development](https://github.com/jd4n14/orchestrated-development) workflow,
a phase file is most of a brief. This skill can replace `implementation-agent` as the executor;
`contract-checker` and `review-agent` still run after it.

## License

MIT
