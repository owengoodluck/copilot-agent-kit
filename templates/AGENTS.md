# AGENTS.md

The single source of truth for this repository. Every agent reads this before doing anything.
Do not substitute general knowledge for what is written here.

> **How to fill this in**: run `bash scan.sh <this-repo>` first to get the mechanical facts
> (stack, command candidates, forbidden paths, directory map) and paste them in. Then write two
> sections by hand — architecture invariants and forbidden actions. Every candidate command must
> be executed once before you keep it.
> **Two pages max.** If it grows past that, move detail into `docs/architecture.md` and leave a
> one-line pointer here.
> **Scope check.** Keep this file to what is true everywhere. A rule that is false outside one path
> (a migrations directory, tests, one package) belongs in `.github/instructions/NAME.instructions.md`
> with an `applyTo` glob. `applyTo: "**"` does not count — that is a second fact layer.

## What this is

[One sentence: what problem this repo solves, who uses it]

- Stack: [language and runtime version] / [framework and version] / [package manager]
- Shape: [single package / monorepo with N packages]

## Commands

```bash
[install dependencies]

[build]

[test]                # full suite
[test single file]    # when iterating on one module

[lint]

[typecheck]           # write "none" if there is no such step
```

Prerequisites: [env vars, local services, private registry, pinned runtime version]

## Directory map

| Directory | What lives here | Copy the pattern from |
|---|---|---|
| `[src/api]` | [HTTP entry points] | `[src/api/xxx.ts]` |
| `[src/service]` | [business logic] | `[src/service/xxx.ts]` |
| `[src/repo]` | [data access] | `[src/repo/xxx.ts]` |
| `[test]` | [tests] | `[test/xxx.spec.ts]` |

## Architecture invariants

Violations get the change rejected, and each rule must be expressible as tooling — if a lint rule
cannot express it, it is not an invariant, it is a preference.

1. [Dependencies flow api → service → repo only, never backwards]
2. [All outbound HTTP goes through `src/infra/http/`; the business layer never calls out directly]
3. [Schema changes go through migration scripts; never edit the database by hand]

## Forbidden actions

- Do not modify: [generated dirs], [build output], lockfiles, `.github/workflows/`, [vendor]
- Do not add dependencies unless the delivery notes explain why existing ones are insufficient
- Do not change tests to make them pass: no deleted assertions, no ignore comments, no relaxed lint
- Do not refactor or reformat anything outside the requested scope
- Do not write credentials or real personal data into code, fixtures, or logs
- Architectural changes (new layer, new top-level directory, changed dependency direction) require
  a human decision first — stop and ask

## Key decisions

Things that are invisible in the code and easy for a newcomer to undo. Three to five bullets is
enough; more than that and nobody reads it.

- [Why A instead of B, and when that decision stops being valid]
- [This layer looks redundant but exists because of X — do not collapse it]
- [Known inconsistency: this one place is written differently on purpose]

## Agent roles in this repo

One owner per role. The picker is a flat list of names, so two agents that both "plan" means the
choice is random and the same task behaves differently depending on who picked.

| Role | File | Status |
|---|---|---|
| plan | `.github/agents/planner.agent.md` | active |
| implement | `.github/agents/implementer.agent.md` | active |
| review | `.github/agents/reviewer.agent.md` | active |
| [other — e.g. a team-owned `architect`] | [path] | [keep for X / retired] |

If anything here overlaps with these three, write down **which one owns what**. An unrecorded
overlap gets resolved differently by every person who runs into it.

## Working discipline

1. **Think before writing.** List your assumptions and open questions first; a wrong assumption
   costs far more than one extra question.
2. **Simplest thing that works.** Build only what the task needs. No speculative abstractions,
   config flags, or extension points.
3. **Touch only what you must.** No drive-by refactors, no import reordering, no formatting of
   files you did not otherwise need to change.
4. **Drive to the target.** Decide what "done" means before you start, then loop until the
   verification commands pass — not until you run out of code to write.

## Definition of done

- [ ] Every acceptance criterion is met
- [ ] Tests, lint, and typecheck actually ran and passed (paste the output in the delivery notes;
      "it passes" is not evidence)
- [ ] The diff stays inside the modules the task named
- [ ] If directory structure, dependency direction, public interfaces, or commands changed,
      **this file was updated in the same diff**

That last item is the only reason this file does not rot: **updating the doc is part of the change,
not a follow-up task.**
