# Round <N>: corrections

The previous round was reviewed. Apply only these corrections; keep every other change as is.
All rules from the original brief still apply (no git writes, no secrets, no DB writes, stay in
scope).

## Issues

1. `<path:line>` — <what is wrong> → <exact expected behavior or change>
2. <...>

## Verification

```bash
<commands to re-run>
```

Your final message MUST end with the same `## HANDOFF` section as before, describing the state
after this round, and nothing after it:

## HANDOFF
- Status: done | partial | blocked
- Files changed: one line per file, `path` — what changed in this round
- Verification: one line per command, `command` → pass | fail (first failing line if fail)
- Deviations from the brief: <every change no step required, including reformatting of untouched lines and deleted comments; or "none" only if literally true>
- Open questions / risks: <list, or "none">
