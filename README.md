# erupt-skill

English | [简体中文](README-zh.md)

A Claude Code Skill that generates a data admin backend from a single sentence.

Powered by the [erupt](https://www.erupt.xyz) low-code framework: say "build me a library admin backend" and get a complete, runnable admin system — login page, CRUD, search, import/export, and permission management out of the box.

**No dev environment required**: with no system JDK, the skill fetches a jlink-minimized OpenJDK 25 runtime on demand (built from Azul Zulu, GPLv2 + Classpath Exception, no licensing concerns; ~46 MB, cached in `~/.erupt-skill`; other platforms fall back to a full JDK download), Maven is prepared automatically, project dependencies go through the Aliyun mirror, and an embedded H2 file database means no MySQL install. The repo itself stays ~1 MB, so cloning is instant. Non-developers can build a data admin backend for any domain with one sentence.

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
git clone https://github.com/plinian/erupt-skill.git ~/.claude/skills/erupt-admin
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
scripts/setup-env.sh        # prepare JDK + Maven (system JDK → cached → minimized JDK from GitHub/Gitee Release → full JDK download)
scripts/compile.sh          # compile-only check (catch syntax errors after code changes)
scripts/run.sh              # one-command build and start
scripts/build-m2-seed.sh    # optional: build a local dependency seed into vendor/m2 for fully-offline first builds
scripts/build-jdk.sh        # maintainer: jlink-build the minimized JDK runtimes (uploaded to the GitHub + Gitee Release, not committed)
```

## Requirements

- macOS / Linux / Windows (on Windows run inside Git Bash, which Claude Code ships with)
- Network access (first run downloads Maven and project dependencies; with no system JDK it also fetches a ~46 MB minimized JDK once, then caches it)
