# 计划文档：线索列表「待跟进优先」改用 pendingPriority 专用排序参数

> 日期：2026-07-28
> 状态：**已开发并真机验证通过**
> 范围：线索列表（我的线索）默认排序 + 排序弹窗「待跟进优先」选项

## 一、背景与问题

- 此前 App「待跟进优先」用 `sort=nextFollowupAt`（按 `nextFollowupAt` 升序）。
- 实际查回数据不合理：`nextFollowupAt` 仅对「有跟进计划」的线索有效；未分配/无计划的线索其值为 `null`，排序语义混乱，且与业务预期（assigned 状态置顶、无计划排最后）不符。
- 与后端沟通后，新增专用排序参数 `sort=pendingPriority`，语义：
  - `assigned` 状态置顶；
  - 其余按 `nextFollowupAt` 升序；
  - 无跟进计划（`NULL`）排最后（`NULLS LAST`）。

## 二、改动文件

1. `lib/providers/lead_list_provider.dart`
   - `LeadListState.sortBy` 默认值由 `'nextFollowupAt'` → `'pendingPriority'`。
   - `toggleSort()`：原 `state.sortBy == '-updatedAt' ? 'nextFollowupAt' : '-updatedAt'` → `'pendingPriority'`（与「最近更新」互相切换）。
2. `lib/pages/leads/widgets/leads_filter_sheet.dart`
   - 排序弹窗「待跟进优先」选项 value 由 `'nextFollowupAt'` → `'pendingPriority'`（label 不变）。
3. `docs/api.md`
   - `GET /api/tenant/leads` 参数表补 `sort` 与 `sort=pendingPriority` 说明（与后端契约对齐）。

## 三、未改动

- 公海列表（`leads_list_page.dart` 的 `scope=public` 分支）仍用 `sort='-updatedAt'`（最近更新），与「待跟进优先」无关，保持原样。
- 后端 `sort` 缺省 `createdAt desc`、其余 DSL 白名单字段（`createdAt` / `updatedAt` / `status` 等）均不变。

## 四、验证

- `flutter analyze` 改动 2 文件 0 issue。
- 真机：默认进入「我的线索」即为「待跟进优先」顺序（assigned 置顶、无计划排尾）；点排序弹窗可在「最近更新 / 待跟进优先」间切换，高亮正确。
