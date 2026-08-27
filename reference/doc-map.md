# 官方文档地图（细节的单一事实源）

本 skill 的本地 reference 只保留**决策规则**和**实测踩过的坑**——这两样官方文档没有。API 全量属性、完整示例、逐字段说明一律以 erupt 官方文档为准（随 erupt 发版更新，不在本地留快照以免漂移）。

## 怎么读官方文档

**官网 https://docs.erupt.xyz 是 JS 渲染的，WebFetch / curl 抓不到正文**（实测只返回导航碎片）。必须读 GitHub 上的 raw markdown 源文件：

```
基址：https://raw.githubusercontent.com/erupts/erupt-docs/main/en/<相对路径>.md
```

用 WebFetch 拉上述 URL 即可拿到完整正文。下表给相对路径（去掉 `.md`）。中文版把 `/en/` 换成 `/zh/`。

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
`annotation/erupt`、`annotation/erupt-field`、`annotation/edit`、`annotation/view`、`annotation/power`、`annotation/search`、`annotation/filter`、`annotation/tree`、`annotation/link-tree`、`annotation/drill`、`annotation/row-operation`、`annotation/on-change`、`annotation/dynamic`、`annotation/drag-sort`、`annotation/layout`、`annotation/order-by`、`annotation/vis`（卡片/看板/甘特/日历）

### 字段类型（field-types/）
每种 EditType 一页，总览在 `field-types/index`；具体如 `field-types/choice`、`field-types/reference-table`、`field-types/attachment`、`field-types/tab-table-add`、`field-types/button` 等。

### 模块用法（modules/）
每个模块一页，总览在 `modules/index`；常用：`modules/erupt-job`、`modules/erupt-notice`、`modules/erupt-websocket`、`modules/erupt-http`、`modules/erupt-jdbc`、`modules/erupt-file`、`modules/erupt-upms`、`modules/erupt-report/index`、`modules/erupt-print`。

### 配置 / 上手
`guide/configuration`（全部配置项）、`guide/getting-started`、`guide/database`（换数据库）。

> 表里没列到的页面，先拉 `modules/index`、`advanced/index`、`annotation/index` 三个目录页找到相对路径，再拉具体页。
