#!/usr/bin/env bash
# SessionStart hook, bundled with the cc-config plugin — fires in every project the
# plugin is active in, but is a no-op unless the project has explicitly opted in via
# CC_CONFIG_AUTO_GIT_PULL=true (set in .claude/settings.local.json's "env" block, since
# this is a personal multi-machine workflow preference, not a project-wide convention).
#
# On opt-in: fetches from the upstream remote and fast-forwards the current branch if
# possible. Never attempts a merge or rebase — if local and remote have diverged, it
# skips the pull and surfaces that fact so the user (or the agent, mid-session) can
# reconcile it deliberately instead of the hook doing it unattended.
#
# Never blocks: always exits 0.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[[ -z "$cwd" ]] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

cd "$cwd" 2>/dev/null || exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -z "$root" ]] && exit 0
cd "$root"

# Opt-in check. Prefer the env var (set by settings.json's "env" block), but also read
# .claude/settings.local.json directly — plugin-declared hooks are a newer surface and
# whether "env" reliably propagates into their subprocess environment isn't a documented
# guarantee, so the file read is the authoritative fallback, not a redundant belt-and-braces.
enabled=false
if [[ "${CC_CONFIG_AUTO_GIT_PULL:-}" == "true" ]]; then
  enabled=true
elif [[ -f ".claude/settings.local.json" ]]; then
  flag="$(jq -r '.env.CC_CONFIG_AUTO_GIT_PULL // empty' .claude/settings.local.json 2>/dev/null || true)"
  [[ "$flag" == "true" ]] && enabled=true
fi
$enabled || exit 0

# Only act on a real branch with an upstream — skip detached HEAD or unpublished branches.
branch="$(git symbolic-ref --short -q HEAD || true)"
[[ -z "$branch" ]] && exit 0

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
[[ -z "$upstream" ]] && exit 0

remote="$(git config --get "branch.$branch.remote" || true)"
[[ -z "$remote" ]] && exit 0

context=""

# Don't touch a dirty working tree — a fast-forward is safe, but let's not risk surprising
# the user by changing files under uncommitted work, even if git itself would allow it.
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  context="cc-config auto-pull: skipped — uncommitted changes in the working tree."
  jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
  exit 0
fi

timeout 15 git fetch --quiet "$remote" 2>/dev/null || exit 0

counts="$(git rev-list --left-right --count "HEAD...$upstream" 2>/dev/null || true)"
[[ -z "$counts" ]] && exit 0
ahead="$(printf '%s' "$counts" | awk '{print $1}')"
behind="$(printf '%s' "$counts" | awk '{print $2}')"

if [[ "$behind" -eq 0 ]]; then
  exit 0
elif [[ "$ahead" -eq 0 ]]; then
  if err="$(git merge --ff-only --quiet "$upstream" 2>&1)"; then
    context="cc-config auto-pull: fast-forwarded $branch by $behind commit(s) from $upstream."
  else
    context="cc-config auto-pull: $branch is $behind commit(s) behind $upstream but the fast-forward failed unexpectedly: ${err:0:200}"
  fi
else
  context="cc-config auto-pull: skipped — $branch has diverged from $upstream ($ahead ahead, $behind behind). Reconcile manually (e.g. rebase or merge) before continuing."
fi

if [[ -n "$context" ]]; then
  jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
fi

exit 0
