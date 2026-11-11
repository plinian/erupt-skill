# AGENTS.md

This file provides guidance to coding agents (Claude Code, Codex, ...) when working with code in this repository.

## What this repository is

An agent skill (the open Agent Skills format: `SKILL.md` at the root, skill name `erupt-admin`) that turns one
sentence into a runnable admin backend built on the [erupt](https://www.erupt.xyz) low-code framework. The
repository is the product: it is cloned into a tool's skills directory (e.g. `~/.claude/skills/erupt-admin`)
and read by an agent, so every file here is either an instruction to that agent, a project template it
copies, or a script it runs. There is no build and no test suite for the repository itself.

`SKILL.md`, `reference/` and the comments inside the templates are written in Chinese on purpose (they are
prompt content); `README.md` is English with `README.zh.md` as its translation — keep the two in step.

## Layout and how the parts fit

- `SKILL.md` — the workflow the agent follows: step 0 warm-up in the background, parse the request into
  entities, copy a template and write entities, build and start, verify, deliver, then iterate. Its table of
  advanced-requirement references (under step 5) routes each kind of follow-up request to one file under
  `reference/`; a new reference file must be added to that table or it is never read.
- `reference/` — `annotations.md` is the mandatory entity-generation spec (decision rules and pitfalls);
  `erupt-model.md` is the full annotation dictionary; the other `erupt-*.md` files cover one topic each;
  `erupt-ecosystem.md` lists existing erupt modules to reuse instead of hand-writing a feature;
  `doc-map.md` maps topics to the official docs (`https://docs.erupt.xyz/en/<path>`). Local reference keeps
  only decision rules and pitfalls verified against a released erupt; API detail belongs to the official
  docs, and where the two disagree the released jar wins, not the erupt development branch.
- `template/` — the application scaffold (Spring Boot parent, `erupt-spring-boot-starter`, H2 file database,
  Lombok). Placeholders: `__ARTIFACT_ID__` in `pom.xml`, `application.yml` and `Application.java`;
  `__APP_TITLE__` and `__APP_DESC__` in `src/main/resources/public/app.js`. `Application` itself implements
  `EruptModule` and registers menus in `initMenus()`.
- `template-module/` — the scaffold for a reusable erupt module (a library jar), used only when the user
  explicitly asks for a module. It differs from `template/` in three ways: erupt dependencies are
  `provided`, `spring-boot-maven-plugin` does not repackage, and the entry class is registered through
  `AutoConfiguration.imports` (the demo application lives in the test source set). Placeholders:
  `__GROUP_ID__`, `__ARTIFACT_ID__` and the package `modtpl`. The procedure is `reference/erupt-module.md`.
- `scripts/` — what the skill runs on the user's machine (bash; Git Bash on Windows). All of them go through
  `setup-env.sh`, which resolves a JDK 17+ (system → cached → downloaded OpenJDK, `ERUPT_SKILL_JDK` overrides
  the major version) and Maven, enables the Aliyun mirror unless `ERUPT_SKILL_NO_MIRROR=1`, and writes
  `~/.erupt-skill/env.sh` (`ERUPT_SKILL_HOME` moves that directory) for the others to source.
- `docs/` — the static landing page of the skill (`index.html`, `icon.svg`); not read by the skill.

## Commands

```bash
bash scripts/warmup.sh                        # prepare JDK/Maven and pre-download dependencies by building template/
bash scripts/run.sh <project-dir> [port]      # compile, then mvn spring-boot:run (default port 8080)
bash scripts/compile.sh <project-dir>         # compile only: the check after any Java change
bash scripts/verify.sh [port] [account] [password]   # read-only API smoke test of a running app; prints PASS
bash scripts/build-m2-seed.sh                 # optional: pack a dependency seed into vendor/m2 for offline first builds
```

`verify.sh` logs in (default `erupt` / `erupt`, the template's default account), lists the menus and queries
every table menu once; it needs `python3`. To try a template change end to end, copy the template elsewhere,
replace the placeholders as `SKILL.md` step 2 describes, then `run.sh` and `verify.sh` it. A generated module
demo starts with `mvn spring-boot:test-run`.

## Keep in step when editing

- **Versions have one declaration point each** (the version-baseline note in `SKILL.md` step 2): the fallback `<erupt.version>` and
  the Spring Boot `<parent>` version live in `template/pom.xml` and `template-module/pom.xml` and must be
  changed in both; the erupt version the `reference/` files were verified against is recorded only in that
  `SKILL.md` line. At generation time the skill queries Maven for the latest released
  `erupt-spring-boot-starter` and overrides the fallback; `warmup.sh` and `build-m2-seed.sh` repeat the same
  query, so a change to that logic touches `SKILL.md` and both scripts.
- A new placeholder or a file that carries one must be reflected in `SKILL.md` step 2,
  `reference/erupt-module.md` and the `sed` list in `build-m2-seed.sh`.
- `warmup.sh` keys its cache on the template pom content plus the resolved erupt version, and `run.sh` /
  `compile.sh` wait for a running warm-up (`~/.erupt-skill/warmup.lock`), so the scripts must stay safe to
  run concurrently against one local Maven repository.
- The skill's `description` front matter in `SKILL.md` is what triggers it in the host tool; treat a change
  to it as a behavior change.
- Generated applications ship with H2 in MySQL mode and `erupt.init-method-enum: every` (menus are re-seeded
  on each start, which is why a new entity appears after a restart).
