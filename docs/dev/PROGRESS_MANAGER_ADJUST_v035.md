# 管理员/经理适配改造 v0.35

## 背景

员工角色功能基本完成后，开始针对管理员和经理角色进行一系列调整，包括编辑分流（已转化→客户编辑，非已转化→线索编辑）、客户列表默认全部、筛选归属人过滤、线索右上角标签修正、日程归属人默认值与选择器改造等。

## 改动清单

### P0 — 编辑分流与客户模型

| 文件 | 改动 |
|---|---|
| `lib/models/customer_detail.dart` | **新建**。客户详情模型，26 个字段，含 fromJson |
| `lib/models/lead_detail_bundle.dart` | 加 `CustomerDetail? customer` 字段，fromJson 解析 data.customer |
| `lib/models/lead.dart` | 列表项加 `customerId` 字段 |
| `lib/models/lead_detail.dart` | 详情加 `customerId`、`ownerId` 字段 |
| `lib/services/lead_service.dart` | `updateLead` 加 name/remark（保留 status）；新增 `updateCustomer` 方法 |
| `lib/pages/leads/widgets/edit_lead_dialog.dart` | 重构：去状态选择，加姓名/备注字段，顺序为姓名→分类→备注 |
| `lib/pages/leads/widgets/edit_customer_dialog.dart` | **新建**。客户编辑抽屉：姓名 + 客户级别（普通/重要/VIP/流失）+ 备注 |
| `lib/pages/leads/lead_detail_page.dart` | 编辑按钮按 isConverted 分流；经理侧移除标记为已转化；传 customer 给 header；传 leadOwnerId 给日程 |

### P1 — 经理 UI 调整

| 文件 | 改动 |
|---|---|
| `lib/pages/customers/customer_list_page.dart` | TM/TA 默认 scope=all，去掉 scope 切换 UI |
| `lib/pages/leads/widgets/leads_filter_sheet.dart` | 归属人筛选仅保留员工角色 |
| `lib/pages/leads/widgets/lead_header_section.dart` | 加 customer 参数；已转化线索显示[已转化]+[级别]；备注优先级显示 |
| `lib/constants/lead_constants.dart` | 加 `customerLevelLabels`、`customerLevelLabel()`、`customerLevelColorStyle()` |
| `lib/pages/schedules/widgets/schedule_form_sheet.dart` | 入口加 leadOwnerId；归属人过滤（只显示归属员工+管理员/经理）；默认值分叉 |
| `lib/pages/schedules/widgets/schedule_form_fields.dart` | 归属人从 DropdownButton 改为抽屉选择器（`_showOwnerPicker`）；加角色标注 |
| `lib/services/options_cache_service.dart` | `_encodeList` 补 role 字段序列化（修复缓存丢失 role 的 bug） |

### 用户级别颜色

| 级别 | 背景色 | 文字色 |
|---|---|---|
| 普通（normal） | 🟢 `#2BA471` | 白 |
| 重要（important） | 🔵 `#0052D9` | 白 |
| VIP（vip） | 🟡 `#DAA520` | 白 |
| 流失（lost） | ⚪ `#DCDCDC` | `#A6A6A6` |

## 验证结论

- 真机 Redmi K60 实测通过
- `flutter analyze` 全仓 0 error
