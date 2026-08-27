# 列表增强与表单联动（DataProxy 进阶 + OnChange）

> 已对照 erupt 发布版实测核实（基线版本统一记录在 SKILL.md「版本基线」）。覆盖高频迭代需求："列表加合计行" "顶部加提醒" "显示脱敏" "导入校验" "选 A 带出 B" "下拉级联" "弹窗预填"。

## 列表增强（DataProxy 钩子，挂在 @Erupt 的 dataProxy 上）

### 底部合计行 extraRow

```java
import xyz.erupt.annotation.model.Column;
import xyz.erupt.annotation.model.Row;

@Override
public List<Row> extraRow(List<Condition> conditions) {
    // 每个 Column 按列顺序对应表格列；colspan 可跨列
    return List.of(Row.builder().columns(List.of(
            new Column("合计", 2),                       // 跨 2 列
            new Column(String.valueOf(sumAmount()))
    )).build());
}
```

### 列表顶部提醒 alert

```java
import xyz.erupt.annotation.model.Alert;

@Override
public Alert alert(List<Condition> conditions) {
    long low = countLowStock();
    return low > 0 ? Alert.info("有 " + low + " 个商品库存不足") : null;   // null = 不显示
}
```

### 列表显示加工 afterFetch（脱敏、拼接、动态列值）

```java
@Override
public void afterFetch(Collection<Map<String, Object>> list) {
    // key 为字段名（camelCase），直接改 Map 即改前端显示，不影响库里数据
    list.forEach(row -> row.put("phone", mask((String) row.get("phone"))));
}
```

### 查询前追加条件 beforeFetch

返回 HQL 条件字符串（数据权限场景见 erupt-upms.md 的 Looker 基类，优先用基类）。**条件值只能来自服务端上下文（当前用户等），严禁拼接请求输入**。

### Excel 导入导出拦截

```java
@Override
public void excelExport(Object workbook) { /* (Workbook) 强转后加汇总行、样式 */ }

@Override
public void excelImport(Object workbook) { /* 导入解析前预处理 */ }

@Override
public void excelImportProcess(List<MyEntity> list) {
    // 导入数据入库前的校验/补全，抛 EruptException 可中止导入
}
```

## 表单联动（后端驱动，零前端代码）

### OnChange：字段变化 → 带出/改造其他字段

```java
// 实体字段：onchange 指向处理器（可与 dataProxy 同一个类）
@EruptField(
        edit = @Edit(title = "客户", type = EditType.REFERENCE_TABLE,
                referenceTableType = @ReferenceTableType(label = "name"),
                onchange = OrderOnChange.class, onchangeParams = {"withAddress"})
)
private Customer customer;
```

```java
@Component
public class OrderOnChange implements OnChange<Order> {   // xyz.erupt.annotation.sub_field.sub_edit.OnChange

    // 返回 Map<字段名, 新值>：用户改动该字段后，自动填充表单其他字段
    @Override
    public Map<String, Object> populateForm(Order order, String[] params) {
        if (null == order.getCustomer()) return Map.of();
        return Map.of("address", order.getCustomer().getDefaultAddress());
    }

    // 返回 Map<字段名, "edit.属性='值'">：运行时改其他字段的 @Edit 配置（只读/描述等）
    @Override
    public Map<String, String> buildEditExpr(Order order, String[] params) {
        return Map.of("discount", "edit.desc='VIP 客户可享折扣'");
    }
}
```

### 下拉级联：ChoiceFetchHandler.fetchFilter

```java
@EruptField(
        edit = @Edit(title = "城市", type = EditType.CHOICE,
                choiceType = @ChoiceType(fetchHandler = CityFetch.class, dependField = "province"))
)
private String city;
```

```java
@Component
public class CityFetch implements ChoiceFetchHandler<Order> {

    @Override
    public List<VLModel> fetch(String[] params) { return allCities(); }   // 全量（结果须包含 fetchFilter 的所有选项）

    // dependField 变化时回调，按整个表单当前值过滤选项
    @Override
    public List<VLModel> fetchFilter(Order order, String[] params) {
        return citiesOf(order.getProvince());
    }
}
```

### 行操作弹窗预填：OperationHandler.eruptFormValue

```java
@Override
public MyForm eruptFormValue(List<MyEntity> rows, MyForm form, String[] param) {
    form.setTitle(rows.get(0).getName() + " 的处理单");   // 按选中行预填，用户打开弹窗即见
    return form;
}
```

### 表单内按钮：EditType.BUTTON

`@Transient` 字段 + `buttonType = @ButtonType(handler = XxxButtonHandler.class)`，点击触发后端逻辑（如"测试连接""重新计算"），handler 返回 JS 字符串（如 `alert(...)` / `msg.success('...')`）在前端执行。完整属性见 erupt-model.md。
