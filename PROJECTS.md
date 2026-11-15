# Multi-project registry

> Lives next to `install.sh` on purpose: **the moment you most need it is the moment you are about to
> run the role-layer upgrade**, and you will be in this directory then. Put it in a notes app instead
> and it never gets updated again.

Add a row when you adopt a project. With one project this table looks pointless; from the third one
on you cannot work without it.

## 1. Adoption status

| Project | Path | Stack | Adopted | Fact layer updated | Status |
| --- | --- | --- | --- | --- | --- |
| e.g. blog-api | ~/code/blog-api | Node 20 + Fastify + Postgres | 2026-11-15 | 2026-11-15 | done |

Three statuses only — do not invent more:

- **done** — `scan.sh` run, both hand-written sections filled, References check passed
- **partial** — templates installed but `AGENTS.md` is still square brackets; agents are guessing
- **unverified** — installed but the References check was never done, so you do not know if it works

Kill **partial** and **unverified** quickly. They are worse than not installing: you believe you have
protection when you do not.

## 2. Recurring problems per project

The most valuable column in this table. If an agent repeats the same mistake in one project, the
constraint is missing — write it down, then turn it into one.

| Project | Recurring problem | Constraint added | Resolved |
| --- | --- | --- | --- |
| e.g. blog-api | New endpoints go into `routes/` instead of `api/v1/` | Placement table in AGENTS.md + `no-reverse-layer` rule | yes |

## 3. Role-layer version

Any edit to `templates/.github/agents/` gets a row here, otherwise you cannot tell which project has
an old copy.

| Version | Date | Change |
| --- | --- | --- |
| v2.1 | 2026-11-15 | Coexistence with pre-existing agents: inventory in `scan.sh` §3, install preflight + `--prefix=`, "Agent roles in this repo" table in the `AGENTS.md` template |
| v2 | 2026-11-15 | Simplified: 6 agents → 3 (planner/implementer/reviewer); fact layer 4 files → 1 `AGENTS.md`; English canonical |
| v1 | 2026-11-15 | Initial, six agents, bilingual templates (archived in `v1-archive.zip`) |

---

## 4. When to update this table

Three "write it down" moments and three "go look" moments.

| Trigger | Action | Cost |
| --- | --- | --- |
| **Adopting a project** | Add a row, status `partial` | 1 min |
| **After writing both sections and passing the References check** | Status → `done`, fill the fact-layer date | 10 s |
| **Upgrading the role layer** | Run `./install.sh <path> --agents-only --force` down the table first, then update version and date | 30 s each |
| **First weekend of the month** | Read the "fact layer updated" column; anything older than a month gets a fresh `scan.sh` and a diff against `AGENTS.md` | 5 min |
| **An agent repeats the same mistake in one project** | Write it into section 2 and turn it into a constraint | 5 min |
| **Quarterly** | Full regression on one project, see below | 30 min |

### The monthly pass looks at exactly one column

The date. A project older than a month may have an `AGENTS.md` that no longer matches reality, while
agents keep working from it daily. **This is your only chance to catch a stale fact layer** —
automation cannot do it: CI can check that the file exists, not that its contents are still true.

### The quarterly regression

Pick one project and do three things:

1. Give `planner` a real, medium-sized requirement. Are the paths it cites **real**, and did it reuse
   an existing implementation? A vague plan means the fact layer is too thin.
2. Plant a violation on purpose — e.g. make a service import a repository's private internals — and
   see whether lint and `reviewer` catch it. If not, the constraint layer has a hole.
3. Compare the directory map and commands in `AGENTS.md` against the actual repo.

One failure out of three means that project goes back to the workshop.

## 5. What this table must not do

- **Do not automate it.** Writing a row takes 10 seconds; a sync script costs more than it saves.
- **Do not record irrelevant detail.** GitHub URLs, descriptions, owners — git already has those.
  This table tracks one thing: the state of this agent setup on that project.
- **Do not exceed 20 rows.** Past twenty projects, the question is not the registry, it is which
  projects should be archived.
