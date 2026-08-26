# Erupt TPL 自定义前端页面开发

TPL 用于在 Erupt 管理后台中放入完全自定义的 HTML 页面，有两类使用形态：

| 形态 | 效果 | 适用场景 |
|-----|------|---------|
| **独立菜单全页面** | 页面作为一个菜单项，占满整个内容区（iframe 承载） | 仪表盘、数据大屏、引导页、任意自定义界面 |
| **嵌入模型页面** | 页面嵌在某个 @Erupt 模型的弹窗 / 字段 / 视图中 | 行操作弹窗、表单字段、多视图 Tab、单元格查看 |

页面内可通过 Erupt REST API（见 `erupt-api.md`）读写数据，实现完整交互。

---

## 一、独立菜单全页面自定义（推荐入口）

### 方式 A：纯 HTML，零 Java 代码（首选）

访问 `/erupt-api/tpl/{path}` 时，若没有匹配的 `@TplAction`，erupt 会直接以 Native 引擎渲染 `resources/tpl/{path}` 文件。因此只需两步：

**1. 编写页面** `src/main/resources/tpl/dashboard.html`（纯 HTML/CSS/JS，写法完全自由）

**2. 注册菜单**：在 `Application.java` 的 `initMenus()` 中追加：

```java
// type 用字符串 "tpl"（即 EruptTplService.TPL 常量），value = tpl 目录下的文件名
menus.add(MetaMenu.createSimpleMenu("dashboard", "数据大屏", "dashboard.html", menus.get(0), 5, "tpl"));
```

模板项目已配置 `init-method-enum: every`（每次启动幂等补插菜单），**重启即出现在菜单栏**，页面自动占满内容区，实现全页面自定义效果。

Native 引擎特性：
- **零依赖**，不需要任何模板引擎 jar
- 无服务端模板变量，唯一支持的占位符是 `${base}`（渲染时替换为应用 contextPath，用于拼静态资源 URL）
- 页面数据全部靠 JS 调 `/erupt-api/...` 接口获取（token 见下文）

### 方式 B：@EruptTpl + @TplAction（需要服务端预渲染数据时）

```java
@Service   // 需注入其他 Bean 时必须是 Spring Bean；无注入需求可不加（erupt 会 new 实例）
@EruptTpl(engine = Tpl.Engine.FreeMarker)   // 类需在 @EruptScan 扫描包内
public class DashboardTpl {

    @Resource
    private EruptDao eruptDao;

    // value 同时是「URL 路径 / 菜单 value / 权限标识」三者；path 指定实际模板文件
    @TplAction(value = "dashboard", path = "/tpl/dashboard.html")
    public Map<String, Object> dashboard() {
        Map<String, Object> map = new HashMap<>();
        map.put("totalCount", eruptDao.lambdaQuery(Order.class).count());  // 模板中 ${totalCount}
        return map;   // 返回值即模板变量；无数据可返回 null 或声明 void
    }
}
```

菜单注册同方式 A，value 换成 `@TplAction` 的 value：

```java
menus.add(MetaMenu.createSimpleMenu("dashboard", "数据大屏", "dashboard", menus.get(0), 5, "tpl"));
```

> **依赖注意**：erupt-tpl 模块随 starter 自带（无需加依赖），但除 Native 外的模板引擎 jar 均为 optional。
> 使用 FreeMarker 需在 pom.xml 追加：
> ```xml
> <dependency>
>     <groupId>org.freemarker</groupId>
>     <artifactId>freemarker</artifactId>
> </dependency>
> ```
> （spring-boot-parent 已管理版本号）。**不加依赖就用 `Tpl.Engine.Native`**。

### 权限与常见坑

- TPL 页面按**菜单 value** 做权限校验：用户须拥有 value 等于该 tpl 路径的菜单才能访问（admin 默认全有）；403 说明菜单没注册或当前角色未分配
- 菜单 value 支持带参数：`dashboard.html?theme=dark`（参数会注入模板变量）
- 页面在 iframe 中渲染，样式与后台主框架天然隔离，可放心使用任意 CSS
- 菜单类型还有 `mtpl`（micro 模式，不用 iframe 直接挂载），高级场景才用，默认用 `tpl`

---

## 二、嵌入模型页面的触发位置

`@Tpl` 可用于以下位置：

| 位置 | 注解写法 | 渲染 URL |
|-----|---------|---------|
| 行操作弹窗 | `@RowOperation(type=Type.TPL, tpl=@Tpl(...))` | `/erupt-api/tpl/operation-tpl/{erupt}/{code}?ids=...` |
| 表单字段 | `@Edit(type=EditType.TPL, tplType=@Tpl(...))` | `/erupt-api/tpl/html-field/{erupt}/{field}` |
| 多视图 | `@Vis(type=Vis.Type.TPL, tplView=@Tpl(...))` | `/erupt-api/tpl/vis-tpl/{erupt}/{code}` |
| 表格单元格查看 | `@View(tpl=@Tpl(...))` | `/erupt-api/tpl/view-tpl/{erupt}/{field}/{id}` |
| 独立菜单页 | 见上文「独立菜单全页面自定义」 | `/erupt-api/tpl/{name}` |

