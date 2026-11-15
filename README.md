# Agent Kit

One file of facts about your repo, plus four prompts. Works with Copilot, Claude Code, Cursor,
Codex and anything else that reads `AGENTS.md`. No scripts, no install step, nothing to run.

> Chinese reference: [`zh/`](zh/). English is the canonical version.

## What you get

An agent that stops inventing directories, stops guessing test commands, and stops quietly editing
files you told it not to touch. That is the whole claim. It will not design better.

## The pieces

```
templates/AGENTS.md   copy into your repo root as AGENTS.md — the only artifact
README.md             this file: how to fill it, four prompts, where enforcement lives
zh/                   Chinese reference translation
```

## Use it

1. **Copy** `templates/AGENTS.md` to your repo root.
   Already have one? **Merge, never replace.** Add the blocks that are missing, keep your wording,
   delete duplicate statements. An existing file may be loaded by other tools and may record
   decisions nobody wrote into the code.
2. **Draft the facts** with prompt 1 below, and paste the result in.
3. **Write two sections yourself**: architecture invariants and forbidden actions. Nothing can
   infer them, and a wrong invariant is worse than none — agents treat this file as authoritative.
4. **Run every command once** before keeping it. Candidate commands found in config files fail
   surprisingly often.
5. **Check it loaded.** Ask "what command runs the tests here?" and expand the answer's references
   to see whether `AGENTS.md` is listed. A file that exists is not a file that was read.

## Four prompts

Use them in order, in one conversation. Read-only planning and read-only review come from the
prompt, not from the tool, so they work everywhere.

**1 — Facts, read-only**

```
Read-only. Read package.json / Makefile / CI config / dependency manifests and the directory
layout. Report: stack and versions, package manager (warn if several lockfiles exist), candidate
commands for install, build, test, lint, generated or vendored directories, and a directory map
with one well-written example file per directory. If you cannot determine something, write
"none found". Never invent a command.
```

**2 — Plan, read-only**

```
Read-only. Read AGENTS.md first, then the code you would touch.
Requirement: <what to change, where, what counts as done, how to verify>.
Return the files to change and why, in order, plus the exact verification command. Every path you
cite must exist. If AGENTS.md is still a template, say so and mark the rest as inferred.
```

**3 — Implement**

```
Implement the plan above, nothing more. Follow AGENTS.md for placement and layering. Do not add
dependencies, do not touch tests to make them pass, do not reformat unrelated code. Run the
verification command from AGENTS.md and paste the output.
```

**4 — Review, read-only**

```
Read-only. Review the diff against AGENTS.md: out-of-scope edits, weakened or deleted tests,
layering violations, verification that was claimed but not run. List findings by severity with
file:line. No praise, no summary of what the diff does.
```

## Rules that must hold belong in a linter

Text is advice; a linter is a gate. Anything under `Architecture invariants` that can be checked
mechanically should also be checked mechanically:

| Language | Tool |
| --- | --- |
| JS / TS | dependency-cruiser: `no-circular`, `not-to-unresolvable`, custom layer rules |
| Python | import-linter |
| Java / Kotlin | ArchUnit |
| Go | `internal/` packages, enforced by the compiler |

If you use dependency-cruiser, do not put `node_modules` in `exclude` — it silently disables the
dependency rules. Use `doNotFollow` instead.

## Limits

- `AGENTS.md` is advisory. Models can ignore it; only CI makes a rule binding.
- Quality is capped by the two sections you write by hand.
- Plan and review run on the same model that wrote the code. Self-review bias survives.
- The file rots when commands change and it does not. Re-run prompt 1 then, and keep the
  "update this file in the same diff" rule.

## Where the rest went

The previous version — installer, scanner, three `.agent.md` profiles, lint config — is in git
history (`git log --oneline`). It earned its complexity only with many repos on macOS/Linux.
