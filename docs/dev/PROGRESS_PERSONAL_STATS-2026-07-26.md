# 进度：个人统计页（v0.32）

> 计划：`docs/dev/PLAN_32_PERSONAL_STATS.md`
> 设计文档：`docs/design/page-design/14-个人统计.md`（v1.1，已按评审整改）
> 入口：个人中心 → 「我的业绩」卡（ProfileStatsCard onTap）+ 「个人统计」菜单项（`profile_page.dart:200`），此前均为 ComingSoon 占位。

## 1. 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 数据模型 `personal_stats.dart` | ✅ | 映射 `GET /api/tenant/stats/mine` 响应：`leadsTotal/followed/answered/noAnswer/converted/conversionRate` + 嵌套 `myToday{followupCount,answeredCount}`；`_int`/`_num` 安全转换（兼容 int/double/数字字符串/null）；`conversionRateDisplay`/`conversionProgress`/`conversionSummary` 派生 |
| 服务层 `home_service.dart`（扩展） | ✅ | 新增 `fetchPersonalStats({required dateFrom, required dateTo})`，复用既有 `dio` + `ApiConstants.statsMine`（与 `fetchMyStats` 同端点，**不新建 Service**） |
| 状态管理 `personal_stats_provider.dart` | ✅ | `PersonalStatsNotifier` + 日期范围（今日/本周/本月/自定义）+ 5 分钟按范围 key 内存缓存（sentinel `_Unset`/`_unset` 模式，同构 `team_stats_provider`） |
| 页面 `personal_stats_page.dart` | ✅ | `ConsumerWidget`：AppBar「个人统计」+ 刷新按钮 + 吸顶日期选择 + 滚动区；错误态 `AppErrorBody` + 骨架屏 `_StatsSkeleton`（呼吸灰块，复用 team_stats 写法） |
| 今日概况 `today_overview.dart` | ✅ | 2 卡（今日跟进/今日接通），`BrandColors.primarySurface` 底 + `primary` 32sp Bold 数字，固定不随日期 Tab 变化 |
| 数据详情 `detail_grid.dart` | ✅ | 2×3 白卡（线索总数/跟进数/接通数/未接数/转化数/转化率），`formatBigNumber`（≥10000 转"万"）+ 转化率卡 accent 用 `primary` |
| 转化率环 `conversion_ring.dart` | ✅ | `CircularProgressIndicator`（strokeWidth:12，背景 `line` + 填充 `primary`，value=`conversionProgress`）中心叠 28sp Bold 百分比 + 下方 `conversionSummary` |
| 日期选择器 `date_range_selector.dart` | ✅ | 改造自 team stats 版本；吸顶 ChoiceChip（今日/本周/本月/自定义）；放宽 90 天上限（设计允许超 1 年），仅拦截 `from>to`；自定义范围用 `showDateRangePicker`（firstDate=1 年前） |
| 入口接线 `profile_page.dart:200` | ✅ | 「个人业绩」卡 onTap 由 `ComingSoonPage('个人统计')` → `PersonalStatsPage()` |
| 入口接线 `profile_stats_card.dart` | ✅ | 卡 onTap 由传入方（`profile_page`）统一改为 `PersonalStatsPage()` |

## 2. 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 接口字段疑云 | 直接按 PLAN_32 建页 | api.md 声明的 5 个区间字段（`myFollowed/myAnswered/myNoAnswer/myConverted/myConversionRate`）本地从未解析；用户在 AskUserQuestion 直接贴真机抓包 JSON 证实字段齐全，风险消除 |
| 转化率口径 | 直接展示后端 `myConversionRate`，前端不二次计算 | 与团队统计不同（团队前端算 `Σconverted/ΣownedLeads`）；后端已兜底分母为 0 返 0 |
| 服务层 | 复用 `HomeService`（非新建 Service） | 同端点 `statsMine`，避免重复 Dio/拦截器配置 |
| 缓存策略 | 5 分钟按范围 key + sentinel | 同构 `team_stats_provider`，切 Tab/范围命中缓存不重加载，避免重复请求 |
| 日期范围上限 | 放宽 90 天上限 | 设计文档允许超 1 年；仅拦截 `from>to` 静默忽略 |
| 今日概况独立性 | 固定展示 `myToday`，不随 Tab 变化 | 设计文档 §1：今日实时数据 vs 区间累计数据两区相互独立 |

