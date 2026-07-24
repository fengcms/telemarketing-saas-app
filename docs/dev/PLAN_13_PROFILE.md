# 开发计划：个人中心页（doc 13）

> 规划依据：[13-个人中心](../../docs/design/page-design/13-个人中心.md)
> 接口依据：[api.md](../../docs/api.md) · [00-全局API约定](../../docs/design/page-design/00-全局API约定.md)
> 复审结论：A（已放行，进入下一功能开发）
> 制定日期：2026-07-24

---

## 一、目标与范围

重构底部 Tab「我的」（当前为 `main_shell.dart` 的 `_ProfileTab` 临时占位页），实现 doc 13 规格的完整个人中心页：

- 用户信息区（头像 / 姓名 / 角色标签 / 邮箱 / **所属租户**）
- 我的业绩概览（**4 列真实数据**，见 §三决策）
- 功能入口（通话记录 / 客户列表 / 设置 → 子页本轮不做，跳 `ComingSoonPage` 占位）
- 团队入口（仅 TM/TA 可见：团队统计 → 跳 `ComingSoonPage` 占位）
- 下拉刷新（重新拉个人统计）
- 退出登录（保留原 `_ProfileTab` 逻辑）

**本轮不做**：通话记录(doc 16) / 客户列表(doc 17) / 设置(doc 19) / 团队统计(doc 21) / 个人统计(doc 14) 五个子页，入口均跳 `ComingSoonPage(featureName:)` 占位，后续迭代。

---

## 二、现状核查（已核实，非猜测）

| 项 | 结论 | 证据 |
|----|------|------|
| 底部「我的」现状 | `_ProfileTab` 占位页（头像+邮箱+退出），无业绩/入口/团队区 | `lib/pages/main_shell.dart:112` |
| 个人统计接口 | `GET /api/tenant/stats/mine?dateFrom&dateTo`，真实返回 `data.myLeadsTotal` + `data.myToday.followupCount` + `data.myToday.answeredCount` | `lib/services/home_service.dart:32` + `lib/models/home_stats.dart:23` |
| 今日待办 | `scheduleStatsProvider.dueToday`，源 `GET /api/tenant/schedules/stats/mine`，与日程角标同源 | `lib/providers/schedule_stats_provider.dart:65` |
| 用户信息 | `authProvider.user` → name / email / role（本地缓存） | `lib/models/user.dart` |
| 租户名 | 登录响应未缓存；`GET /api/tenant/profile` 的 `data.name` 即租户名；现有 `tenantService.fetchProfile()` 只返回 `settings`，**无外部调用方** | `lib/services/tenant_service.dart:14` + `docs/api.md:516` |
| 子页占位 | `ComingSoonPage(featureName:)` 可直接跳转，已有先例 | `lib/pages/coming_soon_page.dart:22` |
| TDesign 组件 | `TDCell` / `TDAvatar` / `TDRefreshHeader` / `TDSkeleton` 项目**零先例**；列表行用 `ListTile`（线索列表）与自定义 `Container`（日程列表） | grep 全工程为空 |

---

## 三、接口与数据映射（含两项已确认决策）

### 3.1 业绩概览 4 列（用户决策：用真实数据）

| 列 | 标签 | 数据源 | 真实字段 |
|----|------|--------|----------|
| 1 | 我的线索 | `stats/mine` | `data.myLeadsTotal` |
| 2 | 今日跟进 | `stats/mine` | `data.myToday.followupCount` |
| 3 | 今日接通 | `stats/mine` | `data.myToday.answeredCount` |
| 4 | 今日待办 | `schedules/stats/mine`（复用共享 provider） | `dueToday` |

> 说明：设计文档 doc 13 §3.3/§6.1 写的是 `myFollowed`(累计跟进) / `myAnswered`(累计接通) / `myConverted`(转化)，与真实接口不符（真实只有**今日**口径、且无转化字段）。已与用户确认：**对齐真实接口，4 列用上述真实数据**，视觉保留设计文档 4 列布局。

### 3.2 所属租户（用户决策：展示，取自 profile 接口）

- 字段：`GET /api/tenant/profile` → `data.name`
- 改造：`tenant_service.dart` **新增** `fetchTenantName()` 返回 `String`（不动原 `fetchProfile`，保持 settings 口径不变）；无外部调用方，安全。

### 3.3 用户信息

- `authProvider.user.name` / `.email` / `.role`（本地缓存，无需网络）
- 角色标签中文映射：`TE`→电销专员，`TM`→团队经理，`TA`→团队助理（doc 13 用 `[TE]` 标签样式）

---

## 四、页面结构实现（对齐设计文档，复用项目已有模式）

> 设计文档大量引用 `TDNavBar / TDCell / TDAvatar / TDTag / TDRefreshHeader / TDSkeleton`，但项目无先例且 TDesign 0.2.7 有兼容坑（见 `DEVELOPMENT_PITFALLS.md`）。**全部改用项目已验证模式**，视觉对齐设计文档。

