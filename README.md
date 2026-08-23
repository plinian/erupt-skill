# erupt-skill

English | [简体中文](README-zh.md)

A Claude Code Skill that generates a data admin backend from a single sentence.

Powered by the [erupt](https://www.erupt.xyz) low-code framework: say "build me a library admin backend" and get a complete, runnable admin system — login page, CRUD, search, import/export, and permission management out of the box.

**No dev environment required**: the repo bundles a trimmed Eclipse Temurin JDK 25 (GPLv2 + Classpath Exception, no licensing concerns; covers macOS Apple Silicon and Windows x64, other platforms download automatically), Maven is prepared automatically (cached in `~/.erupt-skill`), project dependencies are pre-bundled (`vendor/m2/`, seeded into `~/.m2/repository` on first run so the first build needs almost no downloads), and an embedded H2 file database means no MySQL install. Non-developers can build a data admin backend for any domain with one sentence.

## Install

This skill follows the open [Agent Skills](https://agentskills.io) standard (SKILL.md), supported by most mainstream AI coding tools. Clone the repo into the skills directory of your tool:

| Tool | Skills directory | Notes |
|------|-----------------|-------|
| **Claude Code** | `~/.claude/skills/` (personal) or `.claude/skills/` (project) | Native support, auto-activates by description |
| **Codex CLI** | `~/.codex/skills/` (personal) or `.codex/skills/` (project) | Invoke with `$erupt-admin ...` or auto-activation |
| **Cursor** | `.cursor/skills/` or `.agents/skills/` (project) | See [Cursor Agent Skills docs](https://cursor.com/docs/skills) |
| **Trae** | `.agents/skills/` (project) | Supports the Agent Skills open standard |
| **CodeBuddy** | `.agents/skills/` (project) | Supports the Agent Skills open standard |

Example (Claude Code):

```bash
git clone https://github.com/erupts/erupt-skill.git ~/.claude/skills/erupt-admin
```

For any tool without native skill support, just clone this repo anywhere and tell the agent: *"Read SKILL.md in this repo and follow its workflow to build me a XXX admin backend."*

## Usage

Just say in Claude Code:

```
Build a library admin backend
Create a customer order management system with status filtering
Add a borrow-record module to the backend you just built
```

Then open http://localhost:8080 and log in with `erupt / erupt`.

## Directory Structure

```
SKILL.md                    # main skill workflow
reference/annotations.md    # entity generation spec (decision tables + common pitfalls)
reference/erupt-*.md        # official erupt reference docs (annotations, i18n, query, Cube, API, TPL)
template/                   # runnable erupt project template (latest erupt release + Spring Boot 3.5 + H2)
  └─ resources/public/      # app.js / app.css: title, logo, theme color, style customization
vendor/jdk/                 # bundled trimmed Temurin JDK 25 (mac arm64 / windows x64; Linux downloads automatically)
vendor/m2/                  # pre-bundled Maven dependencies (seeded into ~/.m2/repository on first run, no downloads)
scripts/setup-env.sh        # prepare JDK + Maven (system JDK → bundled JDK → online download)
scripts/compile.sh          # compile-only check (catch syntax errors after code changes)
scripts/run.sh              # one-command build and start
```

## Requirements

- macOS / Linux / Windows (on Windows run inside Git Bash, which Claude Code ships with)
- Network access (only Maven itself may be downloaded on first run; the JDK and project dependencies are bundled)
