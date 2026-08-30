---
name: erupt-admin
description: 一句话生成数据管理后台。当用户描述想要一个管理系统、后台、CRUD 系统、信息管理平台，或各类业务系统如 CRM（客户管理）、ERP、OA、进销存、库存管理（WMS）、订单管理（OMS）、会员管理、人事管理（HR）、CMS 内容管理、工单系统、报名/预约系统（如"生成一个图书管理后台"、"做一个 CRM"、"搭个进销存"），或要求为已生成的 erupt 项目增改功能时使用。Generate a full admin backend from one sentence — use when the user asks for an admin panel, CRUD app, management system, dashboard backend, internal tool, or business systems like CRM, ERP, OA, inventory/warehouse (WMS), order management (OMS), membership, HR, CMS, ticketing, or booking systems (e.g. "build me a library admin system", "build a simple CRM"), or iterates on a generated erupt project. 基于 erupt 低代码框架，自动准备 JDK/Maven 环境，非开发人员也可直接使用。
---

# erupt 一句话生成数据管理后台

根据用户一句话需求，生成基于 [erupt](https://www.erupt.xyz) 框架的完整可运行数据管理后台（内置 H2 数据库、自动登录页、增删改查、搜索、导入导出、权限管理），并自动准备 JDK 与 Maven 环境后启动。

## 工作流程

### 第 0 步：预热运行环境与依赖（立即执行，不要等）

收到需求后**第一时间**用后台方式执行：

```bash
bash <skill目录>/scripts/warmup.sh
```

该脚本先准备 JDK/Maven 环境，再用模板项目跑一次真实构建，把 Spring Boot 与 erupt 依赖提前下载到 `~/.m2`——这样在你解析需求、编写代码的同时，依赖已在并行下载，用户项目首次构建基本免等待。环境说明：

- 系统已有 JDK 17+ 和 Maven 时直接复用，秒级完成
- 无系统 JDK 时按需下载 **OpenJDK 25**：Adoptium 官方源，失败自动切清华镜像（国内下载很快），解压到 `~/.erupt-skill/runtime` 后缓存复用；Maven 3.9 同样自动下载，依赖默认走阿里云镜像
- `vendor/m2/`（不入 git）可选放置依赖种子（`scripts/build-m2-seed.sh` 生成），存在时首次构建完全免下载
- 预热前先查最新 erupt 版本并锁定到临时 pom，确保预下的 erupt 依赖与第 4 步生成项目实际用的版本一致（避免预热了旧版、首次构建仍重下）；缓存标记按「模板 pom 内容 + 解析出的 erupt 版本」双重键控，模板变更或 erupt 新版发布都会自动重新预热；预热失败不阻塞流程，`run.sh` 构建时会自动补齐
- 预热进行中时 `run.sh` / `compile.sh` 会自动等待其完成（避免 Maven 本地仓库并发写入），无需人工协调

### 第 1 步：需求解析

从用户一句话中推断出领域模型，**不要追问细节**，用领域常识补全：

- 识别核心实体（通常 2~5 个），如"图书管理" → 图书、分类、借阅记录
- 为每个实体设计 5~10 个常识字段（名称、状态、时间、金额等）
- 识别实体间关系（分类→树形、明细→一对多、标签→多对多）
- 全局只有一条记录的实体（系统设置、参数配置等）→ FORM 表单视图，见 annotations.md「单行数据表单管理」
- 实体与字段命名用英文，界面标题（title）用用户使用的语言

### 第 2 步：生成项目

> **模板分流**：本 skill 的默认场景是生成**应用**（管理后台），一律复制 `template/`。仅当用户**明确提出**要开发可复用的 erupt 功能模块/扩展/插件（产出是 jar，给其他 erupt 应用加依赖使用，如"做一个 erupt-xx 模块"）时，才改用 `template-module/`，流程见 `reference/erupt-module.md`。拿不准时按应用处理，**不要**因为需求里出现"模块"二字（如"用户模块""订单模块"，那只是业务功能）就选 template-module。

1. 项目名用英文 kebab-case（如 `library-admin`），在用户当前目录下创建
2. 复制本 skill 的 `template/` 目录到项目目录
3. 将模板中**所有文件**的 `__ARTIFACT_ID__` 全部替换为项目名（涉及 `pom.xml`、`application.yml`、`Application.java` 三处，建议全局搜索确认无遗漏）
4. **erupt 版本尽量用最新**：查询 Maven 仓库版本列表，取语义化排序最大的正式版，更新 pom.xml 的 `<erupt.version>`：

   ```bash
   curl -s --max-time 10 "https://maven.aliyun.com/repository/public/xyz/erupt/erupt-spring-boot-starter/maven-metadata.xml" \
     | grep -oE "<version>[0-9]+\.[0-9]+\.[0-9]+</version>" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | sort -V | tail -1
   ```

   版本选择规则：
   - 取「模板默认版本」与「查询结果」中**较高**者，但采用前必须校验该版本真实存在（如下），不存在则用查询到的最新已发布版本：

     ```bash
     curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://maven.aliyun.com/repository/public/xyz/erupt/erupt-spring-boot-starter/<版本>/erupt-spring-boot-starter-<版本>.pom"   # 200 才可用
     ```

   - **版本号必须来自上述命令的实际输出，严禁凭记忆或训练数据填写**（曾出现过误写 1.13.0 旧版本的情况）
   - artifact 固定为 `erupt-spring-boot-starter`，不要查 `erupt`、`erupt-core` 等其他 artifact
   - 阿里云查不到时换 `https://repo1.maven.org/maven2/...`（路径相同）；两源都失败时保留模板默认版本，不要阻塞生成流程

   > **版本基线（全部版本的唯一声明点，升级只改这些位置）**：
   > - erupt 兜底版本：`template/pom.xml` 与 `template-module/pom.xml` 的 `<erupt.version>`（生成时自动查最新版覆盖）
   > - Spring Boot 版本：上述两个 pom 的 `<parent>`（Maven 要求 parent 版本必须写死，与 erupt 官方仓库使用的 Spring Boot 版本对齐，两处需同步改）
   > - `reference/` 各文档的实测核实基线：**erupt 2.1.1（2026-08）**，只记录在本行，reference 文档内不写版本号
5. 将 `src/main/resources/public/app.js` 中的 `__APP_TITLE__` 替换为系统中文名（如"图书管理系统"）、`__APP_DESC__` 替换为一句话描述
6. 在 `src/main/java/app/model/` 下编写实体类

**实体类必须严格遵循 [reference/annotations.md](reference/annotations.md) 的规范**，这是本 skill 的核心，编写前必读。需要完整注解字典（所有属性、枚举值、子注解定义）时读 [reference/erupt-model.md](reference/erupt-model.md)。

### 第 3 步：构建并启动

```bash
bash <skill目录>/scripts/run.sh <项目目录> [端口]
```

- 用后台方式运行此命令（依赖已在第 0 步预热时基本就绪；若预热未完成会自动等待或补齐下载）
- 环境已在第 0 步准备完毕，此处直接复用；`ERUPT_SKILL_NO_MIRROR=1` 可关闭阿里云镜像
- 持续观察日志：出现 `Started Application` 即启动成功；出现编译错误则修复实体类后重启
- 端口默认 8080，被占用时换端口重启（如 8081）

### 第 4 步：交付

告知用户：

> 后台已启动：http://localhost:8080
> 账号 / 密码：erupt / erupt
> 数据保存在项目 `data/` 目录下（H2 文件数据库），无需安装任何数据库

**交付前先跑 API 自检**（只读，不写数据）：登录 → 拉菜单 → 逐表查询，任何实体注解错误（联动表达式、权限配置等）都会在这一步暴露，而不是等用户点到才发现：

```bash
bash <skill目录>/scripts/verify.sh [端口]
```

输出 `PASS` 再交付；某张表报 ERROR 时按报错信息修复实体后重启复检。如可用浏览器工具，可再截图登录页确认。

### 第 5 步：迭代（用户继续一句话提需求）

**任何 Java 代码改动后，必须先前台编译校验，通过后再重启，不要只改代码不验证**：

```bash
bash <skill目录>/scripts/compile.sh <项目目录>
```

- 编译报错时根据错误信息修复（缺 import、注解属性写错、类型不匹配等），修到编译通过为止
- 加字段 / 加实体：改代码 → 编译校验 → 重启（`generate-ddl: true` 会自动加列、建表）
- 改外观（标题、Logo、主题色、样式）：编辑 `src/main/resources/public/app.js`（eruptSiteConfig 配置）和 `app.css`（自定义样式），无需改 Java 代码，重启后刷新页面生效
- 自定义整页界面（仪表盘、数据大屏、任意自定义页面）：用 TPL——HTML 放 `src/main/resources/tpl/`，在 `initMenus()` 注册 type 为 `"tpl"` 的菜单即成为全页面菜单项，零 Java 代码，**必读 [reference/erupt-tpl.md](reference/erupt-tpl.md)**
- 改字段类型 / 删字段：H2 不会自动删旧列，若启动报错，提示用户可删除项目 `data/` 目录重置数据后重启
- 换数据库：MySQL 等生产库只需改 `application.yml` 的 datasource 并在 pom 加对应驱动

### 进阶需求参考文档

用户迭代提出以下需求时，**先读对应参考文档再动手**：

| 需求 | 参考文档 |
|------|---------|
| 自定义按钮、数据过滤、钻取、卡片/甘特视图、字段联动、只读控制 | `reference/erupt-model.md` |
| 列表合计行/顶部提醒/显示脱敏、Excel 导入导出拦截、选 A 带出 B、下拉级联、弹窗预填 | `reference/erupt-hooks.md` |
| 数据权限（只看自己/本部门/按职级）、获取当前用户、SSO/LDAP 登录、OpenAPI、附件上云、配置速查 | `reference/erupt-upms.md` |
| 数据不在数据库：对接 REST API / 跨库表 / 本地文件 / 命令输出 / 内存数据 | `reference/erupt-datasource.md` |
| 多语言 / 国际化 | `reference/erupt-i18n.md` |
| DataProxy / Service 中查询数据库 | `reference/erupt-lambda-query.md` |
| BI 报表、数据立方体（@EruptCube） | `reference/erupt-cube.md` |
| 外部系统调用后台接口 | `reference/erupt-api.md` |
| 自定义前端页面：全页面菜单（仪表盘/大屏）、嵌入弹窗/视图（TPL 模板） | `reference/erupt-tpl.md` |
| 定时任务、报表、消息通知、监控、打印、AI 对话、非 JPA 数据源等**现成能力** | **先查 `reference/erupt-ecosystem.md`，加依赖复用，不要手写实现** |
| 开发可复用 erupt 功能模块（发布为 jar 供其他 erupt 应用引入） | `reference/erupt-module.md` |
| 需要注解全量属性、完整示例、上表未覆盖的能力细节 | `reference/doc-map.md`（官方文档地图，随 erupt 版本更新的单一事实源） |

本地 reference 只保留**决策规则**与**实测坑**（官方文档没有的），API 细节一律走官方文档。

**兜底**：本地参考文档解决不了时（报错含义不明、不熟悉的注解属性、高级模块用法等），按 `reference/doc-map.md` 找到对应主题，用 WebFetch 拉取 GitHub raw markdown 阅读后再作答，不要凭猜测编写代码。**注意：官网 https://docs.erupt.xyz 是 JS 渲染，WebFetch 抓不到正文，必须走 doc-map 里的 `raw.githubusercontent.com/.../en/*.md` 地址。**

**文档与实际冲突时以发布版为准**：reference 文档是人工维护的快照，可能落后于 erupt 新版本。当编译/运行结果与文档描述冲突时，以发布版 jar 的实际内容为准，不要对照 erupt 主仓库开发分支源码——开发版与发布版的 API 位置可能不同。使用不熟悉的注解组合（多 RowOperation、eruptClass 弹窗表单、@Dynamic 联动等）前，先在参考文档或发布版 jar 中核实用法再生成代码，一次写对远比编译报错后反复试错省时省 token。

## 常见问题排查

| 现象 | 处理 |
|------|------|
| 编译报找不到 `xyz.erupt` 包 | 依赖未下载完成，查看 Maven 日志；网络问题时确认阿里云镜像已生效 |
| 端口占用 `Port 8080 was already in use` | 换端口：`run.sh <dir> 8081` |
| 启动报 JPA 列类型冲突 | 实体字段类型变更导致，删除项目 `data/` 目录重启 |
| 编译大量报 `cannot find symbol` getter/setter | JDK 23+ 默认禁用隐式注解处理，确认 pom 的 maven-compiler-plugin 已配置 lombok `annotationProcessorPaths`（模板已内置）；同时确认实体类有 `@Getter @Setter` |
| 提交表单报 500 `ReferenceError: "xxx" is not defined` | `@Dynamic` 的 condition 用了字段名作变量，改为固定变量 `value` |
| 启动报 `Primary key not found` | 指向弹窗表单类 → `eruptClass` 表单类必须 `extends BaseModel`；指向自定义主键的实体 → `primaryKeyCol` 字段必须标注 `@EruptField`（可 `show = false` 隐藏） |
| 多个自定义按钮点击后都执行同一个逻辑 | 多个 `@RowOperation` 必须各设唯一 `code`，空串会永远命中第一个 |
| Windows 环境 | 脚本需在 Git Bash / MSYS 中运行（Claude Code on Windows 自带 Git Bash），内置 windows x64 JDK 可直接使用；脚本跑不通时可自装 [JDK 17](https://adoptium.net) 与 [Maven](https://maven.apache.org) 后直接 `mvn spring-boot:run` |

## 能力边界

- 本 skill 覆盖 erupt 核心 CRUD 能力；定时任务、报表、通知、AI、微服务等能力不在默认模板中，需要时按 `reference/erupt-ecosystem.md` 清单加依赖引入，不要手写实现
- 默认使用 H2 内嵌数据库，适合演示与轻量使用；正式生产建议切换 MySQL/PostgreSQL
