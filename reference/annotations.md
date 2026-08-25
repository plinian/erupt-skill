# Erupt 实体生成规范（速查）

生成实体类时严格遵循本文档。本文档基于 erupt 2.0.4 编写并验证（实际生成时版本追 Maven 最新 release，用法向后兼容；若新版编译报错以错误信息为准并查官方文档），JPA 用 `jakarta.persistence.*`。
完整注解字典（@Erupt/@EruptField 所有属性与枚举）见 [erupt-model.md](erupt-model.md)，本文档只覆盖生成时的决策规则与项目约定。

## 实体类骨架（标准模板）

```java
package app.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import xyz.erupt.annotation.Erupt;
import xyz.erupt.annotation.EruptField;
import xyz.erupt.annotation.sub_erupt.Power;
import xyz.erupt.annotation.sub_field.Edit;
import xyz.erupt.annotation.sub_field.EditType;
import xyz.erupt.annotation.sub_field.View;
import xyz.erupt.annotation.sub_field.sub_edit.*;
import xyz.erupt.jpa.model.BaseModel;

@Erupt(name = "图书管理", power = @Power(export = true, importable = true))
@Table(name = "t_book")
@Entity
@Getter
@Setter
public class Book extends BaseModel {

    @EruptField(
            views = @View(title = "书名"),
            edit = @Edit(title = "书名", notNull = true, search = @Search)
    )
    private String title;
}
```

要点：
- 继承 `xyz.erupt.jpa.model.BaseModel` 自动获得自增主键 `Long id`，实体里不要再写 id
- 表名统一 `t_` 前缀小写下划线；类名/字段名英文，`@View/@Edit` 的 title 用用户语言（通常中文）

### 基类选择（决定实体自带哪些字段）

按需选基类，**`orderBy`、搜索、展示只能引用实体或其基类里已声明的字段**：

| 基类 | 包 | 额外字段 | 何时用 |
|------|----|---------|--------|
| `BaseModel` | `xyz.erupt.jpa.model` | 仅 `id` | 不需要审计时间的简单实体 |
| `MetaModelUpdateVo` | `xyz.erupt.jpa.model` | `createTime` / `updateTime` / `createBy` / `updateBy`（`@PrePersist/@PreUpdate` 自动填充；`updateBy`/`updateTime` 列表可见且编辑只读，`createBy`/`createTime` 隐藏） | **推荐默认基类**：需要按创建时间排序、且想在列表展示"最后修改人/时间"时 |
| `HyperModelUpdateVo` | `xyz.erupt.upms.helper` | 同上，但把 `createBy`/`updateBy` 换成关联操作人对象 `createUser` / `updateUser`（列表展示用户名） | 需要展示"谁创建/谁修改"的用户对象时 |

> 说明：另有 `MetaModel`（`xyz.erupt.jpa.model`）/ `HyperModel`（`xyz.erupt.upms.model.base`）字段相同但审计列全部 `show=false` 隐藏，一般更推荐用上表的 `*UpdateVo` 变体，修改痕迹默认可见更实用。

**常见坑**：想用 `orderBy = "createTime desc"` 却继承了 `BaseModel` → 启动正常，但打开列表页查询时抛 `PathElementException: Could not resolve attribute 'createTime'`。要么改继承 `MetaModelUpdateVo`，要么把 orderBy 换成 `id desc`。
- 每个业务字段都写 `@EruptField`，`views` 与 `edit` 的 title 保持一致
- 关键字段加 `search = @Search`（列表页可搜索），默认按编辑类型自动推断查询方式；需强制模糊查询时写 `search = @Search(operator = QueryExpression.LIKE)`（import `xyz.erupt.annotation.config.QueryExpression`）
- 必填字段加 `notNull = true`

## @Erupt 类注解常用属性