---

## @Tpl 注解参数速查

```java
@Tpl(
    path      = "/tpl/my-page.html",       // 模板文件路径（相对 resources/）
    engine    = Tpl.Engine.Native,          // 见下方引擎列表
    openWay   = OpenWay.MODAL,             // MODAL（模态框）/ DRAWER（抽屉）
    width     = "900px",
    height    = "600px",
    tplHandler = MyHandler.class,          // 可选，服务端数据注入
    params    = {"key1=val1"}              // 传给 tplHandler 的静态参数
)
```

**模板引擎**（除 Native 外均需自行添加对应引擎依赖，jar 不存在时该引擎不可用）：

| Engine | 变量语法 | 依赖 | 适用场景 |
|--------|---------|------|---------|
| `Native` | 仅 `${base}` 占位符 | 无（默认可用） | 纯前端页面，全靠 JS 调 API |
| `FreeMarker` | `${varName}`、`<#list>` | `org.freemarker:freemarker` | 需要服务端预渲染数据（默认引擎） |
| `Thymeleaf` | `th:text="${varName}"` | `org.thymeleaf:thymeleaf` | Spring 生态熟悉者 |
| `Velocity` | `$varName`、`#foreach` | `org.apache.velocity:velocity-engine-core` | 简单场景 |
| `Beetl` / `Enjoy` | 各自语法 | 对应 jar | 国产引擎偏好者 |

---

## 模板自动注入变量

使用模板引擎（非 Native）时，以下变量无需 TplHandler 自动可用：

| 变量名 | 类型 | 说明 |
|-------|------|------|
| `base` | String | 应用根路径（`request.contextPath`），用于拼接静态资源 URL |
| `request` | HttpServletRequest | HTTP 请求对象 |
| `rows` | `List<Map>` | 行操作选中的多行数据（行操作场景） |
| `row` | `Map` | 单行数据（`@View` 单元格场景） |

---

## TplHandler — 服务端数据注入

```java
// 在 @Tpl 注解中指定：tplHandler = MyTplHandler.class
@Component
public class MyTplHandler implements Tpl.TplHandler {
    @Resource
    private MyService myService;

    @Override
    public void bindTplData(Map<String, Object> binding, String[] params) {
        // binding 中已有 rows/row 等自动注入变量
        // params 来自 @Tpl(params={"key=val"})
        binding.put("chartData", myService.getChartData());
    }
}
```

在 FreeMarker 模板中使用：`${chartData}`

---

## 可用前端 UI 框架

erupt 提供了打包好前端 UI 框架静态资源的可选模块（离线可用），在 pom.xml 引入后，资源路径**必须以 `${base}/` 开头**（页面 URL 在 `/erupt-api/tpl/` 下，相对路径会 404；`${base}` 在所有引擎含 Native 中都会被替换）：

### Element Plus（Vue 3，推荐）

```xml
<dependency>
    <groupId>xyz.erupt</groupId>
    <artifactId>erupt-tpl-ui.element-plus</artifactId>
    <version>${erupt.version}</version>
</dependency>
```

```html
<link href="${base}/element-plus/element.min.css" rel="stylesheet">
<script src="${base}/element-plus/vue3.js"></script>
<script src="${base}/element-plus/element.min.js"></script>
<script src="${base}/element-plus/axios.min.js"></script>
```

### Ant Design Vue（Vue 2）— artifact：`erupt-tpl-ui.ant-design`

```html
<link href="${base}/ant-design/antd.min.css" rel="stylesheet">
<script src="${base}/ant-design/vue.min.js"></script>
<script src="${base}/ant-design/moment.min.js"></script>
<script src="${base}/ant-design/antd.min.js"></script>
<script src="${base}/ant-design/axios.min.js"></script>
```

### Element UI（Vue 2）— artifact：`erupt-tpl-ui.element-ui`

```html
<link href="${base}/element/element.min.css" rel="stylesheet">
<script src="${base}/element/vue.min.js"></script>
<script src="${base}/element/element.min.js"></script>
<script src="${base}/element/axios.min.js"></script>
```

> 也可以不引任何框架，手写 HTML/CSS/JS（配合 `fetch` 调 API），或在有网环境用公共 CDN。

---

## Token 获取（页面内调用 API）

TPL 页面 URL 中自动携带 `_token` 参数，直接读取：

