# Copilot Agent Kit

Drop a Copilot configuration into any git repository: **one fact file + three role agents**, so new
requirements land in your existing architecture and style instead of something alien.

Runs inside GitHub Copilot in VS Code or IntelliJ IDEA. No cloud agent, no CLI needed.

> Chinese reference translation: [`zh/README.md`](zh/README.md). English is the canonical version.

## What is in the box

```
copilot-agent-kit/
├── README.md                  this file — the only document you need to read
├── PROJECTS.md                multi-project registry: where adopted, version, recurring problems
├── install.sh                 installs 5 files; preflight for agents already present; --prefix=
├── scan.sh                    extracts only determinable facts, never invents a command
├── dependency-cruiser.js      5 rules; copy to your repo root as .dependency-cruiser.js
├── templates/                 ← the only part that gets copied into a project
│   ├── AGENTS.md              the fact layer
│   └── .github/
│       ├── agents/{planner,implementer,reviewer}.agent.md
│       └── PULL_REQUEST_TEMPLATE.md
└── zh/                        reference translation; never installed, never read by an agent
```

`templates/` is the product. Everything else is machinery or bookkeeping: you run `scan.sh` and
`install.sh`, you occasionally open `PROJECTS.md`, and you do not edit any of them.

## The 30-second version

The problem is not that the agent is dumb. It is that **it does not know what your project looks
like** — so it invents paths, invents directories, and refactors things you never asked about.

The fix is not a longer prompt. It is **separating facts from roles**:

| | Contents | Per project |
|---|---|---|
| **Fact layer** | `AGENTS.md`: stack, commands, directory map, invariants, prohibitions | must be written |
| **Role layer** | `.github/agents/`: three files | copy verbatim, never edit |

The role layer contains one key requirement: **read `AGENTS.md` before acting.** That is why one set
of agents works across all your projects and all project differences live in the fact file.

## Install

```bash
./install.sh /path/to/your-project
```

Five files go in — the `templates/` tree above, nothing else. Existing files are skipped by default,
so your edits survive. `--force` refreshes the role layer and **never** replaces a filled `AGENTS.md`:
that file holds the two hand-written sections, and nothing can regenerate them (`--force-facts` is the
only way in). To refresh the role layer across projects: `./install.sh <project> --agents-only --force`.

**Nothing fills `AGENTS.md` for you.** `install.sh` copies the template, square brackets and all;
`scan.sh` prints a draft to stdout and never writes a file. The split is deliberate:

| Part of `AGENTS.md` | Filled by | Why |
|---|---|---|
| Stack, commands, forbidden paths, directory map | you paste from `scan.sh` output | mechanical, but a candidate command still has to be executed once |
| Architecture invariants, prohibition boundaries | you, by hand | invisible in the code; a wrong guess misleads every agent for months |

If you never fill it, the template stays recognisable on purpose: `planner` opens its answer with
"fact layer missing, the following is inferred from code" instead of pretending to know the architecture.

**If `AGENTS.md` already exists, merge — never replace.** `scan.sh` prints a gap check as its last
section: which of the five required blocks are missing, and whether square-bracket placeholders are
still in there. Add only what is missing, keep the existing wording even when you would have phrased
it differently, and delete one of any two paragraphs that say the same thing. That file may already be
loaded by other tools and may encode habits nobody wrote down anywhere else.

## If the project already has agents

Real repositories usually do: a hand-written `plan` agent, a `.cursor/rules` folder, a `CLAUDE.md`,
agents your org publishes. **Do not start by installing.** There are two collisions and they differ
in severity.

**The fact layer is the dangerous one.** Every instruction file present is loaded at once. Two files
that both state the conventions do not merge — the model follows one of them and you never find out
which. Keep `AGENTS.md` canonical and turn the others into pointers (`CLAUDE.md` containing one line:
"Read AGENTS.md"). A copy is a fork, and forks drift.

**The role layer is the easy one.** For each role, exactly one agent is authoritative:

| Situation | What to do |
|---|---|
| Existing agent is yours and unused | Delete it. A spare is a coin flip at pick time |
| Team-owned — other people and CI reference it | Keep it untouched; install these with `--prefix=repo` so you get `repo-planner` / `repo-implementer` / `repo-reviewer`, and record both in the AGENTS.md role table |
| Different job, no overlap | Keep both, nothing to resolve |
| The existing one is simply better | Delete ours. Same test as always: does it cite real paths? |
| Built-in Plan agent, or org/enterprise agents | You cannot remove them. Make yours distinguishable in `description` ("bound to this repo's AGENTS.md") and do not duplicate their work |

Never `planner2`, `planner-new`, `my-planner` — at pick time those names carry no information.
`repo-` says what is different about it.

`install.sh` prints what is already there before writing anything; `scan.sh` section 3 lists every
agent and instruction file it found and the role each one appears to claim.

## Adopt it: four steps, about 20 minutes

**1. Scan — do not start from a blank template**

```bash
bash scan.sh /path/to/your-project > /tmp/facts.md
```