| 属性 | 说明 | 示例 |
|------|------|------|
| `name` | 菜单/功能名（必填） | `name = "图书管理"` |
| `power` | 功能开关 | `@Power(export = true, importable = true, add = true, edit = true, delete = true)` |
| `orderBy` | 默认排序（字段须在实体或基类中已声明） | `orderBy = "id desc"`；按创建时间排序须继承 `MetaModelUpdateVo` 才能用 `orderBy = "createTime desc"` |
| `desc` | 功能描述 | `desc = "管理所有图书"` |
| `tree` | 树形展示 | 见下文「树形结构」 |

## 字段类型 → EditType 映射决策表

不写 `type` 时为 `EditType.AUTO`，会按 Java 类型自动推断（String→INPUT、数值→NUMBER、Boolean→BOOLEAN、Date→DATE），简单字段可省略 type。

| 业务语义 | Java 类型 | 写法 |
|---------|-----------|------|
| 短文本（名称、编号） | String | `@Edit(title = "x", notNull = true, search = @Search(operator = QueryExpression.LIKE))` |
| 长文本（备注、简介） | String | `@Edit(title = "x", type = EditType.TEXTAREA)` |
| 富文本（详情、内容） | String | `@Lob @Edit(title = "x", type = EditType.HTML_EDITOR)` 配 `views = @View(title = "x", type = ViewType.HTML)` |
| 数字（数量、库存） | Integer | `@Edit(title = "x", numberType = @NumberType(min = 0))` |
| 金额（价格、费用） | Double / BigDecimal | `@Edit(title = "x", numberType = @NumberType(min = 0))` |
| 是/否开关 | Boolean | `@Edit(title = "x", boolType = @BoolType(trueText = "是", falseText = "否"))` |
| 日期 | java.util.Date | `@Edit(title = "x", dateType = @DateType)` |
| 日期时间 | java.util.Date | `@Edit(title = "x", dateType = @DateType(type = DateType.Type.DATE_TIME))` |
| 固定选项（状态、分类） | Integer / String | `@Edit(title = "x", type = EditType.CHOICE, search = @Search, choiceType = @ChoiceType(vl = {@VL(value = "1", label = "上架"), @VL(value = "2", label = "下架")}))` |
| 手机号 | String | `@Edit(title = "x", inputType = @InputType(regex = "^1[3-9]\\d{9}$"))` |
| 邮箱 | String | `@Edit(title = "x", inputType = @InputType(regex = "^\\w+@\\w+\\.\\w+$"))` |
| 密码 | String | `@Edit(title = "x", type = EditType.PASSWORD)` |
| 图片上传 | String | `@Edit(title = "x", type = EditType.ATTACHMENT, attachmentType = @AttachmentType(type = AttachmentType.Type.IMAGE))` 配 `views = @View(title = "x", type = ViewType.IMAGE)` |
| 附件上传 | String | `@Edit(title = "x", type = EditType.ATTACHMENT)` 配 `views = @View(title = "x", type = ViewType.DOWNLOAD)` |
| 评分 | Integer | `@Edit(title = "x", type = EditType.RATE)` |
| 滑块/百分比 | Integer | `@Edit(title = "x", type = EditType.SLIDER, sliderType = @SliderType(max = 100))` |
| 颜色 | String | `@Edit(title = "x", type = EditType.COLOR)` |
| 标签 | String | `@Edit(title = "x", type = EditType.TAGS, tagsType = @TagsType)` |
| Markdown | String | `@Lob @Edit(title = "x", type = EditType.MARKDOWN)` |
| 代码 | String | `@Lob @Edit(title = "x", type = EditType.CODE_EDITOR, codeEditType = @CodeEditorType(language = "sql"))` |

注意：`type = EditType.CHOICE` 等需要子注解的类型必须同时写子注解；带子注解属性（boolType、dateType、numberType 等）时 type 可省略（AUTO 会识别）。

## 关联关系

### 多对一（下拉表格选择，最常用）
```java
@ManyToOne
@EruptField(
        views = @View(title = "所属分类", column = "name"),
        edit = @Edit(title = "所属分类", type = EditType.REFERENCE_TABLE,
                referenceTableType = @ReferenceTableType(label = "name"))
)
private Category category;
```
要点：`views` 必须写 `column = "name"`（引用对象的展示字段），否则列表显示对象地址。

