# 用户、数据权限、登录集成（决策速查）

高频需求的最短路径与选型；完整 API 与示例见文末 doc-map 指向。

## 获取当前登录用户

```java
@Resource private EruptUserService eruptUserService;   // xyz.erupt.upms.service.EruptUserService

eruptUserService.getCurrentUid();          // 当前用户 ID
eruptUserService.getCurrentAccount();      // 账号
eruptUserService.getCurrentEruptUser();    // 完整对象（getEruptOrg()/getEruptPost()/getIsAdmin()）
eruptUserService.getSimpleUserInfo();      // 轻量缓存版，高频调用首选
```

## 行级数据权限：Looker 基类（继承即生效，超管自动绕过）

"每个人只能看到自己的数据"这类需求，**换个继承基类**即可，别手写 SQL 条件：

| 基类（`xyz.erupt.upms.looker`） | 规则 | 场景 |
|---|---|---|
| `LookerSelf` | 只看自己创建的 | 我的工单/申请 |
| `LookerOrg` | 只看本组织创建的（用户须绑组织） | 部门数据隔离 |
| `LookerPostLevel` | 自己的 + 本组织内职级更低者创建的（用户须绑职位） | 上级看下级 |

**坑**：这些基类自带 `createUser`/`createTime` 审计字段并自动填充，**不要再叠加继承 MetaModel 系列**。自定义过滤条件时用 DataProxy 的 `beforeFetch` 返回 HQL 字符串，**值只能取自服务端上下文（当前用户），严禁拼接请求输入**。

## 需要展开细节时（一句话 + 指向）

- **SSO/LDAP 登录**：启动类标 `@EruptLogin(MyLoginProxy.class)`，实现 `LoginProxy.login()` 返回 EruptUser → `advanced/custom-login-page`、`advanced/auth`
- **自定义接口挂菜单权限**：方法标 `@EruptMenuAuth("菜单code")`（`xyz.erupt.upms.annotation`）；`/erupt-api` 前缀内默认需登录，前缀外全公开 → `advanced/rest-api`
- **OpenAPI 免登录调用**：后台建应用拿 appid/secret，换 token 调数据接口 → `advanced/open-api`
- **附件上云**：实现 `AttachmentProxy`（`xyz.erupt.annotation.fun`）注册为 @Component → `advanced/upload`

## 高频配置（application.yml，全量见 `guide/configuration`）

```yaml
erupt:
  init-method-enum: every          # 菜单每次启动幂等补插（新增实体重启即出现）
  redis-session: false             # 集群部署改 true（会话存 Redis）
  upms:
    expire-time-by-login: 100      # 登录 token 有效期（分钟）
    default-account: erupt
    default-password: erupt
erupt-app:
  verify-code-count: 2             # 登录失败 N 次出验证码（0=始终）
  water-mark: true                 # 页面水印
```

> 完整用法与示例：**doc-map.md → `advanced/auth`、`advanced/open-api`、`advanced/upload`、`advanced/custom-login-page`、`guide/configuration`**。
