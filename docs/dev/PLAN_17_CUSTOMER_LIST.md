# 计划 17 — 客户列表（列表页）

> 版本：v1.0（2026-07-24 **已定案，实测通过**）
> 范围：本轮**仅做列表页**。客户详情页（doc18）不开发，点卡片直接跳线索详情（用户拍板）。
> 设计文档：docs/design/page-design/17-客户列表.md（注：原标注为 v1.1 预留，本轮回应用户拍板提前开发）
> 接口契约：docs/api.md §客户管理（GET /api/tenant/customers）
> 状态：✅ **已定案，实测通过，已提交**

---

## 1. 关键决策（已与用户确认 / 已对齐）

| 项 | 决策 |
|----|------|
| 本轮范围 | 仅列表页（加载 / 搜索 + 等级筛选 / scope 切换 / 无限滚动 / 下拉刷新 / 空态 / 错误态） |
| level 枚举 | **以 api.md 为准**：`normal` / `important` / `vip` / `lost`（非 doc17 的 A/B/C/D）。筛选 Tag 与卡片标签按此映射 |
| convertedAt 类型 | **Unix 秒数字**（如 `1700000000`），非 doc17 的字符串日期。前端 `fromMillisecondsSinceEpoch(sec*1000)` 解析 → `YYYY-MM-DD` |
| 搜索参数 | **`q`**（同线索列表做法），非空才传（避免空 `q` 触发 400，参考通话记录踩坑） |
| 详情页 | **本轮不开发**；列表卡片**直接跳线索详情** `LeadDetailPage(leadId:)`（用户实测后拍板） |
| scope 切换 | TE 固定 `mine`（隐藏切换按钮）；TM/TA（`tenant_admin`/`tenant_manager`）显示切换「我的/全部」 |
| company 字段 | 后端**确实返回** `company` 字段（实测确认），但多为 null。按 doc17 §7 既有规则「公司为空 → 隐藏该行」容错 |
| 等级筛选 UI | 实测后从横滚 Chip **改为通栏**：5 项等宽 `Expanded` 分段控件占满 100% 宽度 |
| 等级标签映射 | normal→普通(success)、important→重要(brand)、vip→VIP(warning)、lost→流失(error)；空/none 不显示标签 |
| 脱敏 | 前端原样渲染后端返回（TE 下可能看到脱敏 `138****1234`，属正常后端行为） |
| 搜索交互 | 采用「回车或点按钮才发请求」（与线索/通话记录一致），**非** doc17 原文的 500ms 防抖——更稳、规避每字打接口 + 空 `q` 风险 |
| scope 切换 UI | 用 Flutter 原生 `PopupMenuButton`（**不用 TDPicker/TDesign**，规避此前 TDesign 弹层崩溃黑历史） |

> ⚠️ **真机实测核字段**：开发后装真机，用 Alice 浮标抓 `GET /api/tenant/customers` 响应，核对 `level` / `convertedAt` / `company` / `leadId` 实际返回结构与类型。若与 api.md 不符，立即按实测调整模型，不猜测。

---

## 2. 接口依赖

### 2.1 GET /api/tenant/customers（新增 `CustomerService.fetchCustomers`）

```
GET /api/tenant/customers

query:
  erased   = 0            (固定，排除已擦除)
  scope    = mine | all   (TE 强制 mine；TM/TA 可切)
  q        = 关键词        (选填，非空才传；姓名/电话/公司模糊搜)
  level    = normal|important|vip|lost  (选填，空=全部)
  sort     = -convertedAt (默认，转化日期降序)
  page     = 1
  size     = 20
响应包裹：{success, data:{items:[Customer], total, page, size, pages}}
```

**Customer 模型字段（来自 api.md 1702-1714 列表响应）：**
```
id, tenantId, leadId, name, phone, ownerId,
level(normal/important/vip/lost), convertedAt(Unix秒),
createdAt, updatedAt, deletedAt, erasedAt
+ company(String?)  // 容错：列表响应可能缺失
```

**边界（doc17 §7）：** 姓名空→"未命名客户"；电话空→"无联系电话"；公司空/缺失→隐藏公司行；转化日期空→"转化日期: —"；等级空→不显示标签。

---

## 3. 文件清单

### 3.1 新建

