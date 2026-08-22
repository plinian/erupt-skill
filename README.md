# erupt-skill

一句话生成数据管理后台的 Claude Code Skill。

基于 [erupt](https://www.erupt.xyz) 低代码框架：说一句「帮我生成一个图书管理后台」，即可得到一个完整可运行的管理系统 —— 登录页、增删改查、搜索、导入导出、权限管理开箱即用。

**无需开发环境**：仓库内置精简版 Eclipse Temurin JDK 25（GPLv2 + Classpath Exception，无授权问题，覆盖 macOS Apple Silicon 与 Windows x64；Linux 及其他平台自动在线下载），Maven 自动准备（缓存于 `~/.erupt-skill`），内置 H2 文件数据库，无需安装 MySQL。非开发人员也能一句话搭建任何领域的数据管理后台。

## 安装

```bash
git clone https://github.com/erupts/erupt-skill.git ~/.claude/skills/erupt-admin
```

或将本仓库目录复制到项目的 `.claude/skills/erupt-admin`。

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
template/                   # 可运行的 erupt 项目模板（erupt 2.0.4 + Spring Boot 3.5 + H2）
  └─ resources/public/      # app.js / app.css：标题、Logo、主题色、样式自定义入口
vendor/jdk/                 # 内置精简版 Temurin JDK 25（mac arm64 / windows x64，Linux 自动在线下载）
scripts/setup-env.sh        # 准备 JDK + Maven（系统 JDK → 内置 JDK → 在线下载）
scripts/run.sh              # 一键构建并启动
```

## 环境要求

- macOS / Linux / Windows（Windows 需在 Git Bash 中运行，Claude Code 已自带）
- 可访问网络（首次下载 Maven 与项目依赖；JDK 已内置无需下载）
