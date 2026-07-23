# 代码审查：更新文档中的 API 接口地址为测试环境地址

- 提交：`e5c7ac2`
- 类型：`docs`
- 作者 / 日期：FungLeo / 2026-07-22
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23

## 一、改动概览

更新 `docs/api.md` 等文档中的 API 地址为测试环境地址。**未包含任何 `lib/` 业务代码。**

## 二、审查结论

**➖ 无业务代码可审。** 质量门禁（flutter analyze）不适用。

## 三、组长备注

- 建议：API 基址（`https://tm-api-test.kao9.com`）目前已硬编码在 `lib/services/api_constants.dart`（见 `bc59aae` 提交），后续应抽为 `--dart-define` 或环境配置文件，避免测试/生产地址切换靠改代码。
- 文档与代码地址需保持一致，建议建立「改地址→同步文档+代码」的检查清单。
