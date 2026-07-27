# 管理员/经理线索编辑改造计划

> **核心思路**：经理/管理员根据线索是否已转化，走两条不同的编辑路径。员工维持现状不变。
>
> 后端已确认：`PATCH /api/tenant/leads/:id` 已支持 name/remark/categoryId；`PATCH /api/tenant/customers/:id` 已支持 name/level/remark，无需新建接口。

---

## 〇、角色路线图

| 场景 | 员工（TE） | 经理/管理员（TM/TA） |
|---|---|---|
| 非已转化线索 — 编辑按钮 | 无（已移除） | 弹出**线索编辑抽屉**（姓名 + 分类 + 备注） |
| 已转化线索 — 编辑按钮 | 无（已移除） | 弹出**客户编辑抽屉**（姓名 + 级别 + 备注） |
| 标记为已转化 | `following` 态显示「转化」 | **移除**（只有员工做转化） |
| 跟进 / 日程 | 已转化线索禁用 | 始终可用（已实现） |
| 备注显示 | 详情头显沉淀内容 | 详情头显沉淀内容 |

---

## 一、文件改动清单

| 文件 | 改动力度 | 说明 |
|---|---|---|
| `lib/services/lead_service.dart` | 修改 | `updateLead()` 加 `name`、`remark` 参数；新增 `updateCustomer()` 方法 |
| `lib/pages/leads/widgets/edit_lead_dialog.dart` | 重构 | 非已转化：仅展示姓名、分类、备注（移除状态选择）；入口函数签名不变 |
| `lib/pages/leads/widgets/edit_customer_dialog.dart` | **新建** | 客户编辑抽屉：姓名 + 客户级别 + 备注 |
| `lib/pages/leads/lead_detail_page.dart` | 修改 | 经理侧移除「标记为已转化」；编辑按钮按 `isConverted` 分流 |
| `lib/pages/leads/widgets/lead_header_section.dart` | 修改 | 正文下方增加备注沉淀行 |
| `lib/constants/lead_constants.dart` | 修改 | 新增客户级别映射 |

---

## 二、接口契约（后端已确认）

### 2.1 `PATCH /api/tenant/leads/:id` — 编辑线索

TM/TA 可用字段（全部可选，缺省不修改）：

```json
{
  "name": "新姓名",         // string, max60
  "categoryId": "cat001",   // string, max64
  "remark": "线索备注",      // string, max500
}
```

⚠️ 已转化线索不可走此接口（返回 400 `STATUS_ROLLBACK_FORBIDDEN`）。

前端 `updateLead()` 签名：

```dart
Future<bool> updateLead({
  required String id,
  String? name,
  String? categoryId,
  String? remark,
})
```

### 2.2 `PATCH /api/tenant/customers/:id` — 编辑客户

所有角色可用；TE 仅可改自己归属的客户。

```json
{
  "name": "客户姓名",    // string, max100
  "level": "important", // enum: normal | important | vip | lost
  "remark": "客户备注"    // string, max1000
}
```

前端新增：

```dart
Future<bool> updateCustomer({
  required String id,
  String? name,
  String? level,
  String? remark,
})
```

---

## 三、客户级别枚举

```dart
static const Map<String, String> customerLevelLabels = {
  'normal': '普通',
  'important': '重要',
  'vip': 'VIP',
  'lost': '流失',
};
```

`CustomerDetail.level` 字段值即后端返回的枚举字符串，直接映射。

---

## 四、实现步骤（6 个改动）

### 步骤 1：`lead_constants.dart` — 加级别映射表

新增：
```dart
static const Map<String, String> customerLevelLabels = {
  'normal': '普通',
  'important': '重要',
  'vip': 'VIP',
  'lost': '流失',
};
```

### 步骤 2：`lead_service.dart` — 扩展接口

**`updateLead()` 改动**：增加 `name`、`remark` 参数，请求体拼入对应字段。

```dart
Future<bool> updateLead({
  required String id,
  String? name,
  String? categoryId,
  String? remark,
}) async {
  final body = <String, dynamic>{};
  if (name != null) body['name'] = name;
  if (categoryId != null) body['categoryId'] = categoryId;
  if (remark != null) body['remark'] = remark;
  ...
}
```

