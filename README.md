<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/logo-dark.svg" />
    <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/logo.svg" width="220" alt="clever [cc] plugins" />
  </picture>
</p>

# cc-config

Two Claude Code skills for setting up and maintaining a best-practice Claude Code configuration, distributed as a Claude Code plugin.

**`/cc-config:bootstrapping-config`** bootstraps a lean configuration for a new or unconfigured project — a more opinionated alternative to the built-in `/init`.

**`/cc-config:auditing-config`** audits and improves an existing configuration against current best practices — useful after a project has grown, or periodically to prevent config drift.

Both skills work for software projects **and** content projects (static sites, article collections, documentation sets backed by a shared knowledge base). Detection covers code toolchains (npm, cargo, pip, composer, go, …) and content toolchains (Hugo, Jekyll, Astro, Eleventy, MkDocs, Vale, markdownlint).

Both skills are grounded in the consolidated recommendations from the [official Claude Code docs](https://code.claude.com/docs/en/best-practices), [Anthropic's engineering blog](https://www.anthropic.com/engineering), community configurations, and academic research on agent instruction design.

> **Breaking change (v1.0.0):** skill names dropped the `cc-config-` prefix (`cc-config-init` → `bootstrapping-config`, `cc-config-optimize` → `auditing-config`). Plugin skills are already namespaced by Claude Code as `cc-config:<skill-name>`, so the prefix was redundant. Update any saved `/cc-config-...` invocations to the new short names.

## At a glance

| Skill                             | Use it when                            | What it does                                                                                                                                            |
| --------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/cc-config:bootstrapping-config` | Starting a new or unconfigured project | Creates a lean CLAUDE.md, hardened permissions, formatter hooks, and cost-optimization defaults                                                         |
| `/cc-config:auditing-config`      | Auditing an existing setup             | Inventories every config file, flags anti-patterns, and reports findings in three tiers — must fix, should fix, nice to have — before touching anything |

## Table of Contents

- [cc-config](#cc-config)
  - [At a glance](#at-a-glance)
  - [Table of Contents](#table-of-contents)
  - [What problem do these skills solve?](#what-problem-do-these-skills-solve)
  - [Installation](#installation)
    - [Keeping skills current](#keeping-skills-current)
    - [Uninstalling](#uninstalling)
  - [Usage](#usage)
    - [`/cc-config:bootstrapping-config` — Bootstrap a new project](#cc-configbootstrapping-config--bootstrap-a-new-project)
    - [`/cc-config:auditing-config` — Audit and improve an existing setup](#cc-configauditing-config--audit-and-improve-an-existing-setup)
    - [Recommended workflow](#recommended-workflow)
  - [Working with design systems](#working-with-design-systems)
    - [The two design artifacts and where they live](#the-two-design-artifacts-and-where-they-live)
    - [Ordering guideline](#ordering-guideline)
      - [A — Design first, then code (most common)](#a--design-first-then-code-most-common)
      - [B — Code first, design later](#b--code-first-design-later)
      - [C — No Claude Design, but an existing DESIGN.md](#c--no-claude-design-but-an-existing-designmd)
      - [The two rules that cover every case](#the-two-rules-that-cover-every-case)
  - [What the skills create and check](#what-the-skills-create-and-check)
    - [Configuration files](#configuration-files)
    - [Key best practices applied](#key-best-practices-applied)
  - [Compatibility](#compatibility)
  - [Contributing](#contributing)
  - [License](#license)

## What problem do these skills solve?

The built-in `/init` generates a CLAUDE.md by scanning your repository. The result is often verbose, generic, and stuffed with information Claude already knows — burning context tokens on every single message. There's also no guidance on permissions, hooks, cost optimization, or the broader configuration surface beyond CLAUDE.md.

These skills take a different approach:

- **`/cc-config:bootstrapping-config`** creates the minimum viable configuration that's correct from day one: a slim CLAUDE.md, hardened `permissions.deny`, a formatter hook if applicable, and cost-optimization defaults. It asks targeted questions instead of guessing, and uses TODO placeholders rather than hallucinating commands it can't verify.

- **`/cc-config:auditing-config`** treats your existing configuration as a codebase to audit. It inventories every config file, measures CLAUDE.md line count, checks for known anti-patterns (bloat, missing hooks, hardcoded secrets, deprecated settings), and presents findings in three tiers — must fix, should fix, nice to have — before touching anything.

## Installation

Open Claude Code in any project and run:

```
/plugin marketplace add clever-cc-plugins/marketplace
/plugin install cc-config@clever-cc-plugins
```

That's it. Claude Code downloads the skills and makes `/cc-config:bootstrapping-config` and `/cc-config:auditing-config` available immediately.

> **Note:** Auto-update for third-party marketplaces is off by default — see [Keeping skills current](#keeping-skills-current) to enable it.

### Keeping skills current

The plugin system checks for updates automatically on startup. For third-party marketplaces (like this one), auto-update is **off by default**. To enable it:

1. Run `/plugin` in Claude Code
2. Go to the **Marketplaces** tab
3. Turn on auto-update for `clever-cc-plugins/marketplace`

Once enabled, Claude Code updates the skills on startup whenever a new version is available.

After running `/cc-config:bootstrapping-config`, additional files are created in your project (see [What the skills create and check](#what-the-skills-create-and-check)).

### Uninstalling

To remove the plugin and the marketplace in one step:

```
/plugin marketplace remove clever-cc-plugins
```

Removing the marketplace automatically uninstalls any plugins installed from it. To remove only the plugin while keeping the marketplace:

```
/plugin uninstall cc-config@clever-cc-plugins
```

## Usage

### `/cc-config:bootstrapping-config` — Bootstrap a new project

Start Claude Code in your project directory and invoke the skill:

```
/cc-config:bootstrapping-config
```

Or with a brief project description to skip some questions:

```
/cc-config:bootstrapping-config Next.js 14 e-commerce platform with Stripe and Postgres
/cc-config:bootstrapping-config Hugo site, 20 tutorial articles built from a shared knowledge base, output as Markdown
```

The skill will:

1. **Scan** for existing config, project files, quality tools, sensitive files, and design system artifacts (`DESIGN.md`, `context/design/`).
2. **Ask** targeted questions about anything it can't determine — including whether there is shared domain knowledge (brand voice, ICP, architecture decisions, API contracts) that should live in a shared context folder for all future skills to reference.
3. **Create** these files:
   - `.claude/settings.json` — permissions, hooks (if a formatter was detected), cost-optimization env vars
   - `CLAUDE.md` — slim project instructions (typically 20–40 lines), including a Key Config Files table and a Learnings section
   - `context/` — optional shared domain context folder at the project root (brand, architecture, etc.) with placeholder files, if the user confirms domain knowledge to capture; registered in a `## Context files` table in CLAUDE.md for skill discovery
   - `AGENTS.md` — only if a multi-tool AI environment is detected or mentioned
   - `.gitignore` additions for personal Claude Code files
   - `scripts/sync-config-table.sh` — keeps the Key Config Files table in CLAUDE.md in sync with the filesystem (including `DESIGN.md` and `context/` files)
   - `.githooks/pre-commit` — runs the sync script before each commit
4. **Wire** `DESIGN.md` into CLAUDE.md via `@`-import if the file exists at the project root, so Claude automatically consults the design system when building UI.
5. **Offer auto-pull on session start** (if the project is a git repo with a remote): asks once whether you work on this repo from multiple machines and want a fetch + fast-forward at the start of every session. Opt-in only, stored in the gitignored `.claude/settings.local.json` — never merges or rebases, and skips with a message if history has diverged.
6. **Activate** the git hooks directory: `git config core.hooksPath .githooks` (run automatically, once per clone).
7. **Summarize** what was created, what was left out, and high-leverage next steps — including a pointer to the `/schedule` skill for automating recurring multi-step workflows.

It deliberately does **not** set up MCP servers, create skills, or generate content it can't verify. Those decisions are premature for an empty project.

### `/cc-config:auditing-config` — Audit and improve an existing setup

After your project has some code (or anytime you want to check the config):

```
/cc-config:auditing-config
```

Or focused on a specific area:

```
/cc-config:auditing-config CLAUDE.md
/cc-config:auditing-config hooks
/cc-config:auditing-config costs
```

The skill will:

1. **Inventory** every configuration file, design system artifacts (`DESIGN.md`, `context/design/`), the project's tech stack, and available context (code, docs, OpenSpec specs). This now includes `.claude/learnings.md` and reports the number of entries it contains.
2. **Analyze** against best practices, checking for bloat, missing essentials (including a Learnings section and an unreferenced `DESIGN.md`), security gaps, cost optimization opportunities, multi-tool consistency, and — for git repos with a remote that haven't opted in yet — whether auto-pull on session start would help. Steps 1 and 2 run as three parallel, read-only subagents (one per domain) so the read-heavy scanning stays out of your main conversation's context — only their condensed findings come back.
3. **Review learnings**: if `.claude/learnings.md` exists, group entries into recurring patterns vs. one-offs and propose promoting patterns into CLAUDE.md, a skill, or a hook — then deleting resolved entries.
4. **Present** findings grouped as must fix / should fix / nice to have, with explanations for each.
5. **Wait for your approval** before changing anything.
6. **Apply** approved changes with before/after summaries.
7. **Report** metrics (e.g., "CLAUDE.md: 247 lines → 62 lines", "Learnings: 8 entries → 0").

### Recommended workflow

```
Day 1:    /cc-config:bootstrapping-config                     ← Bootstrap config for empty project
          ... start coding ...

Week 1:   /cc-config:auditing-config                 ← First optimization pass with real code context
          ... continue building ...

Ongoing:  /cc-config:auditing-config                 ← Periodic hygiene checks
          /cc-config:auditing-config CLAUDE.md       ← After CLAUDE.md has grown significantly
          /cc-config:auditing-config costs           ← When token spend feels high
```

## Working with design systems

### The two design artifacts and where they live

| Artifact                        | Where it lives    | What it is                                                                                                                                                                                |
| ------------------------------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DESIGN.md`                     | Project root      | Persistent design system spec — YAML tokens + Markdown rationale. Auto-read by Claude Code, Cursor, Copilot, and other agents. Think of it like `tsconfig.json` for your visual language. |
| Claude Design handoff artifacts | `context/design/` | Point-in-time exports from Claude Design: `PROMPT.md`, `design-notes.md`, `screenshots/`. Versioned alongside code, out of root clutter.                                                  |

`DESIGN.md` is an open-source format (originated from Google Stitch, broadly adopted). Claude Design's "Handoff to Claude Code" export produces a bundle of implementation-ready artifacts — these two things are complementary, not competing.

### Ordering guideline

#### A — Design first, then code (most common)

You have finished (or sketched) the design in Claude Design before setting up the project config.

1. Export or author `DESIGN.md` and place it at the **project root**.
2. Place Claude Design handoff artifacts (`PROMPT.md`, `design-notes.md`, `screenshots/`) in **`context/design/`** — create the folder manually if needed.
3. Run **`/cc-config:bootstrapping-config`**. It detects `DESIGN.md` during the scan, wires it into CLAUDE.md with the right `@`-import trigger, and includes both `DESIGN.md` and `context/design/` files in the Key Config Files table automatically.

#### B — Code first, design later

You bootstrapped the project first and are adding a design system later.

1. Run **`/cc-config:bootstrapping-config`** as usual to set up the project config.
2. When the design is ready: place `DESIGN.md` at the project root and handoff artifacts in `context/design/`.
3. Run **`/cc-config:auditing-config`**. It detects the unreferenced `DESIGN.md` and flags it as "should fix" — approve the suggestion and it adds the `@`-import to CLAUDE.md and updates the Key Config Files table.

#### C — No Claude Design, but an existing DESIGN.md

You use a different tool (Figma + Stitch, hand-authored tokens, etc.) that already produced a `DESIGN.md`.

1. Place `DESIGN.md` at the **project root** before running `/cc-config:bootstrapping-config`.
2. Run **`/cc-config:bootstrapping-config`** — it picks it up automatically. No extra steps needed.

#### The two rules that cover every case

1. **`DESIGN.md` always lives at the project root** — this is the community convention; agents discover it there without any configuration.
2. **Claude Design handoff artifacts always live in `context/design/`** — this keeps them versioned, organized, and visible in the Key Config Files table without polluting the root.

If you add design artifacts after running `/cc-config:bootstrapping-config`, a single `/cc-config:auditing-config` pass closes the gap.

## What the skills create and check

### Configuration files

| File                                                        | Created by                                                                          | Purpose                                                                                                                                                          |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                                                 | `/cc-config:bootstrapping-config`                                                   | Project instructions, loaded every message (target: 40–80 lines)                                                                                                 |
| `AGENTS.md`                                                 | `/cc-config:bootstrapping-config`                                                   | Vendor-neutral agent instructions (if multi-tool environment)                                                                                                    |
| `DESIGN.md`                                                 | manual / design tool                                                                | Design system spec — YAML tokens + Markdown rationale; wired into CLAUDE.md via `@`-import by `/cc-config:bootstrapping-config` and `/cc-config:auditing-config` |
| `.claude/settings.json`                                     | `/cc-config:bootstrapping-config`                                                   | Permissions, hooks, environment variables                                                                                                                        |
| `context/`                                                  | `/cc-config:bootstrapping-config` (optional)                                        | Shared domain context folder at project root — brand, architecture, etc.; registered in a `## Context files` table in CLAUDE.md                                  |
| `context/design/`                                           | manual (user)                                                                       | Claude Design handoff artifacts: `PROMPT.md`, `design-notes.md`, `screenshots/`                                                                                  |
| `.claude/learnings.md`                                      | auto (by skills)                                                                    | Project-specific observations auto-stored by skills at run end; also captures user-corrections instead of CLAUDE.md edits                                        |
| `scripts/sync-config-table.sh`                              | `/cc-config:bootstrapping-config`                                                   | Keeps the Key Config Files table in CLAUDE.md in sync — including `DESIGN.md` and `context/` files                                                               |
| `.githooks/pre-commit`                                      | `/cc-config:bootstrapping-config`                                                   | Runs the sync script before each commit; auto-stages CLAUDE.md when the table changes                                                                            |
| `.claude/skills/*`                                          | manual                                                                              | Recurring workflows (audited by `/cc-config:auditing-config`)                                                                                                    |
| `.claude/agents/*`                                          | manual                                                                              | Custom subagent definitions (audited by `/cc-config:auditing-config` for unreferenced or overprivileged agents)                                                  |
| `.mcp.json`                                                 | manual                                                                              | MCP server configuration (audited by `/cc-config:auditing-config`)                                                                                               |
| `<!-- cc-config: last-optimize-run -->` marker              | `/cc-config:bootstrapping-config` and `/cc-config:auditing-config`                  | Baseline (date + commit SHA) in CLAUDE.md that the bundled `SessionStart` staleness-reminder hook compares against                                               |
| `.claude/settings.local.json` `env.CC_CONFIG_AUTO_GIT_PULL` | `/cc-config:bootstrapping-config` or `/cc-config:auditing-config` (optional, asked) | Personal, gitignored opt-in flag that enables the bundled auto-pull-on-session-start hook for this machine                                                       |

### Key best practices applied

- **Lean CLAUDE.md**: every line costs tokens on every message. Remove anything the linter enforces, Claude already knows, or that's only relevant sometimes (move to a skill).
- **Progressive disclosure**: use `@`-imports for reference docs instead of inlining them. Reduces token waste by up to 59%.
- **Domain context folder**: shared knowledge (brand voice, ICP, architecture decisions, API contracts) lives in `context/` at the project root — registered in a `## Context files` table in CLAUDE.md so skills can discover and load files on demand. Claude Design handoff artifacts belong in `context/design/`.
- **Design system integration**: `DESIGN.md` at the project root is wired into CLAUDE.md via `@DESIGN.md **Read when:** building or editing any UI component`. Without this pointer Claude ignores the file for design decisions.
- **`permissions.deny`**: block `.env`, secrets, and destructive commands. Replaces the deprecated `ignorePatterns`.
- **Formatter hooks**: deterministic PostToolUse hooks beat instructions like "always run prettier" — the hook runs every time, the instruction might be ignored.
- **Cost-optimization defaults**: capped thinking-token ceiling (`MAX_THINKING_TOKENS`), Haiku for subagents (`CLAUDE_CODE_SUBAGENT_MODEL`), and a note to leave `alwaysThinkingEnabled`/`effortLevel` at their conservative defaults unless deep reasoning is genuinely needed every turn. Auto-compact threshold stays untouched by default — `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` only affects proactive compaction under specific session/model conditions and is a no-op on a typical local session, so it's no longer a blanket recommendation.
- **Verification loops**: test commands in CLAUDE.md so Claude can verify its own work (2–3× quality improvement).
- **Key Config Files auto-sync**: a pre-commit hook keeps the config file table in CLAUDE.md current — new files get a `TODO` placeholder, deleted files are removed automatically. Covers `DESIGN.md` and `context/` subdirectories. Uses `.githooks/` (no Husky dependency). Requires one-time activation per clone: `git config core.hooksPath .githooks`. Every collaborator must run this command after cloning — without it, the hook is silently skipped.
- **Learnings graduation**: at the end of each run, these skills automatically review and store project-specific observations to `.claude/learnings.md`, and recall stored learnings at the start of the next run — no manual action required. When the user corrects a mistake, Claude also appends a one-line correction instead of editing CLAUDE.md directly. Running `/cc-config:auditing-config` reviews the file: recurring patterns graduate into CLAUDE.md rules, skills, or hooks; one-off entries get deleted. Keeps CLAUDE.md stable between audits.
- **Skill feedback loops**: these skills implement an Observe-Notice-Store-Recall (ONSR) loop — learnings are stored automatically at run end and recalled at run start without any manual action. A terminal feedback question still solicits explicit corrections at the point of delivery.
- **Audit staleness reminder**: the plugin bundles a `SessionStart` hook that fires automatically in any project it's active in — no per-repo settings.json wiring needed, even if you only install `cc-config` at the user level rather than per-repo. It compares a `last-optimize-run` marker (written by `/cc-config:bootstrapping-config` and `/cc-config:auditing-config` on completion) against the repo's current commits and date, and nudges you to run `/cc-config:auditing-config` once drift crosses a threshold (default: 20+ commits or 14+ days with new activity). Silent otherwise, and silent in repos that haven't opted into `cc-config` at all.
- **Auto-pull on session start (opt-in)**: for multi-machine workflows where you sometimes forget to `git pull` before a session — leading to stale context or merge conflicts later — the plugin bundles a second `SessionStart` hook that fetches and fast-forwards the current branch when enabled. It's off by default; `/cc-config:bootstrapping-config` asks once for new git repos with a remote, and `/cc-config:auditing-config` suggests it for existing ones. Enabling it writes `CC_CONFIG_AUTO_GIT_PULL=true` to the gitignored `.claude/settings.local.json`, so it's a personal, per-machine setting, not a project convention. The hook never merges or rebases: on a dirty working tree or diverged history it skips and reports why, leaving reconciliation to you or the agent.
- **Scheduling**: once recurring multi-step workflows emerge, the `/schedule` skill can automate them — run a chain of skills on a cron schedule and land the output in a review folder for human sign-off.

## Compatibility

- Works with any programming language, framework, or build tool.
- Works with content projects: static-site generators (Hugo, Jekyll, Astro, Eleventy, MkDocs), article collections, documentation sets, and Markdown-driven workflows. Knowledge bases and style guides can be referenced via `@`-imports for progressive disclosure rather than inlined into CLAUDE.md.
- Works with design-system-driven projects: detects `DESIGN.md` at the project root and Claude Design handoff artifacts in `context/design/`, and wires them into CLAUDE.md correctly.
- Supports projects using [OpenSpec](https://github.com/Fission-AI/OpenSpec/) for structured change management.
- Supports multi-tool AI environments (Codex, Gemini, Cursor, Copilot) via AGENTS.md.
- Requires Claude Code (CLI or VS Code extension).

## Contributing

Issues and pull requests are welcome. If you've found a best practice that isn't covered, or a pattern that the skills should detect, please open an issue.

## License

[MIT](LICENSE)

---

<p align="center">
  Part of the <a href="https://github.com/clever-cc-plugins">clever-cc-plugins</a> family · <a href="https://github.com/clever-cc-plugins/marketplace">marketplace</a> · <a href="https://github.com/clever-cc-plugins/cc-concept">cc-concept</a> · <a href="https://github.com/clever-cc-plugins/cc-content">cc-content</a> · <a href="https://github.com/clever-cc-plugins/cc-career">cc-career</a> · <a href="https://github.com/clever-cc-plugins/cc-coach">cc-coach</a> · <a href="https://github.com/clever-cc-plugins/cc-handoff">cc-handoff</a> · <a href="https://github.com/clever-cc-plugins/cc-chime">cc-chime</a>
</p>
