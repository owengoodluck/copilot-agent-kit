#!/usr/bin/env bash
# Install 5 files into a project: AGENTS.md, 3 agents, PR template.
#
#   ./install.sh /path/to/project                 skip files that already exist
#   ./install.sh /path/to/project --force         overwrite the role layer; keeps a filled AGENTS.md
#   ./install.sh /path/to/project --agents-only   refresh only the 3 agents
#   ./install.sh /path/to/project --prefix=repo   install as repo-planner / repo-implementer / ...
#   ./install.sh /path/to/project --force-facts   also overwrite AGENTS.md (destroys hand-written text)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

TARGET=""; FORCE=0; FORCE_FACTS=0; AGENTS_ONLY=0; PREFIX=""
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --force-facts) FORCE_FACTS=1 ;;
    --agents-only) AGENTS_ONLY=1 ;;
    --prefix=*) PREFIX="${1#--prefix=}" ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || { echo "Missing target path. Usage: ./install.sh /path/to/project [--force] [--agents-only] [--prefix=name]" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "No such directory: $TARGET" >&2; exit 1; }
[ -d "$TARGET/.git" ] || echo "Warning: $TARGET does not look like a git repo root — double-check the path." >&2
TARGET="$(cd "$TARGET" && pwd)"

# Preflight. An existing agent that overlaps a role is a decision, not a merge conflict, and it is
# cheaper to make that decision now than to discover it three weeks later in the agent picker.
if [ -d "$TARGET/.github/agents" ]; then
  OTHERS=""
  CONFLICT=0
  for f in "$TARGET"/.github/agents/*.md; do
    [ -f "$f" ] || continue
    b=$(basename "$f" | sed -e 's/\.agent\.md$//' -e 's/\.md$//')
    case "$b" in
      planner|implementer|reviewer) CONFLICT=1 ;;
      *) OTHERS="$OTHERS $b" ;;
    esac
  done
  if [ -n "$OTHERS" ]; then
    cat <<MSG

This project already defines agent profiles:$OTHERS
They are not removed and will sit in the picker next to the ones installed here.
Decide one owner per role before going further:
  unused and yours   -> delete it
  team-owned         -> keep it, install these as --prefix=repo (repo-planner, ...)
  a different job    -> keep both, and record the split in AGENTS.md

MSG
  fi
  [ "$CONFLICT" -eq 1 ] && cat <<'MSG'
Warning: an agent named planner / implementer / reviewer already exists here.
Installing these files would put two agents with the same name in the picker.
Use --prefix=repo to install alongside it, or delete the old one first.

MSG
fi

added=0; overwritten=0; skipped=0

while IFS= read -r rel; do
  rel="${rel#./}"
  if [ "$AGENTS_ONLY" -eq 1 ]; then
    case "$rel" in .github/agents/*) ;; *) continue ;; esac
  fi

  # --prefix only renames agent profiles: a fact file with a prefix would simply go unread.
  destrel="$rel"
  if [ -n "$PREFIX" ]; then
    case "$rel" in
      .github/agents/*) destrel=".github/agents/$PREFIX-$(basename "$rel" .agent.md).agent.md" ;;
    esac
  fi

  dest="$TARGET/$destrel"

  # AGENTS.md is the one file no script can regenerate: its two hand-written sections exist nowhere
  # else. --force is meant for the role layer, so it must not be able to delete weeks of writing.
  if [ "$rel" = "AGENTS.md" ] && [ -f "$dest" ] && [ "$FORCE_FACTS" -eq 0 ]; then
    printf '%-16s %s\n' "kept" "$destrel (hand-written; --force-facts to replace)"
    skipped=$((skipped+1)); continue
  fi

  if [ -f "$dest" ] && [ "$FORCE" -eq 0 ]; then
    printf '%-16s %s\n' "skipped" "$destrel"; skipped=$((skipped+1)); continue
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then overwritten=$((overwritten+1)); printf '%-16s %s\n' "overwritten" "$destrel"
  else added=$((added+1)); printf '%-16s %s\n' "added" "$destrel"; fi

  if [ "$destrel" != "$rel" ]; then
    # Rename the agent inside the file too, including handoff targets, or the picker shows one name
    # and every handoff points at a name that does not exist.
    # -E is required: BSD sed (macOS) has no \| alternation in basic regex, and the silent result
    # is a file whose name says repo-planner while the picker still says planner.
    sed -E -e "s/^name: (planner|implementer|reviewer)$/name: $PREFIX-\1/" \
           -e "s/^([[:space:]]*agent: )(planner|implementer|reviewer)$/\1$PREFIX-\2/" \
           "templates/$rel" > "$dest"
  else
    cp "templates/$rel" "$dest"
  fi
done < <(cd templates && find . -type f | sort)

printf '\n%d added, %d overwritten, %d skipped\n' "$added" "$overwritten" "$skipped"

# Only print next steps when something was actually installed.
[ "$added" -gt 0 ] || exit 0

cat <<'NEXT'

Next, four steps:
1. bash scan.sh /path/to/project > /tmp/facts.md
   Paste sections 1-5 into AGENTS.md, then run every command in section 2 to confirm it works.
2. Write two sections by hand: architecture invariants (one rule a linter could enforce),
   and forbidden actions.
3. Open a fresh chat, ask something narrow, expand References in the answer, and confirm
   AGENTS.md was actually loaded.
4. Commit. It works locally right away; committing is only for history.

Per task from here: planner → you decide → implementer → reviewer → you commit.
NEXT
