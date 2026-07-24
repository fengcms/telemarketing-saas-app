# 计划 16 — 通话记录（列表页）

> 版本：v1.0（2026-07-24 起草 → 实测通过，已定案）
> 范围：本轮**完成列表页**；**通话详情页经用户拍板不再开发**，行点击直接跳对应线索详情。
> 设计文档：docs/design/page-design/16-通话记录.md
> 接口契约：docs/api.md §通话记录（注意：后端已补 `leadName` 等字段，但 api.md 尚未更新，字段名以设计文档 doc16 为准）
> 状态：✅ 已开发 + 真机实测通过（2026-07-24），进度见 `MILESTONES.md` 节点 v0.17

---

## 1. 关键决策（已与用户确认）

| 项 | 决策 |
|----|------|
| 本轮范围 | 列表页（加载 / 手机号搜索 + 类型筛选 / 无限滚动 / 下拉刷新 / 空态 / 错误态 / 违规标记） |
| 被叫号码字段 | 用 `phone`（api.md 与现有 `CallRecord` 模型一致；设计文档旧命名 `calleeNumber` 忽略） |
| 线索姓名字段 | 后端**已补** `leadName`，本轮列表第一行显示（半粗），其后紧跟 `phone`（黑/不加粗） |
| 违规标记 | 现有 `CallRecord` 缺 `violation` 字段，需补（api 返回 0/1，设计 §3.3.3 要显示图标） |
| 时间筛选 | **移除 TDesign 日历**（弹层崩溃，见 PITFALLS §2.5），改用手机号搜索（`q` 模糊搜） |
| 详情页 | **经用户拍板不再开发**；列表行点击直接跳对应线索详情（`LeadDetailPage(leadId:)`），不传 listContext |
| 角色权限 | 列表页不涉及编辑/删除按钮（已决定不做详情页），无需 role 判断；后端按 Token 自动限定 TE 只看自己的 |
| 脱敏 | 前端原样渲染后端返回（TE 下可能看到脱敏号码 `138****1234`，属正常后端行为） |

> ⚠️ **真机实测核字段**：开发后装真机，用 Alice 浮标抓 `GET /api/tenant/calls` 响应，核对 `leadName` / `violation` 实际返回字段名与结构。若与 doc16 不符，立即按实测调整模型，不猜测。

---

## 2. 接口依赖

### 2.1 新增 `fetchMyCalls`（替换/补充现有 `fetchCalls`）

现有 `lead_service.fetchCalls` 仅用于线索详情（强制带 `leadId`、size=3），**不适用于**本页（不带 leadId、按日期/类型筛选、size=20）。

新增独立方法（建议放 `lib/services/call_service.dart`，与 `lead_service` 解耦）：

```
GET /api/tenant/calls
query: dateFrom=YYYY-MM-DD  (默认 30 天前)
       dateTo=YYYY-MM-DD    (默认今天)
       answerType=answered|no_answer|rejected|empty_number|suspended  (选填，空=全部)
       sort=-startedAt
       page=1
       size=20
响应包裹：{success, data:{items:[CallRecord], total, page, size, pages}}
```

- 返回 `(items, total, pages)`，列表页据此判断"是否还有下一页"。
- 参数封装：`Map<String, dynamic>` 动态拼装，空 `answerType` 不传该 key（设计 §4.4 "点击全部不传 answerType"）。
- 复用 `ApiClient.parseError` 统一错误。

---

## 3. 页面结构与组件拆分

### 3.1 文件清单（守住 560 行红线）

| 文件 | 职责 | 预估行数 |
|------|------|---------|
| `lib/pages/call_records/call_records_page.dart` | 主页面（ConsumerStatefulWidget）：筛选状态、分页、下拉刷新、空/错态、列表装配 | ~330 |
| `lib/pages/call_records/widgets/call_filter_bar.dart` | 筛选区：日期范围行 + 接听类型横滚 Tag 行 | ~150 |
| `lib/pages/call_records/widgets/call_record_row.dart` | 单条记录行：左侧圆形彩色图标 + 主体两行 + 右侧时长/违规 | ~130 |
| `lib/pages/call_records/widgets/call_list_skeleton.dart` | 骨架屏（复用 `ShimmerBlock`，5 条） | ~60 |
| `lib/models/call_record.dart`（改） | 补 `violation`、`leadName` 字段 | +8 |
| `lib/services/call_service.dart`（新） | `fetchMyCalls` | ~70 |
| `lib/pages/profile/profile_page.dart`（改） | "通话记录"菜单项从 `ComingSoonPage` 改为 push `CallRecordsPage` | ~3 |

### 3.2 列表页布局（对齐 doc16 §2.1 + §3）

```
┌─ AppBar(蓝底白字 "通话记录" + 返回箭头) ─┐
├─ 筛选白卡 ───────────────────────────────┤
│   📅 2026-06-24 ~ 2026-07-24   [⚙]  │
│   [全部][已接听][无人接听][拒接][空号][停机] │  ← 横滚 Chip
├─ 列表（RefreshIndicator + ListView.builder）──┤
│   (icon) 138****1234          3:25      │
│           张先生  2026-07-15 14:30          │
│   ──────────────────────────────(左缩进)── │
│   (icon) 139****5678          0:00   ⚠   │
│           ...                                  │
├─ 底部：加载更多 转圈 / "没有更多了" ──────┤
```

### 3.3 TDesign 零先例组件替代（项目约定：不用 TDCell/TDTag/TDNavBar/TDSkeleton/TDRefreshHeader/TDEmpty/TDCalendarPicker）

