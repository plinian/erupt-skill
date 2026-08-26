# 开发可复用的 erupt 功能模块

> 基于 erupt 2.1.0 实测核实。适用场景：要做的不是一个"应用"，而是一个可发布为 jar、任何 erupt 应用加依赖即用的**功能模块**（如 erupt-ai、erupt-job；完整范例见 erupt-wx）。与应用模式的区别：模块自带菜单注册、依赖用 provided、demo 放 test 源集。

## 项目骨架

```
erupt-xxx/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/xyz/erupt/xxx/
    │   │   ├── EruptXxxAutoConfiguration.java   # 模块入口：EruptModule + 菜单注册
    │   │   ├── config/                          # @ConfigurationProperties("erupt.xxx")
    │   │   ├── model/                           # @Erupt 实体 + 弹窗表单类
    │   │   ├── proxy/                           # DataProxy 实现
    │   │   ├── handler/                         # OperationHandler / ChoiceFetchHandler
    │   │   └── controller/                      # 自定义 REST（可选）
    │   └── resources/META-INF/spring/
    │       └── org.springframework.boot.autoconfigure.AutoConfiguration.imports  # 一行：入口类全名
    └── test/
        ├── java/.../demo/XxxDemoApplication.java   # demo 启动类（不进 jar）
        └── resources/application.yml               # H2 配置
```

## pom 要点

```xml
<parent>spring-boot-starter-parent</parent>   <!-- 与目标 erupt 版本的 Spring Boot 对齐 -->

<dependencies>
    <!-- erupt 依赖用 provided：宿主应用必然自带，避免版本冲突 -->
    <dependency>
        <groupId>xyz.erupt</groupId><artifactId>erupt-upms</artifactId>
        <version>${erupt.version}</version><scope>provided</scope>
    </dependency>
    <!-- demo 依赖用 test：provided 依赖在 test classpath 可见，天然凑齐运行环境 -->
    <dependency>
        <groupId>xyz.erupt</groupId><artifactId>erupt-spring-boot-starter</artifactId>
        <version>${erupt.version}</version><scope>test</scope>
    </dependency>
    <dependency>
        <groupId>com.h2database</groupId><artifactId>h2</artifactId><scope>test</scope>
    </dependency>
</dependencies>

<build><plugins>
    <!-- lombok 处理器显式声明（JDK 23+ 必需），同应用模板 -->
    <!-- 库工程禁用 repackage，spring-boot 插件仅用于 test-run -->
    <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <executions><execution><id>repackage</id><phase>none</phase></execution></executions>
    </plugin>
</plugins></build>
```

demo 启动：`mvn spring-boot:test-run`（Spring Boot 3.1+，自动发现 test 源集里的 @SpringBootApplication）。

## 模块入口类

```java
@Configuration
@ComponentScan
@EruptScan        // 扫描本包 @Erupt 类
@EntityScan       // 扫描本包 JPA 实体
public class EruptXxxAutoConfiguration implements EruptModule {

    static { EruptModuleInvoke.addEruptModule(EruptXxxAutoConfiguration.class); }

    @Override
    public ModuleInfo info() { return ModuleInfo.builder().name("erupt-xxx").build(); }

    @Override
    public List<MetaMenu> initMenus() {
        List<MetaMenu> menus = new ArrayList<>();
        menus.add(MetaMenu.createRootMenu("$xxx", "模块名", "fa fa-cube", 30));
        menus.add(MetaMenu.createEruptClassMenu(MyEntity.class, menus.get(0), 10));
        // 隐藏菜单（如仅供 Drill 下钻的页面）：注册以获得权限，但不显示
        menus.add(MetaMenu.createEruptClassMenu(MyLog.class, menus.get(0), 20, MenuStatus.HIDE));
        return menus;
    }
}
```

- `MenuStatus` 位于 `xyz.erupt.core.constant`
- 宿主应用配置 `erupt.init-method-enum: every` 时每次启动幂等补插菜单

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
