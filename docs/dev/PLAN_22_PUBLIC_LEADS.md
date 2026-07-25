# 开发计划：v0.22 公海线索列表页（doc 06）

> **设计文档**：`docs/design/page-design/06-公海线索列表.md`
> **入口**：线索 Tab 顶部切换「我的线索 / 公海线索」
> **目标版本**：v0.22
> **计划日期**：2026-07-25
> **UI 框架**：Material 3（`UI_STYLE_GUIDE.md` v2.0）

---

## 一、页面概述

公海线索页**不是独立页面**，而是集成到已有 `leads_list_page.dart` 中，在顶部增加一个 TabBar 切换「我的线索 / 公海线索」两个数据源。

### TabBar 可见条件

- 用户角色 = TE（电销坐席）
- 租户配置 `allowSelfClaim=true`（从 `GET /api/tenant/profile` 读取）
- 不满足任一条件时，不显示 TabBar，退化为现有标准线索列表

### 布局结构

```
┌──────────────────────────────────────────┐
│ AppBar (蓝底，显示"线索")                 │
├──────────────────────────────────────────┤
│ [🔍 AppSearchBar]                        │  ← 共享搜索框
├──────────────────────────────────────────┤
│ ┌──────────┬────────────┐                │
│ │ 我的线索  │  公海线索  │                │  ← 新增 TabBar
│ └──────────┴────────────┘                │
├──────────────────────────────────────────┤
│                                          │
│  ┌────────────────────────────────┐      │
│  │ 公海线索卡片（含领取按钮）       │      │  ← scope=public 时的数据
│  │ 姓名     [待跟进] 标签           │      │
│  │ 电话                              │      │
│  │ 分类标签 项目名                    │      │
│  │ 最后更新: X天前                   │      │
│  │ ──────────────────────────        │      │
│  │                    [领取该线索]    │      │
│  └────────────────────────────────┘      │
│                                          │
│  ┌────────────────────────────────┐      │
│  │      [○] 加载中...             │      │
│  └────────────────────────────────┘      │
├──────────────────────────────────────────┤
│  TDBottomTabBar (系统导航栏)              │
└──────────────────────────────────────────┘
```

### TDesign → M3 组件映射

| 设计文档旧组件 | M3 替代 |
|--------------|---------|
| `TDTabBar` | 自绘 `Row` + `Expanded` 分段控件（对齐客户列表的等级筛选通栏风格） |
| `TDSearchBar` | `AppSearchBar` |
| 线索卡片 | 自绘（已有 `LeadCard` 组件，公海版增加领取按钮） |
| `TDButton(secondary)` | `FilledButton.tonal()` |
| `TDToast` | `AppToast` |
| `TDEmpty` | 自绘空态组件 |
| `TDSkeleton` | `ShimmerBlock` |

---

## 二、接口依赖

### 2.1 公海线索列表

```
GET /api/tenant/leads?scope=public&status=pending&erased=0&page=1&size=20
```

- **复用** `LeadService.fetchLeads()`（已有 `scope` 参数），传 `scope: 'public'`
- 排序默认 `-updatedAt`（最久未更新的排前，便于优先跟进）
- 响应结构与现有线索列表一致，`owner` 为 null

### 2.2 领取线索

```
POST /api/tenant/leads/:id/claim
```

- 请求体：无
- 已有 `ApiConstants` 中无此路径，需新增 `static const String leadClaim = '/api/tenant/leads/{id}/claim'` 或直接在 `LeadService` 中拼接
- 需要新增 `LeadService.claimLead(int leadId)` 方法
- 成功响应：`{ "success": true, "data": { "id": 10055, "ownerId": "7", "status": "assigned" } }`

### 2.3 租户配置（判断 allowSelfClaim）

- **复用** `TenantService.fetchProfile()`（已有），返回 `settings.allowSelfClaim` 字段

---

## 三、改动清单

### 3.1 新增/修改文件

