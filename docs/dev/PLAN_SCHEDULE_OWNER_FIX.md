# 管理员/经理日程归属人·选择器·标签调整方案（v2）

---

## 需求 1+2：日程归属人默认值与选项范围

### 当前行为

所有角色在创建日程时，归属人下拉默认选中**当前登录用户**，选项为**全部用户**。

### 改为

| 场景 | 员工 TE | 经理/管理员 TM/TA |
|---|---|---|
| 非已转化线索 | 不变（默认自己） | **默认线索的归属人**（`lead.ownerId`） |
| 已转化线索 | 无编辑权限 | **默认自己**（当前登录用户） |

### 归属人选项范围（重要）

经理/管理员新建日程时，归属人选择器内**只显示三类人**：
1. **线索的归属员工**（`leadOwnerId` 对应的那个人，如果是员工角色）
2. **所有管理员**（`role == 'tenant_admin'`）
3. **所有经理**（`role == 'tenant_manager'`）

**不显示其他普通员工**，因为线索归该员工专属，不能擅自转派给其他员工，但管理员/经理可协助处理。

已转化线索无 `leadOwnerId`，选项只包含管理员和经理。

### 改动点

**① `schedule_form_sheet.dart`**
- 入口函数 `showScheduleFormSheet()` 加可选参数 `String? leadOwnerId`
- `ScheduleFormContent` / `_ScheduleFormContentState` 加 `widget.leadOwnerId`
- `_loadOwnersIfNeeded()` 改动：
  - **员工** → 不显示归属人区块（不变）
  - **经理/管理员** → 加载用户后**过滤**：只保留 `leadOwnerId` 匹配者 + `tenant_admin` + `tenant_manager`
  - 默认值逻辑：
    - 有 `leadOwnerId` → 默认选中对应的归属人
    - 无 `leadOwnerId` → 默认选中当前登录用户

**② `lead_detail_page.dart`**
- 调用 `showScheduleFormSheet` 时传 `leadOwnerId: detail.ownerId`
- 已转化线索仍传 `detail.ownerId`（此时可能为 null），由 sheet 内部逻辑决定默认值

---

## 需求 3：归属人改为抽屉选择

### 当前实现

`schedule_form_fields.dart` 使用 `DropdownButton<OptionItem>` 下拉框。

### 改为「点击 → 弹出选择抽屉」

**UI 交互：**
```
归属人  [ 张三  > ]           ← 点击整行，弹出底部抽屉
```

抽屉内容（使用 `AppBottomSheet.show`）：
```
┌─ 选择归属人 ───────────┐
│                        │
│  ○ 李四 (管理员)         │  ← RadioListTile，可选显示角色后缀
│  ● 张三 (当前)          │
│  ○ 王五 (经理)          │
│                        │
└────────────────────────┘
```

### 改动点

- `schedule_form_fields.dart` 的 `_buildOwnerSection()` 中 `DropdownButton` 改为 `GestureDetector` + 当前选中文本
- 新增 `_showOwnerPicker()` 方法，弹出 `AppBottomSheet` 内嵌人员列表
- 每项用 `RadioListTile` 或自定义 tile，选中后 `setState` 更新 `_owner` 并关闭抽屉

---

## 需求 4：线索右上角标签修正

### 当前实现（有 bug）

已转化线索时，**用级别 tag 替换了状态 tag**。

### 应改为

| 线索状态 | 显示的 tag |
|---|---|
| 非已转化 | **[状态]** + **[分类]** |
| 已转化 | **[已转化]** + **[级别]**（不显示分类） |

### 改动点

`lead_header_section.dart` 的 `_buildNameAndTags`：
- 去掉当前替换逻辑
- 始终显示 `_buildStatusTag()`
- 已转化时追加 `_buildLevelTag()`
- **去掉分类 tag**（已转化时不显示分类）

```dart
_buildStatusTag(),                              // 始终显示
if (detail.isConverted && customer != null)
  _buildLevelTag(),                             // 已转化时追加级别
if (!detail.isConverted && ...)
  _buildCategoryTag(ref),                       // 非已转化时保留分类
```

---

## 改动文件汇总

| 文件 | 改动 |
|---|---|
| `schedule_form_sheet.dart` | 入口加 `leadOwnerId` 参数；`_loadOwnersIfNeeded` 过滤归属人选项（只保留归属员工+管理员/经理） |
| `schedule_form_fields.dart` | `_buildOwnerSection` 下拉框改为抽屉选择器；新增 `_showOwnerPicker` 方法 |
| `lead_detail_page.dart` | 调用 `showScheduleFormSheet` 时传 `leadOwnerId` |
| `lead_header_section.dart` | 已转化线索显示 [已转化] + [级别]，不显示分类 tag |