| 文件 | 说明 |
|------|------|
| `lib/models/customer.dart` | Customer 模型（fromJson + 展示用 getter：displayName / levelLabel / levelColor / convertedAtLabel） |
| `lib/services/customer_service.dart` | `CustomerService.fetchCustomers`，参考 `lead_service.fetchLeads` 的脱敏/分页封装 |
| `lib/providers/customer_service_provider.dart` | Riverpod provider（参考 `call_service_provider`） |
| `lib/pages/customers/customer_list_page.dart` | 列表主页（ConsumerStatefulWidget，参考 `call_records_page`） |
| `lib/pages/customers/widgets/customer_card.dart` | 客户卡片（4 行：姓名+等级标签 / 电话 / 公司 / 转化日期） |
| `lib/pages/customers/widgets/customer_filter_bar.dart` | 等级筛选通栏分段控件（全部/普通/重要/VIP/流失，5 项等宽占满 100%） |
| `lib/pages/customers/widgets/customer_search_bar.dart` | 搜索框（手机号键盘 + 清空 + 搜索按钮，参考 `call_search_bar`） |
| `lib/pages/customers/widgets/customer_list_skeleton.dart` | 骨架（5 条，参考 `call_list_skeleton`） |

### 3.2 修改

| 文件 | 改动 |
|------|------|
| `lib/services/api_constants.dart` | 补 `static const String customers = '/api/tenant/customers';` |
| `lib/pages/profile/profile_page.dart` | 「客户列表」菜单项 `ComingSoonPage` → `CustomerListPage()`（新增 import） |

---

## 4. 交互流程

| 流程 | 行为 |
|------|------|
| 初始加载 | 骨架 → `fetchCustomers(scope=mine, sort=-convertedAt, page=1)` → 渲染 → 隐藏骨架 |
| 搜索 | 输入 + 回车/点「搜索」→ 非空才带 `q` 重请求（page 重置 1）→ 骨架 |
| 等级筛选 | 点 Tag → 切换选中 → 带 `level` 重请求（page 重置 1）→ 骨架 |
| scope 切换（TM/TA） | 右上 `PopupMenuButton` 选「我的/全部」→ 带 `scope` 重请求（page 重置 1）→ 骨架，按钮文字更新 |
| 下拉刷新 | `RefreshIndicator` → 重请求（保持筛选，page 重置 1）→ 刷新列表 |
| 无限滚动 | 距底 < 200px 且 `page < pages` → 转圈 → `fetchCustomers(page+1)` → 追加；到底显示「没有更多了」 |
| 空态 | 搜索无结果→「未找到匹配的客户」+「清除搜索」；无数据→「暂无客户」 |
| 错误态 | 失败→错误插图 + 「重试」 |

---

## 5. 边界情况

| 场景 | 处理 |
|------|------|
| 姓名为空 | 显示「未命名客户」 |
| 电话为空 | 显示「无联系电话」 |
| 公司为空/字段缺失 | 隐藏公司行（容错，不阻塞） |
| 转化日期为空/0 | 显示「转化日期: —」 |
| 等级为空/none | 不显示等级标签 |
| 空 `q` | 不传 q（避免 400） |
| TE 尝试切换 scope | 前端隐藏切换按钮，后端也做权限校验 |
| 列表返回 | 保持搜索 / 筛选 / scope / 滚动位置 |

---

## 6. 本轮不做（下轮无 doc18 客户详情，拍板不开发）

- ~~客户详情页~~ — 不开发，点卡片直接跳 `LeadDetailPage(leadId:)`（同通话记录决策）
- 客户编辑 / 删除 / 分配 / 擦除（DELETE/PATCH/assign/erase 端点）

---

## 7. 真机实测清单（开发后）

1. 个人中心 → 客户列表，列表正确加载（默认 mine + 转化日期降序）。
2. **抓包核对**：`GET /api/tenant/customers` 响应含 `level`/`convertedAt`/`company?`/`leadId` 实际结构与类型（重点验证 level 枚举值、convertedAt 是否为 Unix 秒、company 是否返回）。
3. 卡片：姓名 / 等级标签配色正确 / 电话 / 公司（若有）/ 转化日期格式 `YYYY-MM-DD`。
4. 搜索：输入关键词 + 回车/点按钮 → Alice 见 `q=xxx` 请求且出数据；清空 → 恢复。
5. 等级筛选：点「重要」等 → 列表按 level 过滤；点「全部」恢复。
6. scope 切换（TM/TA 账号）：切「全部」→ 列表变全量；切「我的」恢复。TE 账号不显示切换按钮。
7. 下拉刷新 / 无限滚动 / 空态 / 错误重试正常。

---

## 8. 待确认 / 风险

- **company 字段**：api.md 列表响应未列 `company`，doc17 却要求显示。已用「空则隐藏」容错，但**真机需验证后端到底返不返 company**（实测第 2 项）。若后端确实不返，卡片第三行将始终隐藏，属预期容错表现。
- **scope 切换可见性**：当前测试账号角色需真机确认是 TE 还是 TM/TA，决定能否看到切换按钮（代码已按 role 判断，两种都正确）。
