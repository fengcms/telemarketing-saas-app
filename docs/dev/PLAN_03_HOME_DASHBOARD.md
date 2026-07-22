# 开发计划：03-首页看板

> 设计文档：`docs/design/page-design/03-首页看板.md`  
> 接口文档：`docs/api.md`  
> 预计工时：2d

---

## 一、前置依赖改动

### 1.1 新增模型

| 文件 | 说明 |
|------|------|
| `lib/models/home_stats.dart` | 首页统计数据模型（myToday、myLeadsTotal） |
| `lib/models/schedule.dart` | 日程模型（id、title、content、scheduledAt、status、lead） |

**HomeStats 模型字段：**

```dart
class HomeStats {
  final int followupCount;  // 今日跟进
  final int answeredCount;  // 今日接通
  final int myLeadsTotal;   // 我的线索
  final int dueToday;       // 今日待办（来自 schedules/stats/mine）
}
```

**Schedule 模型（首页仅用部分字段）：**

```dart
class Schedule {
  final String id;
  final String title;
  final String? content;
  final int scheduledAt;    // Unix 秒
  final String status;      // pending / completed / cancelled
  final ScheduleLead? lead; // 关联线索（可选）
}
```

### 1.2 新增 Service 方法

**文件：** `lib/services/home_service.dart`（新建）

| 方法 | 调用的接口 | 说明 |
|------|-----------|------|
| `fetchMyStats(dateFrom, dateTo)` | `GET /api/tenant/stats/mine` | 今日统计 |
| `fetchPendingSchedules()` | `GET /api/tenant/schedules?status=pending&page=1&size=5&sort=scheduledAt` | 待办预览 |
| `fetchMyScheduleStats()` | `GET /api/tenant/schedules/stats/mine` | 日程统计（dueToday） |
| `fetchDueSoonCount(now)` | `GET /api/tenant/schedules?status=pending&scheduledAt__gte={now}&scheduledAt__lte={now+1800}&page=1&size=1` | 到期检测 |

### 1.3 新增 Provider

**文件：** `lib/providers/home_provider.dart`（新建）

| Provider | 类型 | 说明 |
|----------|------|------|
| `homeServiceProvider` | `Provider<HomeService>` | HomeService 实例 |
| `homePageProvider` | `StateNotifierProvider` | 首页聚合状态（stats + schedules + loading/error） |

**首页状态定义：**

```dart
class HomePageState {
  final bool isLoading;
  final HomeStats? stats;
  final List<Schedule>? schedules;
  final int scheduleTotal;    // 日程总数（用于 Badge）
  final int dueSoonCount;     // 即将到期日程数
  final bool isLoadingStats;  // 统计区域独立加载态
  final bool isLoadingSchedules; // 日程区域独立加载态
  final String? statsError;
  final String? schedulesError;
  final bool isOffline;
  final bool isDueSoonBannerClosed; // 用户已关闭到期提醒条
  final int serverTime;       // 缓存的服务端时间
}
```

### 1.4 添加依赖

`pubspec.yaml` 中添加 `connectivity_plus`（离线检测）。

---

## 二、UI 开发步骤

### Step 1：HomePage 骨架重构

**文件：** `lib/pages/home/home_page.dart`（全部重写）

- 从 `ConsumerWidget` 改为 `ConsumerStatefulWidget`（需处理生命周期、轮询）
- 整体布局：`Scaffold` → `Column([TDNavBar, 提示条区域, Expanded(可滚动区域)])`
- 不再简单的 AppBar，改用 TDNavBar

### Step 2：TDNavBar

| 组件 | 说明 |
|------|------|
| 背景色 | `brand-7 #0052D9`，56px 高度 |
| 标题 | "首页"，左对齐，白色 20sp |
| 通知图标 | 隐藏（MVPhase） |
| 团队看板按钮 | 仅 TM/TA 显示，TDButton(text) 白色文字 14sp，TE 隐藏 |
| 退出按钮 | ⚠️ 保留 MVP 阶段方便测试 |

### Step 3：离线提示条 + 日程到期提醒条

**离线提示条：**
- 使用 `connectivity_plus` 监听网络状态
- 断网时滑入（warning-1 背景），恢复时滑出
- 200ms easeOut 动画

