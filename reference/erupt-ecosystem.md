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
| erupt-websocket | WebSocket 支持 | 实时推送 |
| erupt-tpl | 模板引擎，自定义页面/弹窗（详见 erupt-tpl.md） | 自定义页面、大屏 |
| erupt-spring-boot-starter-all | 一键全家桶：starter + 上述常用插件 + AI | — |

## AI 家族

erupt-ai（LLM 接入与对话）、erupt-ai-rag（知识库 RAG）、erupt-ai-claw（自然语言直接操作后台）、erupt-ai-staff（数字员工）、erupt-ai-canvas（AI 生成视图页面）。

## 非 JPA 数据源适配

给任意数据后端套上 erupt CRUD 界面：erupt-data-mongodb / es / http / jdbc / ldap / redis / s3 / k8s / feishu / notion / file / memory。

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

**零代码模块**（加依赖重启即出现菜单，纯界面操作）：erupt-monitor / erupt-magic-api / erupt-designer / erupt-terminal / erupt-report / erupt-print。
