# 动态数据源（非 JPA 数据也能生成 CRUD 界面）

数据不在数据库里——REST API、另一个库、本地文件、命令行输出、内存运行时——也能生成带搜索/排序/分页的管理界面，**不落库、每次实时读取**。模型标注 `@EruptDataProcessor("处理器名")` 切换数据源，**不加 @Entity/@Table**，菜单注册与普通实体相同。

## 实测坑（官方文档没有，务必遵守）

- 模型不继承 BaseModel 时必须 `@Erupt(primaryKeyCol = "xxx")`，且该字段**必须标注 @EruptField**（不显示则 `views = @View(show = false)`），否则启动报 `Primary key not found`
- 数据只读加 `power = @Power(add = false, edit = false, delete = false)`；写操作默认抛只读错误

## 方式一：自定义数据服务（任意来源）

实现 `data()` 返回列表，搜索/排序/分页框架自动处理（mac-admin 实战验证过的最小骨架）：

```java
@Service
public class MyDataService extends EruptBeanDataService<MyModel> {
    public static final String NAME = "myData";
    static { DataProcessorManager.register(NAME, MyDataService.class); }

    @Override
    protected List<MyModel> data(EruptModel eruptModel, EruptQuery eruptQuery) {
        return fetchAnything();   // 每次查询实时调用；慢则自行加短缓存（volatile 字段 + 时间戳）
    }
    // 可选：conditionsPushedDown() 返回 true 表示 data() 已在源头过滤；addData/editData/deleteData 支持写
}
```

模型侧：普通类 + `@EruptDataProcessor(MyDataService.NAME)`，`@EruptField` 写法与实体一致。
import：`xyz.erupt.core.service.EruptBeanDataService`、`xyz.erupt.core.invoke.DataProcessorManager`、`xyz.erupt.core.annotation.EruptDataProcessor`、`xyz.erupt.core.query.EruptQuery`、`xyz.erupt.core.view.EruptModel`。

## 方式二：现成数据源处理器（加依赖 + 两个注解）

各 `erupt-data-*` 模块自带处理器，处理器名如下；配置注解（`@EruptHttp`/`@EruptJdbc`/`@EruptFile` 等）与用法见对应模块文档。

| 依赖 | 处理器名 | 依赖 | 处理器名 |
|---|---|---|---|
| erupt-data-http | `"HTTP"` | erupt-data-jdbc | `"JDBC"` |
| erupt-data-file | `"FILE"` | erupt-data-memory | 继承 `EruptMemoryRepository<T>` |
| erupt-data-ldap | `"LDAP"` | erupt-data-es | `"ELASTICSEARCH"` |
| erupt-data-redis | `"REDIS"` | erupt-data-s3 | `"S3"` |
| erupt-data-k8s | `"KUBERNETES"` | erupt-data-notion | `"NOTION"` |
| erupt-data-feishu | `"FEISHU_BITABLE"` | | |

> 完整机制、IEruptDataService 全部方法、各处理器配置：**doc-map.md → `advanced/custom-datasource` 与 `modules/erupt-http`、`modules/erupt-jdbc`、`modules/erupt-file` 等**。
