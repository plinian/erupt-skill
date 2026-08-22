---
name: erupt-admin
description: 一句话生成数据管理后台。当用户描述想要一个管理系统、后台、CRUD 系统、信息管理平台（如"生成一个图书管理后台"、"做一个客户管理系统"），或要求为已生成的 erupt 项目增改功能时使用。基于 erupt 低代码框架，自动准备 JDK/Maven 环境，非开发人员也可直接使用。
---

# erupt 一句话生成数据管理后台

根据用户一句话需求，生成基于 [erupt](https://www.erupt.xyz) 框架的完整可运行数据管理后台（内置 H2 数据库、自动登录页、增删改查、搜索、导入导出、权限管理），并自动准备 JDK 与 Maven 环境后启动。

## 工作流程

### 第 0 步：预下载运行环境（立即执行，不要等）

收到需求后**第一时间**用后台方式执行：

```bash
bash <skill目录>/scripts/setup-env.sh
```

这样在你解析需求、编写代码的同时，JDK 与 Maven 已在并行下载。环境说明：

- 系统已有 JDK 17+ 和 Maven 时直接复用，秒级完成
- 无系统 JDK 时使用 skill 内置的精简版 **Eclipse Temurin JDK 25**（`vendor/jdk/`，含 mac arm64 与 windows x64，GPLv2 + Classpath Exception 协议，无授权问题），解压到 `~/.erupt-skill/runtime` 即用，无需下载
- 内置包无对应平台时（如 Linux）才在线下载：官方源失败自动切清华镜像；Maven 3.9 自动下载，依赖默认走阿里云镜像

### 第 1 步：需求解析

从用户一句话中推断出领域模型，**不要追问细节**，用领域常识补全：

- 识别核心实体（通常 2~5 个），如"图书管理" → 图书、分类、借阅记录
- 为每个实体设计 5~10 个常识字段（名称、状态、时间、金额等）
- 识别实体间关系（分类→树形、明细→一对多、标签→多对多）
- 实体与字段命名用英文，界面标题（title）用用户使用的语言

### 第 2 步：生成项目

1. 项目名用英文 kebab-case（如 `library-admin`），在用户当前目录下创建
2. 复制本 skill 的 `template/` 目录到项目目录
3. 将 `pom.xml` 和 `src/main/resources/application.yml` 中的 `__ARTIFACT_ID__` 全部替换为项目名
4. 将 `src/main/resources/public/app.js` 中的 `__APP_TITLE__` 替换为系统中文名（如"图书管理系统"）、`__APP_DESC__` 替换为一句话描述
5. 在 `src/main/java/app/model/` 下编写实体类

**实体类必须严格遵循 [reference/annotations.md](reference/annotations.md) 的规范**，这是本 skill 的核心，编写前必读。需要完整注解字典（所有属性、枚举值、子注解定义）时读 [reference/erupt-model.md](reference/erupt-model.md)。

### 第 3 步：构建并启动

```bash
bash <skill目录>/scripts/run.sh <项目目录> [端口]
```

- 用后台方式运行此命令（构建首次需下载依赖，可能耗时数分钟）
- 环境已在第 0 步预下载，此处直接复用；`ERUPT_SKILL_NO_MIRROR=1` 可关闭阿里云镜像
- 持续观察日志：出现 `Started Application` 即启动成功；出现编译错误则修复实体类后重启
- 端口默认 8080，被占用时换端口重启（如 8081）

### 第 4 步：交付

告知用户：

> 后台已启动：http://localhost:8080
> 账号 / 密码：erupt / erupt
> 数据保存在项目 `data/` 目录下（H2 文件数据库），无需安装任何数据库

如可用浏览器工具，可截图登录页验证。

### 第 5 步：迭代（用户继续一句话提需求）

- 加字段 / 加实体：直接改代码，重启即可（`generate-ddl: true` 会自动加列、建表）
- 改外观（标题、Logo、主题色、样式）：编辑 `src/main/resources/public/app.js`（eruptSiteConfig 配置）和 `app.css`（自定义样式），无需改 Java 代码，重启后刷新页面生效
- 改字段类型 / 删字段：H2 不会自动删旧列，若启动报错，提示用户可删除项目 `data/` 目录重置数据后重启
- 换数据库：MySQL 等生产库只需改 `application.yml` 的 datasource 并在 pom 加对应驱动

### 进阶需求参考文档

用户迭代提出以下需求时，**先读对应参考文档再动手**：

| 需求 | 参考文档 |
|------|---------|
| 自定义按钮、数据过滤、钻取、卡片/甘特视图、字段联动、只读控制 | `reference/erupt-model.md` |
| 多语言 / 国际化 | `reference/erupt-i18n.md` |
| DataProxy / Service 中查询数据库 | `reference/erupt-lambda-query.md` |
| BI 报表、数据立方体（@EruptCube） | `reference/erupt-cube.md` |
| 外部系统调用后台接口 | `reference/erupt-api.md` |
| 自定义交互页面（TPL 模板） | `reference/erupt-tpl.md` |

**兜底**：遇到本地参考文档解决不了的问题（报错含义不明、不熟悉的注解属性、高级模块用法等），用 WebFetch 阅读 erupt 官方文档 https://docs.erupt.xyz 后再作答，不要凭猜测编写代码。

## 常见问题排查

| 现象 | 处理 |
|------|------|
| 编译报找不到 `xyz.erupt` 包 | 依赖未下载完成，查看 Maven 日志；网络问题时确认阿里云镜像已生效 |
| 端口占用 `Port 8080 was already in use` | 换端口：`run.sh <dir> 8081` |
| 启动报 JPA 列类型冲突 | 实体字段类型变更导致，删除项目 `data/` 目录重启 |
| Lombok 相关编译错误 | 确认实体类有 `@Getter @Setter`，不要手写 getter/setter |
| Windows 环境 | 脚本需在 Git Bash / MSYS 中运行（Claude Code on Windows 自带 Git Bash），内置 windows x64 JDK 可直接使用；脚本跑不通时可自装 [JDK 17](https://adoptium.net) 与 [Maven](https://maven.apache.org) 后直接 `mvn spring-boot:run` |

## 能力边界

- 本 skill 覆盖 erupt 核心 CRUD 能力；工作流（erupt-flow）、BI 报表（erupt-cube）、微服务等高级模块不在默认模板中，用户需要时再引入对应依赖
- 默认使用 H2 内嵌数据库，适合演示与轻量使用；正式生产建议切换 MySQL/PostgreSQL
