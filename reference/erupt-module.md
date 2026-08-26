# 开发可复用的 erupt 功能模块

> 已对照 erupt 发布版实测核实（基线版本统一记录在 SKILL.md「版本基线」）。适用场景：要做的不是一个"应用"，而是可发布为 jar、任何 erupt 应用加依赖即用的**功能模块**（如 erupt-ai、erupt-job；完整实战范例见 erupt-wx 仓库）。

## 生成方式：复制 template-module/

模块脚手架是真实可编译的工程文件，**所有 pom 与代码以 `template-module/` 目录为唯一事实源**，本文档不重复贴代码：

1. 复制本 skill 的 `template-module/` 到目标目录
2. 全局替换三个占位符：
   - `__GROUP_ID__` → Maven groupId（不发布可用 `app`）
   - `__ARTIFACT_ID__` → 模块名 kebab-case（如 `erupt-wx`），涉及 `pom.xml` 与 `application.yml`
   - `modtpl` → 模块包名（纯小写，如 `wx`），**同时重命名 `src/main/java/modtpl`、`src/test/java/modtpl` 两个目录**，并同步 `META-INF/spring/...AutoConfiguration.imports` 里的类全名
3. 在包下写 `@Erupt` 实体、DataProxy、Handler——**写法与应用完全一致**，遵循 annotations.md / erupt-model.md，菜单在 `ModuleAutoConfiguration.initMenus()` 注册（文件内已附各种菜单类型的注释示例）
4. 启动 demo：`mvn spring-boot:test-run`（demo 启动类在 test 源集，不进 jar），完成后跑 `scripts/verify.sh` 自检
5. erupt 版本：脚手架 pom 的 `<erupt.version>` 为兜底值，按 SKILL.md 第 2 步的版本查询逻辑更新为最新 release

## 与应用（template/）的差异，仅三处

实体注解、DataProxy、`EruptModule` + `initMenus()`、H2 默认库等机制**与应用完全相同**。差异只在打包形态（已内置于 template-module，无需手工调整）：

| | 应用（template/） | 功能模块（template-module/） |
|---|---|---|
| erupt 依赖 scope | compile（默认） | provided（宿主必然自带，不向使用方传递） |
| spring-boot-maven-plugin | 默认 repackage，可执行 jar | 禁用 repackage，普通库 jar |
| 入口注册 | 启动类自身实现 EruptModule | 入口类写进 AutoConfiguration.imports，宿主自动装配 |

> ⚠️ 给用户生成**普通应用**时用 template/，严禁套用模块的 provided / 禁 repackage，否则应用运行时缺 erupt 依赖、也打不出可执行 jar。

## erupt 生态模块清单 —— 先复用，再造轮子

**写任何功能前先对照此表：能加一个依赖解决的，不要手写实现**（如定时任务直接引 erupt-job，不要自己写 @Scheduled + 管理界面）。groupId 统一 `xyz.erupt`，版本与 erupt 保持一致。

**starter 已自带（无需额外引入）**：

| 模块 | 能力 |
|---|---|
| erupt-core | 注解引擎、CRUD、附件上传 |
| erupt-data-jpa | ORM、EruptDao / lambdaQuery |
| erupt-upms | 用户、角色、组织、菜单权限、操作日志、在线用户 |
| erupt-security | 接口安全、防攻击 |
| erupt-web | 管理端前端页面 |

**按需引入的功能插件**：

| artifactId                   | 能力 |
|------------------------------|---|
| erupt-job                    | 定时任务管理（可视化 cron、执行记录、任务处理器） |
| erupt-report                 | BI 报表、图表 |
| erupt-designer               | 可视化表单设计器 |
| erupt-monitor                | 系统监控（服务器/JVM/在线状态） |
| erupt-magic-api              | 在线 IDE，写脚本即发布动态接口 |
| erupt-notice                 | 多渠道消息通知（站内信/邮件等渠道扩展） |
| erupt-print                  | 单据打印模板 |
| erupt-terminal               | 网页版服务器终端 |
| erupt-websocket              | WebSocket 支持 |
| erupt-tpl                    | 模板引擎，自定义页面/弹窗（详见 erupt-tpl.md） |
| erupt-spring-boot-starter-all | 一键全家桶：starter + 上述常用插件 + AI |

**AI 家族**：erupt-ai（LLM 接入与对话）、erupt-ai-rag（知识库 RAG）、erupt-ai-claw（自然语言直接操作后台）、erupt-ai-staff（数字员工）、erupt-ai-canvas（AI 生成视图页面）。

**非 JPA 数据源适配**（给任意数据后端套上 erupt CRUD 界面）：erupt-data-mongodb / es / http / jdbc / ldap / redis / s3 / k8s / feishu / notion / file / memory。

**微服务**：erupt-cloud-server（控制中心）+ erupt-cloud-node（业务节点）。

## 集成第三方服务的惯用模式（以多账号 SDK 为例）

- **注册表 Bean**：`Map<String, SdkClient>` + `@EventListener(ApplicationReadyEvent.class)` 从库加载初始化（不要用 @PostConstruct，建表可能未完成）
- **账号实体的 DataProxy**：`afterAdd/afterUpdate` 刷新注册表，`afterDelete` 移除
- **PASSWORD 字段编辑不回传**：`beforeUpdate` 里发现为空时从库回填旧值，否则密钥会被清空
- **外部动作挂在账号实体的 RowOperation（SINGLE）上**：handler 天然拿到账号上下文，无需选择表单
- **公开回调接口**：路径不要放在 `/erupt-api` 前缀下即免 erupt 鉴权（如 `/xxx/callback/{id}`）

## 高频坑（均为实测踩过）

| 坑 | 规避 |
|---|---|
| 多个 @RowOperation 不设 code | 点任何按钮都执行第一个 handler，必须各设唯一 code |
| eruptClass 表单类不继承 BaseModel | 启动报 Primary key not found |
| @Dynamic condition 用字段名作变量 | 变量固定为 `value`，服务端校验也执行该表达式 |
| 对着 erupt 开发版源码写代码 | API 位置可能与发布版不同（如 Readonly 包路径），一切以发布版 jar 为准 |
| RowOperation 的 data 参数当完整实体用 | erupt 传入的是按 id 重查的实体，但 handler 内仍建议 `eruptDao.find` 重查以获得关联字段 |
