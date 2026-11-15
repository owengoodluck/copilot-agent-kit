# AGENTS.md

The single source of truth for this repository. Read this before doing anything.
Do not substitute general knowledge for what is written here.

> **How to fill it in.** Draft the mechanical parts with the prompt in `README.md`, then write
> **Architecture invariants** and **Forbidden actions** yourself — no tool can infer them.
> Run every command once before keeping it. Two pages max; push detail into `docs/`.
> **Scope.** Only what is true everywhere. A rule for one path belongs in
> `.github/instructions/NAME.instructions.md` with an `applyTo` glob, not here.

## What this is

[One sentence: the problem this repo solves, who uses it]

- Stack: [language + runtime version] / [framework + version] / [package manager]
- Shape: [single package / monorepo with N packages]

## Commands

```bash
[install dependencies]

[build]

[test]              # full suite
[test one file]     # while iterating on one module

[lint]
```

Only commands you have actually run. If one needs a service, a database or an env var, say so
on the same line.

## Directory map

| Path | What belongs here | Canonical example |
| --- | --- | --- |
| `src/...` | ... | `src/.../file.ext` |

New code goes where this table says. If nothing fits, ask before creating a directory.

## Architecture invariants

[Who may call whom, written so a linter could check it.
 Good: "dependencies only flow api -> service -> repo, never back".
 Bad: "keep the code clean".]

1. [...]
2. [...]

## Forbidden actions

- Never edit: [generated directories, lockfiles, vendored code, migrations already applied]
- Never weaken or delete a test to make a check pass.
- Never add a dependency without asking first.
- Never refactor or reformat outside the requested scope.
- Never commit secrets, credentials or large binaries.
- If structure, dependency direction or commands change, **update this file in the same diff**.
  That line is the only reason this file does not rot.
