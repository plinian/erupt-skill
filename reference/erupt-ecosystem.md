# erupt 生态模块清单 —— 先复用，再造轮子

> 适用于所有场景（生成应用、迭代需求、开发扩展模块）。**实现任何功能前先对照此表：能加一个依赖解决的，不要手写实现**（如用户要定时任务，直接引 erupt-job，不要自己写 @Scheduled + 管理界面）。

引入方式：pom 加依赖即用（groupId 统一 `xyz.erupt`，版本用 `${erupt.version}` 与 erupt 保持一致），各模块自带 AutoConfiguration 与菜单注册，重启后功能菜单自动出现（`erupt.init-method-enum: every` 时）。

## starter 已自带（无需额外引入）

| 模块 | 能力 |
|---|---|
| erupt-core | 注解引擎、CRUD、附件上传 |
| erupt-data-jpa | ORM、EruptDao / lambdaQuery |
| erupt-upms | 用户、角色、组织、菜单权限、操作日志、在线用户 |
| erupt-security | 接口安全、防攻击 |
| erupt-web | 管理端前端页面 |

## 按需引入的功能插件

| artifactId | 能力 | 典型需求触发词 |
|---|---|---|
| erupt-job | 定时任务管理（可视化 cron、执行记录、任务处理器） | 定时、调度、跑批 |
| erupt-report | BI 报表、图表 | 报表、图表、统计 |
| erupt-designer | 可视化表单设计器 | 拖拽建表单 |
| erupt-monitor | 系统监控（服务器/JVM/在线状态） | 监控、运维 |
| erupt-magic-api | 在线 IDE，写脚本即发布动态接口 | 动态接口、在线脚本 |
| erupt-notice | 多渠道消息通知（站内信/邮件等渠道扩展） | 消息、通知、提醒 |
| erupt-print | 单据打印模板 | 打印、单据 |
| erupt-terminal | 网页版服务器终端 | 终端、SSH |
| erupt-remote | 后台维护远程主机，网页里直开 VNC 桌面 / SSH 终端 + SFTP 文件面板 | 远程桌面、跳板机、堡垒机、远程运维 |
| erupt-atlas | 模型图谱：血缘、层级、影响面、体检视图 + 可搜索的 Erupt 类注册表 | 模型关系、血缘、影响分析 |
| erupt-sso | 单点登录：OAuth2 / OIDC 认证源在后台配置，17 种供应商预设（Keycloak、Authing、Okta、Auth0、Entra ID、Google、GitHub、Gitee、飞书、钉钉、企业微信、微信…），登录页自动出按钮 | 单点登录、SSO、用飞书/钉钉/企微/微信登录、OAuth |
| erupt-comment | 记录评论：任意记录一条评论流，一级回复、置顶 / 已解决、行评论计数、@提及站内通知（需 erupt-notice） | 评论、留言、讨论、协作备注、@同事 |
| erupt-websocket | WebSocket 支持 | 实时推送 |
| erupt-tpl | 模板引擎，自定义页面/弹窗（详见 erupt-tpl.md） | 自定义页面、大屏 |
| erupt-spring-boot-starter-all | 一键全家桶：starter + 上述常用插件（含 erupt-sso / erupt-comment）+ AI（含 erupt-ai-decision） | — |

## AI 家族

erupt-ai（LLM 接入与对话）、erupt-ai-rag（知识库 RAG）、erupt-ai-claw（自然语言直接操作后台）、erupt-ai-staff（数字员工）、erupt-ai-canvas（AI 生成视图页面）、erupt-ai-decision（AI 决策：把「是否 / 选项 / 评分」判断交给决策模型，返回带概率的类型化答案，代码按阈值分支；仅依赖 erupt-data-jpa，不需要 erupt-ai）。

## 非 JPA 数据源适配

给任意数据后端套上 erupt CRUD 界面：erupt-data-mongodb / es / http / jdbc / ldap / redis / s3 / k8s / feishu（飞书多维表）/ dingtalk（钉钉多维表）/ airtable / notion / file / memory。

## 微服务

erupt-cloud-server（控制中心）+ erupt-cloud-node（业务节点）。

## 引入依赖后怎么写代码

需要写代码接入的模块，入口类与用法见 doc-map.md 对应页：

| 模块 | 你要写什么 | 文档（doc-map 相对路径） |
|---|---|---|
| erupt-job | 实现 `EruptJobHandler`（`xyz.erupt.job.handler`）注册为 Bean，cron/参数界面配置 | `modules/erupt-job` |
| erupt-notice | 注入 `EruptNoticeService.send(...)` 发消息；继承 `AbstractNoticeChannel` 扩展渠道 | `modules/erupt-notice` |
| erupt-websocket | 注入 `EruptWebSocketService`（`sendJsNotify`/`sendJsMessage`）推送前端 | `modules/erupt-websocket` |
| erupt-http/jdbc/file | 数据源注解，见 erupt-datasource.md | `modules/erupt-http` 等 |
| erupt-remote | 不写代码，但要配 `erupt.remote.secret-key`（凭据 AES 密钥，留空则首次启动随机生成写入 `.erupt/remote.key`，**多节点部署必须显式配同一值**）；另有 `max-sessions`（默认 20）、`idle-timeout-minutes`（默认 30）、`connect-timeout-seconds`（默认 5） | `modules/erupt-remote` |
| erupt-sso | 不写代码：「系统管理 → 单点登录」新增认证源，选供应商预设、贴客户端 ID / 密钥、把回调地址 `<erupt 地址>/erupt-api/sso/callback/<编码>` 登记到认证源控制台；编码保存后不可改。引入后 erupt-notice 多出飞书 / 钉钉 / 企业微信 / Slack 四个推送渠道，直接借用认证源凭据向登录过的用户推送 | `modules/erupt-sso`、`modules/erupt-notice` |
| erupt-comment | 不写代码：引入后所有模型默认可评论（`@Power(comment)` 默认 true），不该被讨论的日志 / 流水类模型加 `@Power(comment = false)`；@提及要有通知需同时引入 erupt-notice | `modules/erupt-comment` |
| erupt-ai-decision | 后台「AI 决策 → 决策模型」配好模型连接（TypeSafe Jev 或本地部署的开源 Laya），代码里 `Decisions.of(state).ask(Noul.of("是否紧急?")).yes(0.9)` 按概率分支；问题类型 `Noul`（是否）/ `Choice`（枚举选项，可实现 `Criteria` 自述规则）/ `Score`（有序等级），包 `xyz.erupt.decision` | `modules/erupt-ai-decision` |
| erupt-data-s3 | 附件上云两步：启动类标 `@EruptAttachmentUpload(S3AttachmentProxy.class)`，yml 配 `erupt.s3.*`（bucket / region / endpoint / path-style / access-key / secret-key / domain），全部附件转存 S3 / MinIO / OSS / COS / R2，附件域名由后端下发、`app.js` 不用改 | `modules/erupt-s3` |

**零代码模块**（加依赖重启即出现菜单，纯界面操作）：erupt-monitor / erupt-magic-api / erupt-designer / erupt-terminal / erupt-report / erupt-print / erupt-atlas / erupt-sso / erupt-comment。

`erupt-remote` 的两点运维前提：JPA 会新建 `e_remote_host` 与 `e_remote_host_user` 两张表；Nginx 反代必须为 `/erupt-remote` 转发 WebSocket upgrade，SFTP 上传走裸 body 流式写入，需调大 `client_max_body_size`。权限是两层：菜单权限决定能不能用远程功能，主机记录上的 Authorized Users 决定能连哪台（不勾选则仅超管可见）。
