# 官方文档地图（细节的单一事实源）

本 skill 的本地 reference 只保留**决策规则**和**实测踩过的坑**——这两样官方文档没有。API 全量属性、完整示例、逐字段说明一律以 erupt 官方文档为准（随 erupt 发版更新，不在本地留快照以免漂移）。

## 怎么读官方文档

**官网 https://docs.erupt.xyz 是 VitePress 静态站点（SSG），正文直接在 HTML 里，WebFetch 即可完整抓取**，优先访问官网：

```
基址：https://docs.erupt.xyz/en/<相对路径>
```

注意：语言前缀 `en`/`zh` 必须带（根路径下没有页面），路径末尾**不加 `.html`**。中文版把 `/en/` 换成 `/zh/`。下表给相对路径。

兜底（官网不可达时）：读 GitHub raw markdown 源文件 `https://raw.githubusercontent.com/erupts/erupt-docs/main/en/<相对路径>.md`。

## 相对路径速查

### 核心机制（advanced/）
| 主题 | 相对路径 |
|---|---|
| 自定义数据源 IEruptDataService / EruptBeanDataService | `advanced/custom-datasource` |
| DataProxy 总览与全部钩子 | `advanced/data-proxy` |
| 列表加载 DataProxy（beforeFetch/afterFetch/表格钩子） | `advanced/data-proxy-table` |
| 列表底部合计行 | `advanced/extra-row` |
| Excel 导入导出钩子 | `advanced/data-proxy-excel` |
| CRUD 拦截钩子 | `advanced/data-proxy-crud` |
| 校验钩子 | `advanced/data-proxy-validate` |
| FORM 单行表单视图 | `advanced/form-view` |
| 权限与数据权限 | `advanced/auth` |
| OpenAPI 对外接口 | `advanced/open-api` |
| 自定义 REST 接口挂权限 | `advanced/rest-api` |
| 附件上传 / 云存储代理 | `advanced/upload` |
| Spring 事件监听 | `advanced/event-listener` |
| WebSocket 前端推送 | `advanced/frontend-notify` |
| 自定义登录页 / SSO | `advanced/custom-login-page` |
| 虚拟字段 | `advanced/virtual-field` |
| 软删除 | `advanced/soft-delete` |
| EruptDao 用法 | `advanced/erupt-dao`、`advanced/erupt-dao-lambda` |

### 注解（annotation/）
`annotation/erupt`、`annotation/erupt-field`、`annotation/edit`、`annotation/view`、`annotation/power`、`annotation/search`、`annotation/filter`、`annotation/tree`、`annotation/link-tree`、`annotation/drill`、`annotation/row-operation`、`annotation/on-change`、`annotation/dynamic`、`annotation/drag-sort`、`annotation/layout`、`annotation/form-steps`（分步表单）、`annotation/order-by`、`annotation/vis`（卡片/看板/甘特/日历）

### 字段类型（field-types/）
每种 EditType 一页，总览在 `field-types/index`；具体如 `field-types/choice`、`field-types/reference-table`、`field-types/attachment`、`field-types/tab-table-add`、`field-types/button`、`field-types/textarea`（含 @提及）、`field-types/auto-complete`、`field-types/boolean`（`@BoolType(type)` 开关 / 单选）、`field-types/icon`（图标选择）、`field-types/key-value`（键值对）、`field-types/transfer`（多对多穿梭框）、`field-types/multi-choice`（含穿梭框模式）等。

### 模块用法（modules/）
每个模块一页，总览在 `modules/index`；常用：`modules/erupt-job`、`modules/erupt-notice`（含借用 SSO 认证源的飞书 / 钉钉 / 企微 / Slack 推送渠道）、`modules/erupt-websocket`、`modules/erupt-http`、`modules/erupt-jdbc`、`modules/erupt-file`、`modules/erupt-upms`、`modules/erupt-upms/user`（登录校验链、MFA、登录锁定、锁屏）、`modules/erupt-sso`（单点登录、供应商预设）、`modules/erupt-comment`（记录评论）、`modules/erupt-ai-decision`（AI 决策 Java API）、`modules/erupt-s3`（S3 数据源 + `S3AttachmentProxy` 附件上云）、`modules/erupt-dingtalk`（钉钉多维表数据源）、`modules/erupt-airtable`（Airtable 数据源）、`modules/erupt-report/index`、`modules/erupt-print`、`modules/erupt-remote`（VNC/SSH 远程主机 + SFTP）、`modules/erupt-atlas`（模型图谱）、`modules/erupt-generator`（从数据库表导入生成实体类）。

### 配置 / 上手 / 界面
`guide/configuration`（全部后端配置项）、`guide/config-frontend`（`app.js` 全部前端配置：Logo、favicon、皮肤、菜单模式、登录页布局、表单面板、PWA）、`guide/ui`（界面能力总览：表单面板、登录页布局、皮肤、锁屏、PWA）、`guide/pwa`（安装为桌面应用）、`guide/getting-started`、`guide/database`（换数据库）、`guide/upgrade`（各版本升级指南与破坏性变更）、`guide/changelog`（更新日志）。

> 表里没列到的页面，先拉 `modules/index`、`advanced/index`、`annotation/index` 三个目录页找到相对路径，再拉具体页。
