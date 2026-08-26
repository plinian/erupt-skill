# 开发可复用的 erupt 功能模块

> 已对照 erupt 发布版实测核实（基线版本统一记录在 SKILL.md「版本基线」）。适用场景：要做的不是一个"应用"，而是可发布为 jar、任何 erupt 应用加依赖即用的**功能模块**（如 erupt-ai、erupt-job；完整可运行范例见 erupt-wx 仓库）。

## 与应用（template/）的关系：同一套机制，只差打包形态

实体注解、DataProxy、`EruptModule` + `initMenus()` 菜单注册、H2 默认库——模块与应用**完全一样**，template 应用里的一切写法可直接沿用。差异只有三处：

| | 应用（template/） | 功能模块 |
|---|---|---|
| erupt 依赖 scope | compile（默认） | **provided**（宿主必然自带，不向使用方传递） |
| spring-boot-maven-plugin | 默认 repackage，打可执行 jar | **禁用 repackage**，打普通库 jar |
| 入口注册 | `@SpringBootApplication` 启动类自身实现 EruptModule | 入口类写进 **AutoConfiguration.imports**，由宿主自动装配 |

> ⚠️ 反向同样成立：给用户生成**普通应用**时严禁套用本文的 provided / 禁 repackage，否则应用运行时缺 erupt 依赖、也打不出可执行 jar。应用一律照 template/ 原样。

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
        ├── java/.../demo/XxxDemoApplication.java   # demo 启动类（不进 jar），普通
        │                                           # @SpringBootApplication + @EruptScan + @EntityScan，同 template
        └── resources/application.yml               # H2 配置，同 template
```

## pom：在 template/pom.xml 基础上只改两处

properties（erupt.version 等）、lombok 依赖与 maven-compiler-plugin 的 annotationProcessorPaths、H2（runtime）**全部与 template/pom.xml 保持一致，直接复制，不要重新发明**。仅以下两处不同：

```xml
<!-- 差异 1：erupt 依赖加 provided（starter 含 core/jpa/upms/security/web 完整前后端链路） -->
<dependency>
    <groupId>xyz.erupt</groupId>
    <artifactId>erupt-spring-boot-starter</artifactId>
    <version>${erupt.version}</version>
    <scope>provided</scope>
</dependency>

<!-- 差异 2：禁用 repackage 打库 jar（插件保留，spring-boot:test-run 跑 demo 仍需要它） -->
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>repackage</id>
            <phase>none</phase>
        </execution>
    </executions>
</plugin>
```

第三处差异不在 pom：新增 `AutoConfiguration.imports` 文件（见下节）。

demo 启动：`mvn spring-boot:test-run`（Spring Boot 3.1+，自动发现 test 源集里的 @SpringBootApplication；provided 与 runtime 依赖在 test classpath 均可见，demo 无需额外依赖）。

## 模块入口类

与 template 的 `Application.java` 是**同一机制**（实现 EruptModule + initMenus），仅两点不同：去掉 `main` 方法与 `@SpringBootApplication` 改为 `@Configuration`；并在 `resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` 中写一行入口类全名，由宿主应用自动装配。

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
        // 树形实体（@Erupt 带 tree 配置）需指定 TREE 类型，同 template：
        // menus.add(MetaMenu.createEruptClassMenu(MyTree.class, menus.get(0), 15, MenuTypeEnum.TREE));
        // 自定义整页 TPL 页面，同 template：
        // menus.add(MetaMenu.createSimpleMenu("dashboard", "数据大屏", "dashboard.html", menus.get(0), 5, "tpl"));
        // 隐藏菜单（如仅供 Drill 下钻的页面）：注册以获得权限，但不显示
        menus.add(MetaMenu.createEruptClassMenu(MyLog.class, menus.get(0), 20, MenuStatus.HIDE));
        return menus;
    }
}
```

- `MenuStatus`、`MenuTypeEnum` 均位于 `xyz.erupt.core.constant`
- 宿主应用配置 `erupt.init-method-enum: every` 时每次启动幂等补插菜单

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
