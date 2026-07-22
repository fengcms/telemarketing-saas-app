# 开发计划：04-线索列表页

> 设计文档：`docs/design/page-design/04-线索列表.md`  
> 接口文档：`docs/api.md`  
> 预计工时：3d

---

## 一、涉及接口

| # | 端点 | 方法 | 用途 |
|---|------|------|------|
| 1 | `GET /api/tenant/leads` | GET | 线索列表（分页+搜索+筛选+排序） |
| 2 | `GET /api/tenant/options/categories` | GET | 筛选面板-分类选项 |
| 3 | `GET /api/tenant/options/projects` | GET | 筛选面板-项目选项 |
| 4 | `GET /api/tenant/options/users` | GET | 筛选面板-归属人选项（TM/TA） |

---

## 二、新增文件

| 文件 | 说明 |
|------|------|
| `lib/models/lead.dart` | 线索模型（id、name、phone、status、category、project、owner、lastFollowupAt、nextFollowupAt） |
| `lib/models/option_item.dart` | 下拉选项通用模型（id + name） |
| `lib/services/lead_service.dart` | 线索相关接口封装 |
| `lib/providers/lead_list_provider.dart` | 线索列表状态管理（搜索/筛选/排序/分页） |

---

## 三、LeadListProvider 状态设计

```dart
class LeadListState {
  final bool isLoading;           // 首屏加载
  final List<Lead> leads;         // 当前列表数据
  final int total;                // 总数
  final int currentPage;          // 当前页码
  final bool isLoadingMore;       // 加载更多中
  final bool hasMore;             // 是否还有更多
  final String? keyword;          // 搜索关键词
  final String? statusFilter;     // 状态筛选
  final String? categoryId;       // 分类筛选
  final String? projectId;        // 项目筛选
  final int? dateFrom;            // 时间段起始
  final int? dateTo;              // 时间段截止
  final String sortBy;            // 排序：-updatedAt / nextFollowupAt
  final String? errorMessage;     // 错误信息
  final List<OptionItem> categories; // 缓存的分类选项
  final List<OptionItem> projects;   // 缓存的项目选项
}
```

**核心方法：**
- `loadInitial()` — 首屏加载（page=1，清空旧数据）
- `loadMore()` — 加载下一页（page+1，追加数据）
- `search(String keyword)` — 搜索（500ms 防抖）
- `toggleSort()` — 切换排序
- `applyFilters(...)` — 应用筛选条件
- `clearFilter(String key)` — 移除单个筛选
- `resetFilters()` — 清空全部筛选
- `refresh()` — 下拉刷新

---

## 四、UI 开发顺序

### Step 1：页面骨架 + TDNavBar
- `LeadsListPage` (ConsumerStatefulWidget)
- TDSearchBar（胶囊形，搜索线索姓名/电话/公司）
- 排序按钮 + 筛选漏斗按钮

### Step 2：筛选标签栏
- 横向滚动 TDCheckTag 组
- 条件渲染：有筛选条件时显示
- 点击 × 移除筛选

### Step 3：线索卡片
- 5 行布局（姓名+状态 / 电话 / 分类+项目 / 时间+徽章 / 归属人(TM/TA)）
- 5 种状态标签配色
- 跟进倒计时徽章（今日可打/N天后/已逾期）
- 时间格式化（刚刚/N分钟前/N小时前/昨天/MM-DD）

### Step 4：筛选面板 + 排序弹窗
- TDPopup 底部弹出
- 状态（前端枚举）/ 分类 / 项目 / 时间段
- 排序弹窗（最近更新 / 待跟进优先）
- 确定 + 重置按钮

### Step 5：无限滚动 + 下拉刷新
- ScrollController 监听底部阈值
- 加载锁防重复请求
- RefreshIndicator 下拉刷新

### Step 6：状态处理
- 首屏骨架屏（3~4 个骨架卡片）
- 空态（无线索 / 搜索无结果）
- 错误态 + 重试按钮

---

## 五、注意点

| # | 要点 |
|---|------|
| 1 | scope 参数：TE 固定 `mine`，TM/TA 固定 `all`，由 AuthNotifier 用户角色决定 |
| 2 | `erased=0` 固定追加到所有请求 |
| 3 | 搜索防抖 500ms，按回车立即触发 |
| 4 | 加载锁防止快速滚动时重复请求 |
| 5 | 选项数据（分类/项目）需缓存，避免每次打开筛选面板都请求 |
| 6 | 切换 Tab 保留列表状态（关键词、筛选、排序、滚动位置） |
| 7 | 姓名/电话脱敏由后端返回，前端不做额外处理 |

---

> 计划版本：v1 | 编制日期：2026-07-22
