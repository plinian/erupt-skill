# template-module —— 仅用于开发 erupt 扩展模块

此脚手架**不是**用来生成管理后台应用的。它的产出是一个 jar 库（erupt 功能模块），供其他 erupt 应用加依赖复用，如 erupt-ai、erupt-job、erupt-wx。

- 用户要"XX 管理系统 / 后台 / CRUD 应用" → 用 `template/`（skill 默认场景）
- 用户明确要"开发一个 erupt 模块 / 扩展 / 插件，给其他 erupt 应用用" → 才用本目录

使用流程与占位符替换规则见 `reference/erupt-module.md`。
