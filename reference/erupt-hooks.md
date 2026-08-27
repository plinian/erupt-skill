# 列表增强与表单联动（钩子速查）

高频迭代需求 → 对应钩子/方法。挂在 @Erupt 的 `dataProxy` 或字段的 `onchange` 上；完整签名与示例见文末 doc-map 指向。

## 列表增强（DataProxy 钩子）

| 需求 | 钩子方法 | 要点 |
|---|---|---|
| 底部合计/统计行 | `extraRow(conditions)` | 返回 `List<Row>`，`Row.builder().columns(List.of(new Column(值, 跨列数)))` |
| 顶部提醒条 | `alert(conditions)` | 返回 `Alert.info("...")`，null=不显示 |
| 显示脱敏/拼接/动态列 | `afterFetch(list)` | 改 `Collection<Map>` 的值即改前端显示，不动库数据（key 为 camelCase 字段名） |
| 查询前追加条件 | `beforeFetch(conditions)` | 返回 HQL 条件串；数据权限优先用 Looker 基类（见 erupt-upms.md） |
| Excel 导入导出拦截 | `excelExport(wb)` / `excelImport(wb)` / `excelImportProcess(list)` | wb 需强转 POI `Workbook`；导入入库前校验抛 `EruptException` 中止 |

`Row`/`Column`/`Alert` 均在 `xyz.erupt.annotation.model`。

## 表单联动（后端驱动，零前端代码）

| 需求 | 机制 | 要点 |
|---|---|---|
| 选 A 自动带出 B | 字段 `@Edit(onchange = X.class)` + 实现 `OnChange.populateForm` | 返回 `Map<字段名, 新值>` 填充表单 |
| 运行时改其他字段的 @Edit 配置 | `OnChange.buildEditExpr` | 返回 `Map<字段名, "edit.属性='值'">` |
| 下拉级联（省→市） | `@ChoiceType(fetchHandler=X, dependField="province")` + 实现 `ChoiceFetchHandler.fetchFilter` | `fetch()` 返全量，`fetchFilter(model, params)` 按依赖字段过滤 |
| 行操作弹窗预填 | `OperationHandler.eruptFormValue(rows, form, param)` | 按选中行预填 form 后返回 |
| 表单内触发后端逻辑（测试连接等） | `@Transient` 字段 + `@Edit(type=BUTTON, buttonType=@ButtonType(handler=X))` | handler 返回 JS 串在前端执行 |

`OnChange`/`ChoiceFetchHandler` 在 `xyz.erupt.annotation.sub_field.sub_edit` / `xyz.erupt.annotation.fun`。

> 完整签名与示例：**doc-map.md → `advanced/data-proxy-table`、`advanced/extra-row`、`advanced/data-proxy-excel`、`annotation/on-change`、`annotation/row-operation`**。