| 文件 | 改动 |
|------|------|
| `lib/services/api_constants.dart` | 补 `leadClaim` 路径模板 `/api/tenant/leads/{id}/claim` |
| `lib/services/lead_service.dart` | 新增 `claimLead(int leadId)` 方法 |
| `lib/providers/lead_service_provider.dart` | 无需改动（已有 provider） |
| `lib/pages/leads/leads_list_page.dart` | **主要改动**：増加 TabBar 切换我的/公海线索 + 公海视图 + 领取功能 |
| `lib/pages/leads/widgets/lead_card.dart` | 新增公海版式（增加领取按钮，不显归属行）或同时支持两种模式 |
| `lib/widgets/lead_card.dart` | 如果已有 LeadCard，改造支持 isPublic 模式 |

### 3.2 主要改动内容（leads_list_page.dart）

由于单文件红线 560 行，当前文件接近上限，需考虑拆分方案：

**方案 A：加 TabBar 并在原文件内维护双状态**（可能超线）
**方案 B：抽离公共部分到 `leads_scope_provider.dart`，主文件保持双视图切换**

推荐方案 B，将获取公海/我的线索的列表逻辑抽离成两个独立的 provider，主文件只负责 Tab 切换和视图渲染。

### 3.3 公海线索卡片

公海卡片与我的线索卡片差异：

| 元素 | 我的线索 | 公海线索 |
|------|---------|---------|
| 状态标签 | 按实际状态显示 | 固定"待跟进" |
| 归属人 | 显示 | 不显示（无归属人） |
| 跟进计划 | 显示 nextFollowupAt 徽章 | 不显示 |
| 底部操作 | 无 | 「领取该线索」按钮 |
| 点击跳转 | LeadDetailPage | LeadDetailPage（scope=public） |

建议：修改 `LeadCard` 支持 `showType` 参数（`mine` / `public`），根据模式展示不同内容。

---

## 四、交互流程

### 4.1 切换到公海线索
1. 点击「公海线索」Tab
2. Tab 指示器切换
3. 搜索框占位文字切换为"搜索公海线索姓名/电话"
4. 列表显示骨架屏
5. 发起 `GET /api/tenant/leads?scope=public...`
6. 接口返回 → 渲染公海卡片

### 4.2 领取线索
1. 点击卡片上的「领取该线索」
2. 按钮进入 loading 态（防重复点击，不弹确认弹窗，设计文档 §2.3）
3. `POST /api/tenant/leads/:id/claim`
4. 成功 → `AppToast` "领取成功，已加入您的线索池"
5. 该卡片从列表中移除
6. 自动切换到「我的线索」Tab 并刷新

### 4.3 失败处理
| 错误 | 提示 |
|------|------|
| 线索已被领取（400） | "该线索已被领取" + 刷新列表 |
| 禁拨名单（422） | "该线索在禁拨名单中，无法领取" |
| 网络错误 | "网络异常，请重试" |

### 4.4 卡片点击
点击卡片信息区域（非领取按钮）→ 跳转 `LeadDetailPage(leadId: id)`（复用现有逻辑）

---

## 五、状态设计

| 状态 | 表现 |
|------|------|
| 首屏加载 | 骨架屏 |
| 公海无数据 | 空态 "当前公海没有可领取的线索" |
| 搜索无结果 | 空态 "未搜索到相关线索" |
| 加载失败 | 错误态 + 重试按钮 |
| 领取中 | 按钮显示 loading，disabled |

---

## 六、待确认事项

1. **现有的 `LeadCard` 在 `lib/widgets/lead_card.dart`（公共组件目录），需要改它支持公海模式，还是新建 `lib/pages/leads/widgets/public_lead_card.dart`？**
2. **领取成功后是否自动切换到「我的线索」Tab？** 设计文档 §4.5 说"自动切换到 TDTabBar「我的线索」Tab"，但用户习惯可能不想被打断。
3. **allowSelfClaim** 配置可通过 `TenantService.fetchProfile()` 获取（复用现有接口），返回数据中是否有此字段需要确认。

---

**本计划等待用户确认后进入开发。**