| 设计组件 | 实现方式 | 依据 |
|----------|----------|------|
| TDNavBar「我的」 | `AppBar`（蓝底白字，main_shell 已有模式） | `main_shell.dart` |
| 头像 TDAvatar | `CircleAvatar`（姓名首字，蓝底白字） | `main_shell.dart:135` |
| 角色标签 TDTag | 自定义 `Container`（圆角小标签，brand-1 底 brand-7 字） | 日程状态标签同款 |
| 业绩概览 4 列 | 自定义 `Row` + 4×`Expanded`（数字 brand-7 20px Bold + 标签 gray-6 12px），背景 gray-1 圆角 | 纯自定义，无组件依赖 |
| 功能入口 TDCell | 自定义 `Container` 行（左 `Icon` 20px gray-6 + 标题 16px + 右 `Icons.chevron_right` + 底 `Divider` 缩进） | 日程列表行同款 Container |
| 团队入口 | 同上，TM/TA 时渲染；上方加 `Divider` 分隔 | doc 13 §3.5 |
| 下拉刷新 TDRefreshHeader | Flutter 原生 `RefreshIndicator`（日程详情页已用） | `schedule_detail_page.dart` |
| 骨架屏 TDSkeleton | 复用项目 `ShimmerBlock`（白卡片 + shimmer，对齐日程详情风格） | `schedule_detail_cards.dart` |
| 错误态 | 统计区「数据加载失败，点击重试」+ 网络断开 `TDToast` | doc 13 §5.3 |

### 4.1 加载流程

```
进入页面 / 下拉刷新
  → 显示骨架屏（用户信息区 + 业绩区）
  → 并行：
      1. authProvider.user（本地，同步取 name/email/role）
      2. tenantService.fetchTenantName() → 所属租户
      3. homeService.fetchMyStats(today) → 线索/今日跟进/今日接通
      4. scheduleStatsProvider.load()（幂等）→ dueToday（今日待办）
  → 渲染完整内容；TE 隐藏团队入口
```

### 4.2 角色动态显示

```
if role == 'TE' → 不渲染「团队统计」入口
if role in ['TM','TA'] → 渲染「团队统计」入口
```

---

## 五、文件改动清单

| 动作 | 文件 | 说明 |
|------|------|------|
| 新增 | `lib/pages/profile/profile_page.dart` | 个人中心页主体（ConsumerStatefulWidget），含用户信息区 / 业绩概览 / 功能入口 / 团队入口 / 下拉刷新 / 骨架屏 / 退出登录。控制在 **560 行红线**内，超则抽 widget 到 `lib/pages/profile/widgets/` |
| 改 | `lib/services/tenant_service.dart` | 新增 `fetchTenantName()` → `data['name']` 字符串 |
| 改 | `lib/pages/main_shell.dart` | `_ProfileTab` 替换为 `ProfilePage()`（内部自行读 `authProvider`，删除原占位类） |
| 引用 | `lib/pages/coming_soon_page.dart` | 五个子页入口跳转占位（不改，仅引用） |

> 不新增独立 `profile_provider`：页面内 `_load()` 直接调 `homeService` + `tenantService` + watch 共享 `scheduleStatsProvider`，避免重复请求与过度设计；若后续子页（个人统计）需要复用，再抽 provider。

---

## 六、风险与待验证

1. **TDesign 组件零先例**：已决策全部改用项目已验证模式，规避 0.2.7 兼容坑（参考 `TDCheckbox` 白屏、`IconData extends` 兼容问题）。
2. **dueToday 时序**：复用共享 `scheduleStatsProvider`，页面 `_load` 主动触发一次 `load()`（幂等），不依赖首页/日程 Tab 加载时序。
3. **行数红线**：`profile_page.dart` 若超 560 行，按 Sprint 复审结论立即抽 widget 文件（参考 `schedule_detail_cards.dart` / `schedule_form_fields.dart` 的 part 方案）。
4. **角色映射**：`TE/TM/TA` → 中文标签需与后端枚举严格对齐；若后端返回非预期值，按 doc 13 §7 默认按 TE 处理（隐藏团队入口）。

---

## 七、测试验证

1. `flutter analyze` 全工程 **0 issue**（Sprint 复审硬指标）。
2. `flutter build apk --debug --dart-define=DEV_TOOLS=true` 构建。
3. 装 Redmi K60 真机实测（沿用项目惯例）：
   - 用户信息区：姓名 / 角色标签 / 邮箱 / **所属租户名** 正确展示
   - 业绩概览 4 列：我的线索 / 今日跟进 / 今日接通 / 今日待办 数据正确（与首页看板口径一致）
   - 下拉刷新：统计区刷新正常
   - 角色可见性：TM/TA 见「团队统计」入口，TE 隐藏
   - 入口跳转：通话记录 / 客户列表 / 设置 / 团队统计 均跳 `ComingSoonPage` 占位
   - 退出登录：弹窗确认 → 跳登录页
   - 真机抓包（DEV_TOOLS 浮标）：确认 `stats/mine` + `profile` 请求正常、无 4xx/5xx
4. 写开发进度文档 + 踩坑文档，`git commit & push`。

---

## 八、后续迭代（不在本轮）

- doc 14 个人统计页（业绩概览点击跳转目标）
- doc 16 通话记录列表页（入口已暴露，原定"下一建议节点"）
- doc 17 客户列表 / doc 19 设置 / doc 21 团队统计

---

**确认后开始开发。开发完成 → 真机实测 → 文档 → commit & push。**