Six sections: stack and package-manager detection (a multiple-lockfile warning fires, since that is
the number one cause of wrong commands), candidate commands (from `package.json` scripts, Makefile,
CI config), an inventory of agent and instruction files already present, existing constraint configs,
forbidden zones, a directory map, and finally **three questions only you can answer**. A seventh
section appears only when `AGENTS.md` already exists — the gap check described above.

If something cannot be detected it prints "none found" rather than inventing a plausible command.

**2. Paste it in, then write only two sections by hand**

Paste sections 1-5 and **execute every command in section 2** — a candidate is not a working
command (some need dependencies installed or a database running).

Two sections are yours alone, because they are invisible in the code:

- **Architecture invariants**: who may call whom, in one sentence. The test is "could a linter
  enforce this". "Code should be clean" fails; "dependencies flow api → service → repo" passes.
- **Forbidden actions**: protected directories (the scanner finds those) plus process rules
  (never weaken tests to get CI green, never add dependencies unasked).

**3. Verify it is actually loaded**

Open a fresh chat, ask something narrow ("what is the test command in this repo"), expand
**References** in the answer, and check that `AGENTS.md` appears.

A file existing is not the same as a file being loaded. This is the most commonly skipped step, and
skipping it means you installed nothing.

**4. Commit.** It works locally immediately; committing is for history.

> The IDE's built-in `/init` (VS Code) or Settings → GitHub Copilot → Customizations (IDEA) can also
> draft something, but **it invents commands**. `scan.sh` exists to extract only facts that are
> actually there. Use both if you like: the IDE writes the structural description, you correct the
> commands against the scan.

## The daily loop

```
you write the task  →  planner plans  →  you decide  →  implementer implements  →  reviewer reviews  →  you commit
```

**Write the task in four parts**, or quality drops immediately: what to change / where (give paths) /
what counts as done / how to verify (specific command).

**To check whether planner really read the repo**, look at one thing: are the file paths it cites
real?

**Write feedback as a work order**, not "this logic seems off" — it will guess, guess wrong, and
burn a round:

```
src/auth/session.ts:42 does not handle the expired-token branch.
Symptom: still returns 200 after expiry.
Expected: return 401 and clear the cache. Follow handleExpired() in src/auth/api.ts, do not write a second one.
Do not touch files outside this task.
```

**Stop conditions**: third round on the same issue, diff growing instead of converging, or it starts
weakening tests or adding ignore comments to get CI green. Any one of those — take it over yourself.
Do not try a fourth round.

## Enforcement: tooling, not prose

Rules written in docs get skipped. Rules a tool can block do not.

`dependency-cruiser.js` is a copy-and-go starting point. Five rules need no knowledge of your layout
(circular imports, imports that resolve to nothing, undeclared packages, production code importing
devDependencies, production code importing test files). Copy it to your repo root as
`.dependency-cruiser.js`:

```bash
npx depcruise src --config .dependency-cruiser.js
```

**The rollout order decides whether it survives**: count existing violations first → **set `error`
only on rules with zero violations**, keep the rest as `warn` → promote one every two weeks. Set them
all to `error` at once, CI goes fully red, you disable it, and the whole thing dies.

After enabling it, **deliberately write one violating import and confirm it actually fails**. If it
does not fail, all you own is a config file that looks correct.

For Python use `import-linter`, same logic: start with just "layers may not import upwards" and
"packages may not import each other's internals".

## Maintenance rhythm

| Trigger | Action | Cost |
|---|---|---|
| Handing over a task | Check whether reviewer caught scope creep | 0 |
| The same review comment appears twice | Write it into `AGENTS.md` instead of repeating it | 1 min |
| First weekend of the month | Scan the "fact layer last updated" column in `PROJECTS.md`; re-run `scan.sh` for anything older than a month | 5 min |
| Quarterly | Regression on one project: are planner's paths real? Do planted violations get caught? | 30 min |

`PROJECTS.md` sits next to `install.sh` on purpose: **the moment you most need it is the moment you
are about to run the `--agents-only` upgrade**, and you will be in this directory then. By the third
project you cannot live without it.

## What v2 cut

v1 had 39 files; this has 10 (13 with the Chinese reference). Everything cut was something **you had
to maintain or decide between**:

| Cut | Why |
|---|---|
| English template tree (13 files) | Two copies of the same rules always drift |
| `copilot-instructions.md` | Copilot reads `AGENTS.md` natively; two copies are a drift risk |
| `docs/architecture.md` + `docs/conventions.md` | One architecture change meant editing three files; in practice you edit one. Merged, with "split past two pages" as the escape hatch |
| `karpathy.instructions.md` | Four principles compressed into four lines of "Working discipline" |
| `project-onboarder` agent | Replaced by `scan.sh` + your 20 minutes; it used to invent commands |
| `test-writer` / `docs-keeper` agents | Folded into implementer's definition of done, minus one "which agent now?" decision |
| Two guides, two starter READMEs | Folded into this file and the comments in `dependency-cruiser.js` |

**Not cut**: `scan.sh` (240 lines, but it is machinery — you never read it), `dependency-cruiser.js`
(tested), the three agents, and the shape of `AGENTS.md`.

The test: **the only file you read, edit, and make choices in each week is `AGENTS.md`.** Everything
else is install-and-forget.