**日程到期提醒条：**
- 条件渲染，brand-1 背景
- 显示 "您有 N 条日程即将到期"
- 可关闭（关闭后当次会话不再显示）
- 点击跳转日程 Tab

### Step 4：今日概况 Section

白色卡片容器（shadowMedium），含：

- **Section 头部**："今日工作概况" 标题 + 日期标签（如 "7月23日 周三"）
- **2x2 网格**（4 个 StatCard）：
  - 左上：今日待办（dueToday）
  - 右上：今日跟进（followupCount）
  - 左下：今日接通（answeredCount）
  - 右下：我的线索（myLeadsTotal）

**StatCard 规格：**
- 灰色背景（gray-1 #F3F3F3），圆角 8px
- 数字 32sp Bold brand-7 色，标签 13sp gray-6 色
- 数字 ≥ 1000 显示 "999+"
- 首次加载骨架屏 → 数据，轮询时数字滚动动画 300ms

### Step 5：待办日程 Section

白色卡片容器（shadowMedium），含：

- **Section 头部**："待办日程" + TDBadge（dueToday 数值）+ "查看全部 >" 按钮
- **日程条目列表**（最多 5 条）：
  - 左侧时间（14:30），逾期时变 error-7 红色
  - 中间标题 + 线索名，逾期时文字变红色
  - 右侧 "已逾期" 标签（仅逾期时显示，error-1 背景）
  - 可点击 → 跳转日程详情（预留）
  - 分割线（有缩进）
- **空态**：TDEmpty "暂无待办日程" + 副文案
- **加载态**：3 个骨架占位

### Step 6：快捷入口 Section

白色卡片容器（shadowMedium），含：

- 2x1 网格：
  - 我的线索（TDIcons.task，副标题 "128 条"）
  - 通话记录（TDIcons.call，无副标题）
- 点击 → 跳转到对应 Tab/页面

### Step 7：轮询 + 后台监听

| 功能 | 实现方式 |
|------|---------|
| 10 分钟轮询 | `Timer.periodic(Duration(minutes: 10))` |
| APP 前后台切换 | `WidgetsBindingObserver.didChangeAppLifecycleState` |
| 后台回前台超 10 分钟 | 立即触发刷新 |
| 跨午夜检测 | 页面首次加载时记录日期，轮询时比较日期是否变化 |
| 请求去重 | 同一接口并发请求时取消旧请求（使用 cancel token） |

### Step 8：错误态

| 区域 | 错误表现 |
|------|---------|
| 统计区域 | "⚠ 加载失败" + "[重试]" 按钮 |
| 日程区域 | "⚠ 加载失败" + "[重试]" 按钮 |
| 下拉刷新失败 | TDToast 提示（全部失败/部分失败） |

---

## 三、接口清单

| # | 端点 | 方法 | 触发时机 |
|---|------|------|---------|
| 1 | `GET /api/tenant/stats/mine?dateFrom=...&dateTo=...` | 首页 4 项统计数字 | 首屏/下拉/轮询 |
| 2 | `GET /api/tenant/schedules?status=pending&page=1&size=5&sort=scheduledAt` | 待办日程列表 | 首屏/下拉/轮询 |
| 3 | `GET /api/tenant/schedules/stats/mine` | dueToday（四宫格+Badge） | 首屏/下拉/轮询 |
| 4 | `GET /api/tenant/schedules?status=pending&scheduledAt__gte=...&scheduledAt__lte=...&page=1&size=1` | 到期日程检测 | 首屏/下拉/轮询 |

---

## 四、开发顺序

```
模型(Schedule/HomeStats) → HomeService → HomeProvider
  → 首页骨架+TDNavBar → 今日概况Section → 待办日程Section
  → 快捷入口Section → 提示条(离线/到期) → 轮询+后台监听
  → 状态完善(加载/错误/空态) → 真机测试
```

---

## 五、待确认问题

| # | 问题 | 说明 |
|---|------|------|
| 1 | 退出按钮是否保留？ | 当前首页有退出按钮方便测试，正式版是否移除或隐藏？ |
| 2 | `dueToday` 兜底字段 | 设计文档说 `dueToday` 字段上线前以 `byStatus.pending` 兜底。后端是否已上线？ |
| 3 | 通话记录页路由 | 快捷入口"通话记录"跳转目标是独立页面还是"我的" Tab 内子页面？ |

---

> 计划版本：v1 | 编制日期：2026-07-22