### 多对一（树形选择，引用对象是树时）
```java
@ManyToOne
@EruptField(
        views = @View(title = "所属部门", column = "name"),
        edit = @Edit(title = "所属部门", type = EditType.REFERENCE_TREE,
                referenceTreeType = @ReferenceTreeType(label = "name", pid = "parent.id"))
)
private Department department;
```

### 一对多（主表内联编辑子表）
```java
@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
@JoinColumn(name = "order_id")
@EruptField(
        edit = @Edit(title = "订单明细", type = EditType.TAB_TABLE_ADD)
)
private List<OrderItem> items;
```
要点：子表实体也要有 @Erupt 注解但可以不需要独立菜单；TAB_TABLE_ADD 不写 views。

### 多对多（复选框）
```java
@ManyToMany
@JoinTable(name = "t_book_tag",
        joinColumns = @JoinColumn(name = "book_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id"))
@EruptField(
        edit = @Edit(title = "标签", type = EditType.CHECKBOX,
                checkboxType = @CheckboxType(label = "name"))
)
private Set<Tag> tags;
```

## 树形结构（分类、部门、区域等）

```java
@Erupt(name = "分类管理", tree = @Tree(id = "id", label = "name", pid = "parent.id"))
@Table(name = "t_category")
@Entity
@Getter
@Setter
public class Category extends BaseModel {

    @EruptField(
            views = @View(title = "名称"),
            edit = @Edit(title = "名称", notNull = true)
    )
    private String name;

    @ManyToOne
    @EruptField(
            edit = @Edit(title = "上级分类", type = EditType.REFERENCE_TREE,
                    referenceTreeType = @ReferenceTreeType(pid = "parent.id"))
    )
    private Category parent;
}
```
需要 import `xyz.erupt.annotation.sub_erupt.Tree`。

## 单行数据表单管理（FORM 视图，适合系统设置/参数配置）

只有一条记录的实体（如系统设置、站点配置、全局参数）不要用列表页，用 **FORM 菜单类型**：页面直接渲染成一张表单，打开即编辑、保存即生效。

FORM 视图**不自动读写数据库**，加载与保存全部由 DataProxy 钩子完成：

```java
// 1. 实体：正常写 @EruptField，并挂上 dataProxy
@Erupt(name = "系统设置", dataProxy = SiteConfigProxy.class)
@Table(name = "t_site_config")
@Entity
@Getter
@Setter
public class SiteConfig extends BaseModel {

    @EruptField(edit = @Edit(title = "网站名称", notNull = true))
    private String siteName;

    @EruptField(edit = @Edit(title = "客服电话"))
    private String servicePhone;
}
```

```java
// 2. DataProxy：formViewBehavior 加载唯一记录，formSave 新增或更新
package app.proxy;

import jakarta.annotation.Resource;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import xyz.erupt.annotation.fun.DataProxy;
import xyz.erupt.jpa.dao.EruptDao;
import app.model.SiteConfig;

@Service
public class SiteConfigProxy implements DataProxy<SiteConfig> {

    @Resource
    private EruptDao eruptDao;

    @Override
    public void formViewBehavior(SiteConfig model) {
        SiteConfig db = eruptDao.lambdaQuery(SiteConfig.class).one();
        if (db != null) BeanUtils.copyProperties(db, model);
    }

    @Override
    @Transactional
    public void formSave(SiteConfig model) {
        SiteConfig db = eruptDao.lambdaQuery(SiteConfig.class).one();
        if (db == null) {
            eruptDao.persist(model);
        } else {
            model.setId(db.getId());
            eruptDao.merge(model);
        }
    }
}
```