```javascript
const token = new URLSearchParams(location.search).get('_token');
```

所有 API 调用将此 token 放入 Header：

```javascript
axios.defaults.headers.common['token'] = token;
// 或原生 fetch
fetch('/erupt-api/...', { headers: { token } });
```

---

## 完整示例：全页面数据仪表盘（零 Java 代码）

**场景**：为订单系统增加一个「数据看板」菜单页，展示统计卡片 + 分页表格。

### 1. 页面文件 `src/main/resources/tpl/board.html`

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <link href="${base}/element-plus/element.min.css" rel="stylesheet">
  <style>body { margin: 0; padding: 16px; background: #f5f7fa; }</style>
</head>
<body>
<div id="app">
  <el-row :gutter="12">
    <el-col :span="8"><el-card>订单总数：{{ total }}</el-card></el-col>
  </el-row>

  <el-input v-model="keyword" placeholder="搜索订单号..." style="width:220px;margin:12px 0"
            @keyup.enter="load(1)" clearable @clear="load(1)"/>
  <el-button type="primary" @click="load(1)">查询</el-button>

  <el-table :data="list" stripe border>
    <!-- prop 用 Java 字段名（不是数据库列名） -->
    <el-table-column prop="orderNo" label="订单号"/>
    <el-table-column prop="amount"  label="金额"/>
    <el-table-column prop="status"  label="状态"/>
  </el-table>

  <el-pagination style="margin-top:12px"
    :total="total" :page-size="pageSize" :current-page="pageIndex"
    layout="total, prev, pager, next" @current-change="load"/>
</div>

<script src="${base}/element-plus/vue3.js"></script>
<script src="${base}/element-plus/element.min.js"></script>
<script src="${base}/element-plus/axios.min.js"></script>
<script>
const token = new URLSearchParams(location.search).get('_token');
axios.defaults.headers.common['token'] = token;

Vue.createApp({
  data: () => ({ list: [], total: 0, pageIndex: 1, pageSize: 20, keyword: '' }),
  mounted() { this.load(1); },
  methods: {
    async load(page) {
      this.pageIndex = page;
      // URL 中的 Order = @Erupt 类简名，condition.key = Java 字段名
      const { data } = await axios.post('/erupt-api/data/table/Order', {
        pageIndex: this.pageIndex,
        pageSize:  this.pageSize,
        condition: this.keyword
          ? [{ key: 'orderNo', value: this.keyword, conditionType: 'LIKE' }]
          : []
      });
      this.list  = data.list;
      this.total = data.total;
    }
  }
}).use(ElementPlus).mount('#app');
</script>
</body>
</html>
```

### 2. pom.xml 加 UI 资源依赖（见上文 Element Plus 段）

### 3. 菜单注册（`Application.java` 的 `initMenus()`）

```java
menus.add(MetaMenu.createSimpleMenu("board", "数据看板", "board.html", menus.get(0), 5, "tpl"));
```

重启后菜单栏出现「数据看板」，点击即全页面展示。

---

## 嵌入模型页面示例（多视图 Tab）

```java
@Erupt(
    name = "订单管理",
    vis = @Vis(
        title = "自定义视图",
        type = Vis.Type.TPL,
        tplView = @Tpl(path = "/tpl/order-view.html", engine = Tpl.Engine.Native,
                       width = "100%", height = "100%")
    )
)
@Entity
public class Order { ... }
```

模板写法与上例相同（token、API 调用、`${base}` 资源引用均一致）。

---

## 生成自定义页面的流程

1. **选择形态** — 独立整页（仪表盘/大屏）→ 纯 HTML + 菜单注册（方式 A）；附属在某模型 → `@Vis(type=TPL)` 或 `@RowOperation(type=TPL)`；需服务端预渲染 → 方式 B（记得加引擎依赖）
2. **确认模型字段** — 表格列 `prop` 和 condition `key` 用 `@EruptField` 的 Java 字段名（不是列名）
3. **选择 UI 框架** — 默认推荐 Element Plus（需在 pom 加 `erupt-tpl-ui.element-plus`）；简单页面可手写零依赖
4. **编写模板** — token 从 `_token` URL 参数取；静态资源用 `${base}/` 前缀；API 路径 `{erupt}` = 类简名
5. **验证** — `compile.sh` 编译通过 → 重启 → 检查菜单出现、页面无 403/404、接口有数据

---

## conditionType 速查

| 值 | 含义 |
|----|------|
| `EQ` | 等于 |
| `LIKE` | 模糊匹配 |
| `GT` / `LT` | 大于 / 小于 |
| `GTE` / `LTE` | 大于等于 / 小于等于 |
| `IN` | IN 查询（value 为数组） |
| `NOT_NULL` | 非空 |