## 3. 接口契约核对（已真机证实）

请求：`GET /api/tenant/stats/mine?dateFrom=&dateTo=`（YYYY-MM-DD，必传）。

响应 `data`（用户真机抓包证实）：

```
{
  "myLeadsTotal": 116, "myFollowed": 6, "myAnswered": 1,
  "myNoAnswer": 0, "myConverted": 0, "myConversionRate": 0,
  "myToday": { "followupCount": 0, "answeredCount": 0 }
}
```

| 字段 | 用途 | 展示位置 |
|------|------|----------|
| `myLeadsTotal` | 线索总量 | 数据详情卡 + 转化率分母 |
| `myFollowed` / `myAnswered` / `myNoAnswer` / `myConverted` | 区间累计 | 数据详情 4 卡 |
| `myConversionRate` | 转化率 % | 转化率环（直接展示） |
| `myToday.followupCount` / `answeredCount` | 今日实时 | 今日概况 2 卡 |

## 4. 验证

| 验证项 | 结果 |
|------|------|
| `flutter analyze`（个人统计相关 6 文件） | No issues found |
| `flutter analyze`（全仓） | 0 error；仅 `token_storage.dart` 11 个 `!` 基线 warning（web 存储修复遗留，无关） |
| 构建 | `flutter build apk --release --dart-define=DEV_TOOLS=true` → `app-release.apk` 62.3MB |
| 装真机 | `adb install -r` 到 Redmi K60（`3e06fd6d`）Success |
| 真机实测 | ✅ 通过（用户确认测试通过） |

## 5. 改动文件清单

| 文件 | 改动类型 |
|------|---------|
| `lib/models/personal_stats.dart` | 🆕 新建 |
| `lib/providers/personal_stats_provider.dart` | 🆕 新建 |
| `lib/services/home_service.dart` | ✅ 扩展（新增 `fetchPersonalStats`） |
| `lib/pages/personal_stats/personal_stats_page.dart` | 🆕 新建 |
| `lib/pages/personal_stats/widgets/date_range_selector.dart` | 🆕 新建 |
| `lib/pages/personal_stats/widgets/today_overview.dart` | 🆕 新建 |
| `lib/pages/personal_stats/widgets/detail_grid.dart` | 🆕 新建 |
| `lib/pages/personal_stats/widgets/conversion_ring.dart` | 🆕 新建 |
| `lib/pages/profile/profile_page.dart` | ✅ 修改（入口 onTap） |
| `lib/pages/profile/widgets/profile_stats_card.dart` | ✅ 修改（onTap 目标，由调用方传入） |

## 6. 踩坑记录

详见 `docs/dev/DEVELOPMENT_PITFALLS.md §15`：

- **§15**：骨架屏里写 `const Expanded(child: _box(height: 90))` 报 `const_eval_method_invocation`——`Expanded` 被标 `const` 但 `child` 是 `_box(...)` 方法调用（非构造器），编译期无法求值。去掉 `Expanded` 上的 `const` 即可；注意 `_box` 是实例方法不是类，不能 `const` 调用。

## 7. 待开发（非阻塞）

- KGP 告警（`package_info_plus`/`sensors_plus`/`share_plus`）按方案 A 暂接受。
- 团队视图日期筛选（v0.24 放弃项）留待后续。
- 全端 ComingSoon 残留：个人统计整页已建，入口已全部接线，无残留占位。