```java
// 3. 菜单注册：FORM 类型 + 手动补 ADD/EDIT 功能权限（必须！）
MetaMenu formMenu = MetaMenu.createEruptClassMenu(SiteConfig.class, menus.get(0), 30, MenuTypeEnum.FORM);
menus.add(formMenu);
// UPMS 只为 TABLE/TREE 菜单自动生成功能权限按钮，FORM 菜单必须手动补，
// 否则打开/保存表单时报 "Insufficient permissions"
menus.add(MetaMenu.createSimpleMenu("SiteConfig@ADD", "新增", "SiteConfig@ADD", formMenu, 10, MenuTypeEnum.BUTTON.getCode()));
menus.add(MetaMenu.createSimpleMenu("SiteConfig@EDIT", "修改", "SiteConfig@EDIT", formMenu, 20, MenuTypeEnum.BUTTON.getCode()));
```

要点：
- FORM 视图字段只需写 `edit`，不需要 `views`（没有列表页）
- **必须手动注册 `实体名@ADD` 和 `实体名@EDIT` 两个 BUTTON 权限菜单**（见上），这是 FORM 类型最常见的坑
- 数据来源不限于数据库：`formViewBehavior`/`formSave` 里也可以读写文件、调外部 API
- 保存前会正常执行字段校验（notNull、正则等）；`formSave` 里抛 `xyz.erupt.annotation.exception.EruptException` 可中止保存并向用户提示

## 菜单注册（必做，否则实体不会出现在后台）

@Erupt 实体**不会**自动出现在菜单，必须在启动类 `Application.initMenus()` 中注册（模板已带 EruptModule 骨架，取消注释并补齐即可）：

```java
@Override
public List<MetaMenu> initMenus() {
    List<MetaMenu> menus = new ArrayList<>();
    menus.add(MetaMenu.createRootMenu("$app", "业务管理", "fa fa-th-large", 10));
    menus.add(MetaMenu.createEruptClassMenu(Book.class, menus.get(0), 10));
    // 树形实体（@Erupt 带 tree 配置）必须指定 TREE 类型：
    menus.add(MetaMenu.createEruptClassMenu(Category.class, menus.get(0), 20, MenuTypeEnum.TREE));
    return menus;
}
```

- import：`xyz.erupt.core.constant.MenuTypeEnum`、`xyz.erupt.core.module.*`、实体类
- 配置 `erupt.init-method-enum: every`（模板已配）后按 code 幂等补插，新增实体加一行重启即生效
- 仅作为子表内联（TAB_TABLE_ADD）的实体无需注册菜单
- 一级分组用 `createRootMenu`，code 以 `$` 开头避免与实体类名冲突；sort 数值越小越靠前

## 常见坑（务必避免）

1. **@ManyToOne / @ManyToMany 必须显式写 EditType**（REFERENCE_TABLE / REFERENCE_TREE / CHECKBOX），AUTO 无法推断
2. **引用字段的 @View 必须带 `column`**，指向对象的展示属性
3. 树形 pid 是对象路径写法 `pid = "parent.id"`，不是外键列名
4. UI 辅助字段（DIVIDE 分割线等）必须加 `@Transient`（jakarta 的）
5. 富文本/长文本超过 255 字符要加 `@Lob`，否则 H2/MySQL 建列为 varchar(255)
6. 不要用 java.time.LocalDateTime，日期统一用 `java.util.Date`
7. 实体类都放在 `app.model` 包下，启动类 `@EruptScan`/`@EntityScan` 默认扫描 `app` 包
8. 枚举选项值用 @VL 的 value 是字符串（存库时按字段 Java 类型转换）
9. 每个实体必须有 `@Entity` + `@Table` + `@Erupt` + `@Getter` + `@Setter` 五件套
10. **@Search 没有 `vague` 属性**（那是 erupt 1.x 的旧 API），模糊查询写 `@Search(operator = QueryExpression.LIKE)` 并 import `xyz.erupt.annotation.config.QueryExpression`
11. **`QueryExpression` 只有 `EQ / GT / LT / LIKE / IN / RANGE`**，没有 `GE / LE / NE / BETWEEN`；范围查询用 `RANGE`
12. **`orderBy`/搜索/展示引用的字段必须真实存在**：`createTime`/`updateTime` 仅 `MetaModelUpdateVo`/`HyperModelUpdateVo`（非 `BaseModel`）才有，否则查询时抛 `PathElementException`（见上文「基类选择」）