**新增 `updateCustomer()`**：

```dart
Future<bool> updateCustomer({
  required String id,
  String? name,
  String? level,
  String? remark,
}) async {
  final body = <String, dynamic>{};
  if (name != null) body['name'] = name;
  if (level != null) body['level'] = level;
  if (remark != null) body['remark'] = remark;
  final response = await _apiClient.dio.patch(
    '${ApiConstants.customers}/$id',
    data: body,
  );
  final data = response.data;
  return data is Map && data['success'] == true;
}
```

### 步骤 3：新建 `edit_customer_dialog.dart` — 客户编辑抽屉

```
标题：「编辑客户信息」
── 底部 AppBottomSheet ──
姓名        [TextField 或 AppFormSection 包裹的输入框]
客户级别    普通  重要  VIP  流失  ← TagChipRow 单选（预填当前 level）
备注        [AppTextarea，maxLength 不设上限]
           ┌──────┐
           │  保存  │  ← AppActionBar.submit
           └──────┘
```

- 入口函数：`showEditCustomerDialog(context, {required CustomerDetail customer})`
- 保存调用 `updateCustomer()` → `refreshBundle()` → toast「客户信息已更新」

### 步骤 4：`edit_lead_dialog.dart` — 重构为非已转化线索编辑

当前内容（分类 + 状态选择 + 提交）→ 改为：

```
标题：「编辑线索信息」
── 底部 AppBottomSheet ──
姓名        [TextField，预填线索姓名]
线索分类    分类1  分类2  分类3  ← TagChipRow 单选（预填当前 categoryId）
备注        [AppTextarea，maxLength: 500]
           ┌──────┐
           │  保存  │  ← AppActionBar.submit
           └──────┘
```

改动点：
- 删除 `_forwardStatusMap` / `_selectedStatus` / 状态相关 UI 和 import
- 新增姓名字段、备注字段
- 保存调 `updateLead()` 传 `name`、`categoryId`、`remark`
- 保留 `categoryId` 的加载+选择逻辑
- 入口函数签名保持 `showEditLeadDialog(context, leadId:, detail:)` 不变

### 步骤 5：`lead_detail_page.dart` — 操作栏调整

**经理侧：**
- **移除**「标记为已转化」按钮（完整删除 `else if (!detail.isConverted) { ... }` 段）
- 编辑按钮按 `detail.isConverted` 分流：
  - 已转化 → `showEditCustomerDialog(context, customer: state.bundle!.customer!)`
  - 非已转化 → `showEditLeadDialog(context, leadId: detail.id, detail: detail)`

**员工侧：**
- 维持现有「转化」按钮（仅 `following` 态显示）

### 步骤 6：`lead_header_section.dart` — 增加备注显示

在 `_buildInfoRows()` 已有字段（公司、职位、归属）之后追加：

```dart
if (detail.remark != null && detail.remark!.isNotEmpty)
  AppInfoRow(
    icon: Icons.notes,
    label: '备注',
    value: detail.remark!,
  ),
```

---

## 五、验证项

1. 经理打开非已转化线索 → 点编辑 → 姓名/分类/备注 → 保存 → 详情刷新
2. 经理打开已转化线索 → 点编辑 → 姓名/级别/备注 → 保存 → 详情刷新
3. 经理在非已转化线索 → 操作栏无「标记为已转化」
4. 员工在 `following` 线索 → 操作栏仍有「转化」按钮
5. 详情页有备注时 → 头部卡片底部显示备注行
6. 全仓 `flutter analyze` 0 error

---

## 六、开发顺序

1. `lead_constants.dart`（加级别映射）
2. `lead_service.dart`（扩展接口）
3. `edit_lead_dialog.dart`（重构：去状态、加姓名/备注）
4. `edit_customer_dialog.dart`（新建）
5. `lead_detail_page.dart`（分流编辑 + 去标记为已转化）
6. `lead_header_section.dart`（加备注显示）
→ 构建 APK → 真机实测 → 写文档 → commit
