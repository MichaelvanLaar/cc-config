#!/usr/bin/env bash
# sync-config-table-version: 6
# Keeps the "Key Config Files" table in CLAUDE.md in sync with the filesystem.
# - Removes rows for files that no longer exist
# - Appends rows for new config files with a placeholder description
# - Excludes gitignored files (they are per-machine, not part of the committed state)
# Preserves all existing hand-written descriptions.
# Invoked automatically by the pre-commit hook.
#
# Every scan below is directory-guarded, so this one script self-adapts to the
# project shape: a plugin repo's `context/` scan is a no-op, a content repo's
# `plugins/` scan is a no-op. Do not fork it per project — /auditing-config
# compares the version marker above against the plugin's copy and offers to
# refresh, and local forks would be flagged as drift.
#
# One scan is content-guarded rather than directory-guarded: `context/` files
# are skipped entirely when CLAUDE.md carries the
# `<!-- cc-config: context-toc-registered -->` marker, since that marker means
# the project already registers those files in its own `## Context files`
# table (bootstrapping-config Step 3, content-onboarding Step 5) — listing them
# again here would just duplicate that table under a generic "TODO" summary.
#
# This script can only judge "is this a config-shaped file" (matches a scanned
# directory/extension), never "is this file important enough to belong in a
# lean CLAUDE.md" — that call needs human/agent judgment, which is what
# /auditing-config is for. When that skill decides a matched file isn't
# worth a row, deleting the row alone doesn't stick: the file still matches a
# scan on the next run and gets silently re-added with a placeholder. To make
# a demotion stick (while staying reversible), /auditing-config records it
# in a `key-config-excluded` HTML comment block anywhere in CLAUDE.md:
#
#   <!-- cc-config: key-config-excluded
#   path/to/file.ext — one-line reason — YYYY-MM-DD
#   -->
#
# Any path listed there is dropped from the table regardless of which scan
# matched it. Nothing here prunes stale entries or judges whether an excluded
# file has since grown important again — that periodic reconsideration is
# also /auditing-config's job, not this script's.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_MD="$ROOT/CLAUDE.md"

# CRLF-safe: carriage return computed at runtime (no literal CR in source).
cr=$(printf '\r')

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "sync-config-table: CLAUDE.md not found, skipping"
  exit 0
fi

# Collect config files
config_files=()

# Root-level config files (by extension)
while IFS= read -r -d '' f; do
  name="$(basename "$f")"
  # Skip non-config files
  case "$name" in
    package-lock.json|README.md|CHANGELOG.md|AGENTS.md|CLAUDE.md|LICENSE) continue ;;
  esac
  config_files+=("$name")
