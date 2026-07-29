#!/usr/bin/env bash
# SessionStart hook, bundled with the cc-config plugin — fires automatically in any
# project the plugin is active in, no per-repo settings.json wiring needed.
#
# Reminds the user to run /cc-config-optimize once a project has drifted noticeably
# since the last audit. "Last audit" is read from a marker that /cc-config-init and
# /cc-config-optimize write to CLAUDE.md on completion:
#
#   <!-- cc-config: last-optimize-run: YYYY-MM-DD <commit-sha> -->
#
# Never blocks: always exits 0. Stays silent unless it finds clear evidence the
# project already opted into cc-config (a sync-config-table.sh with a version
# marker) — otherwise every non-cc-config repo would get pestered on every launch.
# This is a nudge, not a gate: deciding whether now is a good time to audit is a
# judgment call for the human, not this hook.

set -euo pipefail

COMMIT_THRESHOLD=20
DAY_THRESHOLD=14

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[[ -z "$cwd" ]] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

cd "$cwd" 2>/dev/null || exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -z "$root" ]] && exit 0

claude_md="$root/CLAUDE.md"
[[ -f "$claude_md" ]] || exit 0

sync_script="$root/scripts/sync-config-table.sh"
uses_cc_config=false
if [[ -f "$sync_script" ]] && grep -q 'sync-config-table-version' "$sync_script" 2>/dev/null; then
  uses_cc_config=true
fi

marker_line="$(grep -m1 'cc-config: last-optimize-run:' "$claude_md" || true)"

remind=false
reason=""

if [[ -z "$marker_line" ]]; then
  if $uses_cc_config; then
    remind=true
    reason="This project has cc-config's Key Config Files sync set up, but no record of /cc-config-init or /cc-config-optimize ever completing a full run."
  fi
else
  marker_date="$(printf '%s' "$marker_line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)"
  marker_sha="$(printf '%s' "$marker_line" | grep -oE '\b[0-9a-f]{7,40}\b' | head -1 || true)"

  commits_since=""
  if [[ -n "${marker_sha:-}" ]] && git cat-file -e "${marker_sha}^{commit}" 2>/dev/null; then
    commits_since="$(git rev-list --count "$marker_sha"..HEAD 2>/dev/null || true)"
  fi

  if [[ -n "$commits_since" && "$commits_since" -ge "$COMMIT_THRESHOLD" ]]; then
    remind=true
    reason="$commits_since commits have landed since the last /cc-config-optimize run ($marker_date)."
  elif [[ -n "${marker_date:-}" ]]; then
    marker_epoch="$(date -d "$marker_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$marker_date" +%s 2>/dev/null || true)"
    if [[ -n "${marker_epoch:-}" ]]; then
      now_epoch="$(date +%s)"
      days_since=$(( (now_epoch - marker_epoch) / 86400 ))
      last_commit_epoch="$(git log -1 --format=%ct 2>/dev/null || echo 0)"
      if [[ "$last_commit_epoch" -gt "$marker_epoch" && "$days_since" -ge "$DAY_THRESHOLD" ]]; then
        remind=true
        reason="It's been $days_since days since the last /cc-config-optimize run ($marker_date), and the repo has new commits since then."
      fi
    fi
  fi
fi

if $remind; then
  context="cc-config reminder: $reason Consider running /cc-config-optimize to catch drift (stale Key Config Files, outdated sync script, config best practices) before it accumulates."
  jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
fi

exit 0
