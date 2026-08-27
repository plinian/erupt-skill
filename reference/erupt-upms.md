# 用户、数据权限、登录集成与配置速查

> 已对照 erupt 发布版实测核实（基线版本统一记录在 SKILL.md「版本基线」）。覆盖：业务代码获取当前用户、行级数据权限、SSO/LDAP 登录对接、自定义接口挂权限、OpenAPI、常用配置项。

## 获取当前登录用户（业务代码标准姿势）

```java
@Resource
private EruptUserService eruptUserService;   // xyz.erupt.upms.service.EruptUserService

Long uid = eruptUserService.getCurrentUid();                  // 当前用户 ID
String account = eruptUserService.getCurrentAccount();        // 账号
EruptUser user = eruptUserService.getCurrentEruptUser();      // 完整对象（含 getEruptOrg()/getEruptPost()/getIsAdmin()）
MetaUserinfo info = eruptUserService.getSimpleUserInfo();     // 轻量缓存版，高频调用首选
```

## 行级数据权限：Looker 基类（继承即生效）

三个 `@MappedSuperclass` 基类内置 `beforeFetch` 过滤，实体换个继承就有数据权限，**超级管理员自动绕过**：

| 基类（`xyz.erupt.upms.looker`） | 过滤规则 | 典型场景 |
|---|---|---|
| `LookerSelf` | 只能看自己创建的数据 | 我的工单、我的申请 |
| `LookerOrg` | 只能看本组织创建的数据（用户须绑定组织） | 部门数据隔离 |
| `LookerPostLevel` | 自己的 + 本组织内职级低于自己的人创建的（用户须绑定职位） | 上级看下级 |

```java
@Erupt(name = "我的工单")
@Table(name = "t_ticket")
@Entity
@Getter
@Setter
public class Ticket extends LookerSelf {   // 换成 LookerOrg / LookerPostLevel 即切换规则
    @EruptField(views = @View(title = "标题"), edit = @Edit(title = "标题", notNull = true))
    private String title;
}
```

基类自带 `createUser`（关联操作人）/`createTime` 等审计字段并自动填充，**不要再继承 MetaModel 系列**。

自定义过滤条件时用 DataProxy 的 `beforeFetch` 返回 HQL 条件字符串（值取自 `EruptUserService`，不要拼接任何来自请求的输入）：

```java
@Override
public String beforeFetch(List<Condition> conditions) {
    if (eruptUserService.getCurrentEruptUser().getIsAdmin()) return null;   // null = 不加条件
    return "Ticket.createUser.id = " + eruptUserService.getCurrentUid();
}
```

## SSO / LDAP / 自定义登录：@EruptLogin + LoginProxy

```java
@EruptLogin(MyLoginProxy.class)   // 标注在 Spring Boot 启动类上
@SpringBootApplication
@EruptScan
@EntityScan
public class Application { ... }

@Component
public class MyLoginProxy implements LoginProxy {

    @Override
    public EruptUser login(String account, String pwd) {
        // 调 LDAP / OAuth / 内部账号系统校验；失败抛异常（异常消息会展示给用户）
        // 返回 EruptUser（框架据此建立会话）
    }

    // 可选钩子：loginSuccess(user, token) / logout(token) / beforeChangePwd / afterChangePwd
}
```

> 密码默认传输加密（三重 Base64），对接外部系统需拿明文时框架已在调用 login 前解码；`erupt-app.pwd-transfer-encrypt: false` 可整体关闭传输加密（不推荐）。

## 自定义 @RestController 挂 erupt 权限

- 路径在 `/erupt-api` 前缀下的接口默认要求登录 token；前缀外的路径完全公开（适合第三方回调）
- 需要绑定**菜单权限**（用户有某菜单才能调用）时用 `@EruptMenuAuth("菜单code")`（`xyz.erupt.upms.annotation.EruptMenuAuth`）标注在方法上
- 更细的路由校验用 `@EruptRouter`（verifyType = LOGIN / MENU / ERUPT），一般用不到，见 `xyz.erupt.core.annotation.EruptRouter`

## OpenAPI：外部系统免登录调用

1. 后台「Open API」菜单新增应用 → 得到 appid / secret（绑定一个用户，Token 继承该用户的全部权限）
2. 换取 token（同 appid 再次换取会使旧 token 失效）：`GET /erupt-api/open-api/create-token?appid=xxx&secret=xxx`
3. 携带 `token` 请求头调用任意数据接口（见 erupt-api.md）

## 附件上传自定义（云存储）

实现 `AttachmentProxy`（`xyz.erupt.annotation.fun`）并注册为 @Component，即接管所有附件上传：

```java
@Component
public class OssAttachmentProxy implements AttachmentProxy {
    @Override
    public String upLoad(InputStream inputStream, String path) { /* 传 OSS/S3，返回存储路径 */ }
    @Override
    public String fileDomain() { return "https://cdn.example.com"; }   // 前端访问附件的域名
    @Override
    public boolean isLocalSave() { return false; }                     // 是否同时留本地副本
}
```

## 常用配置项速查（application.yml）

```yaml
erupt:
  upload-path: /opt/erupt-attachment   # 附件存储目录
  csrf-inspect: true                   # CSRF 防护
  init-method-enum: every              # 菜单初始化策略（every=每次启动幂等补插）
  redis-session: false                 # true 时会话存 Redis（集群部署必开，需引 spring-boot-starter-data-redis）
  upms:
    expire-time-by-login: 100          # 登录 token 有效期（分钟）
    default-account: erupt             # 初始超管账号
    default-password: erupt
  security:
    record-operate-log: true           # 自动记录操作日志（后台「操作日志」菜单可查）

erupt-app:
  pwd-transfer-encrypt: true           # 登录密码传输加密
  verify-code-count: 2                 # 登录失败 N 次后出验证码（0=始终）
  water-mark: true                     # 页面水印（内容默认当前用户）
  reset-pwd-prompt: false              # 首次登录是否强制改密码
```