done < <(find "$ROOT" -maxdepth 1 -type f \( -name '*.json' -o -name '*.js' -o -name '*.ts' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.yaml' -o -name '*.yml' -o -name '*.toml' \) -print0 2>/dev/null | sort -z)

# Root-level dotfiles that are config files
for dotfile in .gitignore .npmignore .prettierignore .editorconfig .nvmrc .node-version .vale.ini .markdownlint.json .markdownlint.yaml .markdownlint.yml .claudeignore; do
  [[ -f "$ROOT/$dotfile" ]] && config_files+=("$dotfile")
done

# CLAUDE.md is the table's own host and is excluded from the extension scan
# above, so add it explicitly — it belongs in the table it lives in.
config_files+=("CLAUDE.md")

# Root-level named config files (non-dotfile conventions)
if [[ -f "$ROOT/DESIGN.md" ]]; then
  config_files+=("DESIGN.md")
fi

# .githooks/ files
if [[ -d "$ROOT/.githooks" ]]; then
  while IFS= read -r -d '' f; do
    config_files+=(".githooks/$(basename "$f")")
  done < <(find "$ROOT/.githooks" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
fi

# scripts/ shell scripts
if [[ -d "$ROOT/scripts" ]]; then
  while IFS= read -r -d '' f; do
    config_files+=("scripts/$(basename "$f")")
  done < <(find "$ROOT/scripts" -maxdepth 1 -type f -name '*.sh' -print0 2>/dev/null | sort -z)
fi

# .claude/ direct children (skip subdirectories like skills/)
if [[ -d "$ROOT/.claude" ]]; then
  while IFS= read -r -d '' f; do
    config_files+=(".claude/$(basename "$f")")
  done < <(find "$ROOT/.claude" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
fi

# .claude/skills/ skill definitions
if [[ -d "$ROOT/.claude/skills" ]]; then
  while IFS= read -r -d '' f; do
    relpath="${f#$ROOT/}"
    config_files+=("$relpath")
  done < <(find "$ROOT/.claude/skills" -maxdepth 2 -name 'SKILL.md' -type f -print0 2>/dev/null | sort -z)
fi

# plugins/ manifests, skills, and bundled hooks (plugin repos)
if [[ -d "$ROOT/plugins" ]]; then
  while IFS= read -r -d '' f; do
    relpath="${f#$ROOT/}"
    config_files+=("$relpath")
  done < <(find "$ROOT/plugins" -type f \( -name 'plugin.json' -o -name 'SKILL.md' -o -path '*/hooks/*.json' -o -path '*/hooks/*.sh' \) -print0 2>/dev/null | sort -z)
fi

# context/ reference files — skipped when CLAUDE.md carries the
# context-toc-registered marker (see header comment above).
if [[ -d "$ROOT/context" ]] && ! grep -qF '<!-- cc-config: context-toc-registered -->' "$CLAUDE_MD"; then
  while IFS= read -r -d '' f; do
    relpath="${f#$ROOT/}"
    config_files+=("$relpath")
  done < <(find "$ROOT/context" -maxdepth 2 -type f -name '*.md' -print0 2>/dev/null | sort -z)
fi

# .github/workflows/
if [[ -d "$ROOT/.github/workflows" ]]; then
  while IFS= read -r -d '' f; do
    config_files+=(".github/workflows/$(basename "$f")")
  done < <(find "$ROOT/.github/workflows" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
fi

# Filter out gitignored files (per-machine / personal files don't belong
# in the committed config table — they may not exist on other clones).
# git check-ignore exits 0 if the path is ignored, 1 if tracked/untracked-but-not-ignored.
filtered_files=()
cd "$ROOT"
for file in "${config_files[@]}"; do
  if ! git check-ignore -q "$file" 2>/dev/null; then
    filtered_files+=("$file")
  fi
done
config_files=("${filtered_files[@]}")

# Sort config files, dropping duplicates that overlapping scans may have added
mapfile -t sorted_files < <(printf '%s\n' "${config_files[@]}" | sort -u)

# Drop paths listed in the key-config-excluded block (see header comment).
# Format per line: <path> — <reason> — <date>; only the path before the first
# em-dash is read, so reason/date wording never has to match anything here.
excluded_files=()
in_exclude_block=false
while IFS= read -r line; do
  if [[ "$line" == *"<!-- cc-config: key-config-excluded"* ]]; then
    in_exclude_block=true
    continue
  fi
  if $in_exclude_block; then
    if [[ "$line" == *"-->"* ]]; then
      in_exclude_block=false
      continue
    fi
    path="${line%%—*}"
    path="${path#"${path%%[![:space:]]*}"}"
    path="${path%"${path##*[![:space:]]}"}"
    [[ -n "$path" ]] && excluded_files+=("$path")
  fi
done < "$CLAUDE_MD"

if ((${#excluded_files[@]})); then
  remaining_files=()
  for file in "${sorted_files[@]}"; do
    excluded=false
    for ex in "${excluded_files[@]}"; do
      [[ "$file" == "$ex" ]] && { excluded=true; break; }
    done
    $excluded || remaining_files+=("$file")
  done
  sorted_files=("${remaining_files[@]}")
fi

# Parse existing descriptions from CLAUDE.md
declare -A descriptions
section_found=false
while IFS= read -r line; do
  if [[ "$line" == *"## Key Config Files"* ]]; then
    section_found=true
    continue
  fi
  if $section_found; then
    if [[ "$line" =~ ^\|[[:space:]]*\`([^\`]+)\`[[:space:]]*\|[[:space:]]*(.+)[[:space:]]*\| ]]; then
      file="${BASH_REMATCH[1]}"
      desc="${BASH_REMATCH[2]}"
      # The capture is greedy and swallows the cell's trailing padding, which the
      # rebuilt row would then re-pad — adding a space per row on every run.
      desc="${desc%"${desc##*[![:space:]]}"}"
      [[ "$file" == "File" ]] && continue
      descriptions["$file"]="$desc"
    fi
  fi
done < "$CLAUDE_MD"

# Build new table
new_table="| File | Purpose |
|------|---------|"

for file in "${sorted_files[@]}"; do
  desc="${descriptions[$file]:-TODO: add description}"
  new_table+=$'\n'"| \`$file\` | $desc |"
done

# Replace the table in CLAUDE.md
# Find the section, skip old blank lines + table rows, emit new table
tmpfile="$(mktemp)"
in_section=false
table_replaced=false

while IFS= read -r line; do
  line="${line%$cr}"
  if [[ "$line" == *"## Key Config Files"* ]]; then
    in_section=true
    echo "$line" >> "$tmpfile"
    continue
  fi

  if $in_section && ! $table_replaced; then
    # Skip blank lines and old table rows between heading and next content
    if [[ "$line" == "" ]] || [[ "$line" == "|"* ]]; then
      continue
    fi
    # First non-blank, non-table line: emit new table, then this line
    echo "" >> "$tmpfile"
    echo "$new_table" >> "$tmpfile"
    echo "" >> "$tmpfile"
    echo "$line" >> "$tmpfile"
    table_replaced=true
    in_section=false
    continue
  fi

  echo "$line" >> "$tmpfile"
done < "$CLAUDE_MD"

# If we hit EOF while still in the section (table is the last thing)
if $in_section && ! $table_replaced; then
  echo "" >> "$tmpfile"
  echo "$new_table" >> "$tmpfile"
fi

# Normalize the candidate the same way the PostToolUse formatter normalizes
# CLAUDE.md, so the comparison below reflects content rather than table padding.
# Without this, the rebuilt table never matches the formatted file on disk and
# CLAUDE.md is rewritten and staged on every commit, including commits that
# touch no config file at all.
if command -v prettier >/dev/null 2>&1; then
  prettier --write --parser markdown "$tmpfile" > /dev/null 2>&1 || true
fi

# Check for changes
if diff -q "$CLAUDE_MD" "$tmpfile" > /dev/null 2>&1; then
  echo "sync-config-table: no changes"
  rm "$tmpfile"
else
  mv "$tmpfile" "$CLAUDE_MD"
  echo "sync-config-table: updated CLAUDE.md"
  # Auto-stage so the updated table is included in the triggering commit
  git add CLAUDE.md
fi
