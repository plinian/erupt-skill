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

- **用外部账号登录（飞书 / 钉钉 / 企业微信 / 微信 / Keycloak / Authing / Okta / Entra ID / GitHub 等）**：**零代码**，加依赖 `erupt-sso`（starter-all 已含），重启后在「系统管理 → 单点登录」新增认证源、选供应商预设、贴客户端 ID / 密钥，登录页自动出现按钮；回调地址 `<erupt 地址>/erupt-api/sso/callback/<编码>` 要登记到认证源控制台，编码保存后不可改。不要再让用户手写 OAuth 回调 → `modules/erupt-sso`、`advanced/auth`
- **LDAP / AD / 短信验证码 / 自有用户中心校验**：启动类标 `@EruptLogin(MyLoginProxy.class)`，实现 `LoginProxy.login()` 返回**库里真实存在**的 EruptUser（外部用户不存在时先建号）。账户状态 / 有效期 / IP 白名单 / 登录锁定 / MFA 的检查对密码、SSO、LoginProxy 三种登录统一生效，LoginProxy 无法绕过 → `advanced/auth`
- **双因素认证（MFA）**：内置 TOTP，用户在头像菜单自助绑定，无需开发；`erupt-app.mfa.enable: false` 可整体关闭；管理员在用户列表可「重置 MFA」。自写登录客户端要处理 `/erupt-api/login` 返回 `mfaRequired` 后再调 `/erupt-api/login-mfa` → `modules/erupt-upms/user`
- **修改 / 重置密码后该账号其他会话立即下线**，只保留发起修改的会话；用户可在头像菜单自助改头像与姓名（`LoginProxy.beforeUpdateProfile` 抛异常可否决）、锁屏
- **自定义接口挂菜单权限**：方法标 `@EruptMenuAuth("菜单code")`（`xyz.erupt.upms.annotation`）；`/erupt-api` 前缀内默认需登录，前缀外全公开 → `advanced/rest-api`
- **OpenAPI 免登录调用**：后台建应用拿 appid/secret，换 token 调数据接口 → `advanced/open-api`
- **附件上云**：S3 兼容存储（AWS S3 / MinIO / 阿里云 OSS / 腾讯云 COS / Cloudflare R2）**不用写代码**——加依赖 `erupt-data-s3`，启动类标 `@EruptAttachmentUpload(S3AttachmentProxy.class)`，`application.yml` 配 `erupt.s3.bucket / region / endpoint / path-style / access-key / secret-key`（MinIO 等自建服务 `path-style: true`）即可；附件访问域名由后端下发，`app.js` 的 `fileDomain` 留空 → `modules/erupt-s3`；其他存储才自己实现 `AttachmentProxy`（`xyz.erupt.annotation.fun`）注册为 @Component → `advanced/upload`

## 高频配置（application.yml，全量见 `guide/configuration`）

```yaml
erupt:
  init-method-enum: every          # 菜单每次启动幂等补插（新增实体重启即出现）
  redis-session: false             # 集群部署改 true（会话存 Redis）
  upms:
    expire-time-by-login: 100      # 登录 token 有效期（分钟）
    default-account: erupt
    default-password: erupt
    login-lock:                    # 登录锁定（默认开启）：同一账号 + IP 连续失败 max-failures 次锁 lock-minutes 分钟，验证码填错同样计数
      enable: true                 # 压测 / 自动化登录 / 共享出口 IP 受影响时调大阈值或关闭
      max-failures: 10
      lock-minutes: 10
erupt-app:
  verify-code-count: 2             # 登录失败 N 次出验证码（0=始终）
  water-mark: true                 # 页面水印
  mfa:
    enable: true                   # 双因素认证入口（用户自助绑定，不强制）
```

**IP 归属地格式**：归属地字符串为 `国家|省|市|ISP|国家码`。自己解析过这个字段的代码要按此格式处理。用户的 IP 白名单支持 IPv4 / IPv6 CIDR 网段。

> 完整用法与示例：**doc-map.md → `advanced/auth`、`modules/erupt-sso`、`modules/erupt-upms/user`、`advanced/open-api`、`modules/erupt-s3`、`advanced/upload`、`advanced/custom-login-page`、`guide/configuration`**。
