# erupt-skill

[English](README.md) | 简体中文

一句话生成数据管理后台的 Claude Code Skill。

基于 [erupt](https://www.erupt.xyz) 低代码框架：说一句「帮我生成一个图书管理后台」，即可得到一个完整可运行的管理系统 —— 登录页、增删改查、搜索、导入导出、权限管理开箱即用。

**无需开发环境**：JDK 25（Eclipse Temurin，GPLv2 + Classpath Exception 协议）与 Maven 首次运行自动下载（多镜像兜底）并缓存于 `~/.erupt-skill`，系统已有 JDK 17+ 时直接复用；项目依赖走阿里云镜像加速；内置 H2 文件数据库，无需安装 MySQL。非开发人员也能一句话搭建任何领域的数据管理后台。

## 安装

本 skill 遵循 [Agent Skills](https://agentskills.io) 开放标准（SKILL.md），主流 AI 编程工具均可使用，将仓库克隆到对应工具的 skills 目录即可：

| 工具 | Skills 目录 | 说明 |
|------|------------|------|
| **Claude Code** | `~/.claude/skills/`（个人）或 `.claude/skills/`（项目） | 原生支持，按描述自动触发 |
| **Codex CLI** | `~/.codex/skills/`（个人）或 `.codex/skills/`（项目） | 用 `$erupt-admin ...` 调用或自动触发 |
| **Cursor** | `.cursor/skills/` 或 `.agents/skills/`（项目） | 见 [Cursor Agent Skills 文档](https://cursor.com/docs/skills) |
| **Trae** | `.agents/skills/`（项目） | 已支持 Agent Skills 开放标准 |
| **CodeBuddy** | `.agents/skills/`（项目） | 已支持 Agent Skills 开放标准 |

以 Claude Code 为例：

```bash
git clone https://github.com/erupts/erupt-skill.git ~/.claude/skills/erupt-admin
```

若工具不支持 skills，也可将仓库克隆到任意位置，然后直接对 AI 说：「阅读这个仓库的 SKILL.md 并按其流程帮我生成一个 XXX 管理后台」。

## 使用

在 Claude Code 中直接说：

```
生成一个图书管理后台
做一个客户订单管理系统，要能按状态筛选
给刚才的后台加一个借阅记录模块
```

生成后访问 http://localhost:8080，账号/密码 `erupt / erupt`。

## 目录结构

```
SKILL.md                    # skill 主流程
reference/annotations.md    # 实体生成规范（决策表 + 常见坑）
reference/erupt-*.md        # erupt 官方参考文档（注解字典、i18n、查询、Cube、API、TPL）
template/                   # 可运行的 erupt 项目模板（erupt 追 Maven 最新 release + Spring Boot 3.5 + H2）
  └─ resources/public/      # app.js / app.css：标题、Logo、主题色、样式自定义入口
scripts/setup-env.sh        # 准备 JDK + Maven（系统 JDK → 本地离线包 → 在线下载）
scripts/compile.sh          # 仅编译校验（改代码后快速发现语法错误）
scripts/run.sh              # 一键构建并启动
scripts/build-m2-seed.sh    # 可选：生成本地依赖种子到 vendor/m2，实现首次构建完全离线
vendor/                     # 可选本地离线包目录（不入 git）：JDK 压缩包与 m2 依赖种子
```

## 环境要求

- macOS / Linux / Windows（Windows 需在 Git Bash 中运行，Claude Code 已自带）
- 可访问网络（首次运行下载 JDK、Maven 与项目依赖，均会缓存复用）
