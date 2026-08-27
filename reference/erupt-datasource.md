# 动态数据源（非 JPA 数据也能生成 CRUD 界面）

> 已对照 erupt 发布版实测核实（基线版本统一记录在 SKILL.md「版本基线」）。适用场景：数据不在数据库里——来自 REST API、另一个数据库、本地文件、命令行输出、内存运行时——同样生成带搜索/排序/分页的管理界面，**不落库、每次实时读取**。

## 机制总览

模型类标注 `@EruptDataProcessor("处理器名")` 即切换数据源（不再是 JPA 实体，**不要加 @Entity/@Table**）；框架对返回的数据统一做搜索、排序、分页求值。菜单注册方式与普通实体完全相同。

**通用注意（实测踩过）**：
- 模型不继承 BaseModel 时必须自定义主键：`@Erupt(primaryKeyCol = "xxx")`，且该字段**必须标注 @EruptField**（不想显示则 `views = @View(title = "ID", show = false)`），否则启动报 `Primary key not found`
- 数据只读时加 `power = @Power(add = false, edit = false, delete = false)`；写操作默认抛只读错误

## 方式一：自定义数据服务（任意数据来源）

实现 `data()` 返回列表即可，搜索/排序/分页框架自动处理。适合：本机命令输出、聚合计算、任何 SDK。

```java
// 1. 数据服务：注册名 + 实现 data()
@Service
public class MyDataService extends EruptBeanDataService<MyModel> {

    public static final String NAME = "myData";

    static { DataProcessorManager.register(NAME, MyDataService.class); }

    @Override
    protected List<MyModel> data(EruptModel eruptModel, EruptQuery eruptQuery) {
        return fetchAnything();  // 每次查询实时调用；数据获取慢时自行加短缓存（volatile 字段 + 时间戳）
    }
    // 可选覆盖：conditionsPushedDown() 返回 true 表示 data() 已在源头按条件过滤，框架不再重复过滤
    // 可选覆盖：addData/editData/deleteData 支持写操作（默认只读）
}

// 2. 模型：普通类（非 @Entity），@EruptField 写法与实体一致
@Erupt(name = "我的数据", primaryKeyCol = "code",
        power = @Power(add = false, edit = false, delete = false))
@EruptDataProcessor(MyDataService.NAME)
@Getter
@Setter
public class MyModel {

    @EruptField(views = @View(title = "编码"), edit = @Edit(title = "编码", search = @Search))
    private String code;

    @EruptField(views = @View(title = "名称", sortable = true))
    private String name;
}
```

import：`xyz.erupt.core.service.EruptBeanDataService`、`xyz.erupt.core.invoke.DataProcessorManager`、`xyz.erupt.core.annotation.EruptDataProcessor`、`xyz.erupt.core.query.EruptQuery`、`xyz.erupt.core.view.EruptModel`。

## 方式二：现成数据源处理器（加依赖即用）

各模块（groupId `xyz.erupt`，版本同 erupt）自带处理器，模型上两个注解即可：

### HTTP —— 把 REST API 当数据源

依赖 `erupt-data-http`，处理器名 `"HTTP"`：

```java
@Erupt(name = "远程用户")
@EruptDataProcessor("HTTP")
@EruptHttp(
        value = "https://api.example.com/users",   // 基础 URL
        headers = {"Authorization: Bearer xxx"},   // 可选请求头
        queryMode = EruptHttp.QueryMode.LOCAL,     // LOCAL=拉全量内存过滤；REMOTE=分页条件透传给 API
        timeout = 10
)
@Getter
@Setter
public class RemoteUser { ... }
```

### JDBC —— 直连任意库任意表（跨库/遗留系统）

依赖 `erupt-data-jdbc`，处理器名 `"JDBC"`，字段名与表列名一致：

```java
@Erupt(name = "遗留订单")
@EruptDataProcessor("JDBC")
@EruptJdbc(value = "legacy_orders", datasource = "legacyDs")  // datasource 为 DataSource bean 名，空 = 默认数据源
@Getter
@Setter
public class LegacyOrder { ... }
```

### FILE —— 把 CSV/JSON/YAML/properties 文件当库用

依赖 `erupt-data-file`，处理器名 `"FILE"`：

```java
@Erupt(name = "功能开关")
@EruptDataProcessor("FILE")
@EruptFile(value = "config/features.csv")   // 格式自动推断；single = true 表示整个文件是一条记录（配置文件场景）
@Getter
@Setter
public class FeatureFlag { ... }
```

### 其他现成处理器名速查

| 依赖 | 处理器名 |
|---|---|
| erupt-data-memory | 继承 `EruptMemoryRepository<T>` 自建（进程内可写存储） |
| erupt-data-ldap | `"LDAP"` |
| erupt-data-es | `"ELASTICSEARCH"` |
| erupt-data-redis | `"REDIS"` |
| erupt-data-s3 | `"S3"` |
| erupt-data-k8s | `"KUBERNETES"` |
| erupt-data-notion | `"NOTION"` |
| erupt-data-feishu | `"FEISHU_BITABLE"` |

各自的配置注解在对应模块的 `annotation` 包下，用前读源码或官方文档核实属性。