| 设计文档组件 | 实现替代 |
|----|----|
| `TDNavBar` | `AppBar`（backgroundColor brand-7 #0052D9，foregroundColor white，leading 返回箭头） |
| `TDCell`（多行） | 自绘 `Row`（白底 + 左 padding16 + 底 `Divider` 左缩进 56） |
| `TDTag`/`TDCheckTag` | 自绘横滚 `Chip`（`Container` 圆角999 + `GestureDetector`，选中 brand-1 底 / brand-7 字，未选 gray-1 底 / gray-6 字） |
| `TDRefreshHeader` | `RefreshIndicator`（系统下拉刷新） |
| `TDSkeleton` | 复用现有 `ShimmerBlock`（传 `ctrl`） |
| `TDEmpty` | 自绘空态（`Icon` + `Text` + 可选"重试" `TextButton`） |
| `TDCalendarPicker` | 本轮简化：点击日期行弹 `showDatePicker` 选**起始**日，二次点选**结束**日（或先选起再选止两段式）；后续可换 TDesign 日历 |

> 图标配色（doc16 §3.3.1）：answered→success-7 #2BA471 / no_answer→error-7 #D54941 / rejected→warning-7 #E37318 / empty_number·suspended→gray-6，均 20% 透明度做圆形背景，图标用 `Icons.call`/`Icons.close_circle`/`Icons.info`/`Icons.power_off`。

### 3.4 单行渲染规则（doc16 §3.3 + §7）

- **第一行**：优先显示 `leadName`（后端已补）；`leadName` 为空时回退显示 `phone`（脱敏或明文）；`phone` 也为空 → "未知号码"。
- **第二行**：`(leadCompany 或 leadName 补充) + 拨号时间`（shortDateTime，MM-DD HH:mm）。本轮若无 company 字段则仅显示时间。
- **右侧时长**：`durationText`（M:SS）；`duration==0` 或 非 answered → 显示"未接通"（doc16 §7）；answered 且 >0 → M:SS。
- **违规图标**：`violation==1` 时在时长下方显示 `Icons.error` 红点（error-7）。
- **左缩进分割线**：`Divider` 左 margin 56（对齐图标右缘）。

---

## 4. 交互流程（对齐 doc16 §4）

| 流程 | 行为 |
|------|------|
| 初始加载 | 显示骨架 → `fetchMyCalls(page=1)` → 渲染列表 → 隐藏骨架 |
| 下拉刷新 | `RefreshIndicator` → 重新请求（保持当前搜索词/筛选，page 重置 1）→ 刷新列表 + 重置分页 |
| 手机号搜索 | 顶部搜索栏输入 → 点「搜索」或回车 → `q` 非空才传 → 重请求（page 重置 1）；清空则取消搜索 |
| 类型筛选 | 点 Tag → 切换选中 → 重请求（带 answerType，page 重置 1） |
| 行点击 | `leadId` 非空 → 跳 `LeadDetailPage(leadId:)`；空号/停机等无关联线索不跳 |
| 无限滚动 | 滚动距底 < 200px 且 `page < pages` → 转圈 → `fetchMyCalls(page+1)` → 追加；`page>=pages` → "没有更多了" |
| 空态 | items 空 → （有搜索词）"未找到相关通话" / （无）"暂无通话记录" |
| 错误态 | 请求失败 → 错误插图 + "重试" 按钮（重新拉第一页） |

---

## 5. 边界情况（doc16 §7，本轮覆盖）

- `duration==0` 显示 "0 秒"；非 answered 类型显示 "未接通"。
- 被叫号码为空 → "未知号码"。
- `violation==1` → 右侧 error 图标。
- 列表快速滚动 → `ListView.builder` 复用，保证流畅。
- 详情页返回保持滚动位置（本轮列表页独立，暂无跨页状态保留需求）。

---

## 6. 经用户拍板不开发（已定案）

> 2026-07-24 用户确认：列表已呈现关键信息（姓名/号码/时间/时长/违规），**通话详情页无独立开发价值**。故下列功能**永久不做**，原「列表行点击跳详情」改为「跳对应线索详情」。

- 通话详情页（`/mine/call-records/:id`）
- TM/TA 编辑弹窗（`PATCH /api/tenant/calls/:id`）
- TA 删除按钮（`DELETE /api/tenant/calls/:id`）
- 关联线索卡片（`leadCompany` / `leadLevel`）
- 列表行点击 → **跳 `LeadDetailPage(leadId:)`**（仅 `leadId` 非空才跳）

---

## 7. 真机实测清单（装 Redmi K60 + Alice 浮标）

1. 进入「我的」→「通话记录」，列表正确加载。
2. **抓包核对**：`GET /api/tenant/calls` 响应含 `leadName`、`violation` 字段（与 doc16 一致）。
3. 每行：图标配色按接听类型正确；第一行姓名(半粗)+手机号(黑/不加粗)；第二行时间；右侧时长；违规行有红点。
4. 下拉刷新正常，数据刷新、分页重置。
5. 类型筛选：点「已接听」等，列表按类型过滤；点「全部」恢复。
6. 手机号搜索：输入号码点「搜索」，Alice 可见请求带 `q=xxx` 且出数据；清空搜索恢复全部。
7. 行点击：有姓名(关联线索)的记录跳线索详情；空号/停机(无 leadId)不跳。
8. 无限滚动：滚到底自动加载下一页；到底显示"没有更多了"。
9. 空态 / 错误态（断网重试）显示正常。

---

## 8. 文档与提交

- 进度：`docs/review/history/call-records-list-dev-2026-07-24.md`
- 踩坑（如有）：`docs/dev/DEVELOPMENT_PITFALLS.md`
- 里程碑：`docs/dev/MILESTONES.md` 标记「通话记录列表页」✅
- `flutter analyze` 全工程 0 issue → 构建 debug（DEV_TOOLS）→ 装真机 → 实测 → `git commit & push`
