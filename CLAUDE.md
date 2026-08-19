# cc-config

Reusable Claude Code skills for configuration management, distributed as a Claude Code plugin. Install via the plugin system (see README).

## Key Config Files

| File                                                     | Purpose                                                                                           |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `.claude/format-markdown.sh`                             | PostToolUse hook: formats Markdown files with prettier after edits                                |
| `.claude/guard-secret-files.sh`                          | PreToolUse hook: blocks reads/edits/writes of secret .env files                                   |
| `.claude/settings.json`                                  | Permissions, hooks, environment variables                                                         |
| `.claudeignore`                                          | Paths excluded from Claude Code indexing                                                          |
| `.githooks/pre-commit`                                   | Secret scanning (gitleaks) + CLAUDE.md table sync                                                 |
| `.github/workflows/claude-code-review.yml`               | Automatic PR review via Claude Code                                                               |
| `.github/workflows/claude.yml`                           | Trigger Claude via @claude mentions in issues/PRs                                                 |
| `.github/workflows/release.yml`                          | Triggers shared plugin-release workflow — version bump + GitHub release — on push to main         |
| `.gitignore`                                             | Git ignore patterns                                                                               |
| `CLAUDE.md`                                              | Project instructions, loaded every message                                                        |
| `plugins/cc-config/.claude-plugin/plugin.json`           | Plugin manifest for the cc-config plugin                                                          |
| `plugins/cc-config/agents/config-auditor.md`             | Custom subagent: tool-restricted (no Write/Edit) worker used by /auditing-config's parallel scans |
| `plugins/cc-config/hooks/auto-git-pull.sh`               | SessionStart hook: opt-in fetch + fast-forward pull at session start (CC_CONFIG_AUTO_GIT_PULL)    |
| `plugins/cc-config/hooks/check-optimize-staleness.sh`    | SessionStart hook: nudges to run /auditing-config when a project has drifted since its last audit |
| `plugins/cc-config/hooks/hooks.json`                     | Declares the bundled SessionStart hooks so they apply in any project the plugin is active in      |
| `plugins/cc-config/skills/auditing-config/SKILL.md`      | Skill: Audit and optimize an existing Claude Code configuration                                   |
| `plugins/cc-config/skills/bootstrapping-config/SKILL.md` | Skill: Bootstrap a best-practice Claude Code config for a new project                             |
| `scripts/sync-config-table.sh`                           | Keeps Key Config Files table in sync on each commit                                               |

<!-- cc-config: key-config-excluded
.claude/learnings.md — already described in ## Learnings section below; a table row would just duplicate that with a stale TODO placeholder — 2026-07-29
-->

<!-- cc-config: last-optimize-run: 2026-07-29 a76ad9058f844e7d8166ce5452d31c318f6b7493 -->

## Setup

To use the cc-config skills locally in this repo (dogfooding), install from the clever-cc-plugins marketplace:

```
/plugin marketplace add clever-cc-plugins/marketplace
/plugin install cc-config@clever-cc-plugins
```

## Don't

- Don't commit secrets or credentials to git
- Don't use `--force` flags — fix the underlying issue instead

## Compact Instructions

When compacting, preserve: current branch and list of modified plugins/skills.

## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to .claude/learnings.md. Don't modify CLAUDE.md directly.
