# 电销工作台 APP — Sprint 审阅（2026-07-24）

> ## 🔄 状态标记：第四轮 · 日程模块 + 拨号 + 重构 + 权限修复
> 第一轮全量审阅已验收归档于 `docs/review/history/`；第二轮 `SPRINT-REVIEW-2026-07-23.md`（评级 A）；第三轮 `SPRINT-REVIEW-2-2026-07-23.md`（评级 A，趋势 A+）。
> 本批提交区间：`2388faa` → `024f8f4`（18 个提交）
> 审查人：Mobile App Builder（移动端小组组长）

## 一、审阅范围与客观验证

### 本批提交清单（18 个，按功能域归类）
| 提交 | 主题 | 实质内容 | 类型 |
|------|------|----------|------|
| `0ddf4cd` | fix(android): main 清单声明 INTERNET | **release 无法联网根因修复** + Alice 懒加载、踩坑 §9 | 🔴 阻塞修复 |
| `d29ea98` | feat(schedule): 日程列表页 v0.12 + 共享统计 + 底部角标 | 列表骨架屏/分组/分页/统计角标；Alice 浮窗+登录预填(dev) | feat |
| `f78125c` | fix(schedule): 日程列表真机实测修复合集 | 刷新变灰/缓存/TabCache/分组桶/骨架屏/吸顶头 | fix |
| `925c159` | feat(schedule): 日程详情页与新建/编辑表单 + v0.14 打磨 | 详情五区块+操作链+权限矩阵；表单抽屉；缓存优先；删旧 dialog | feat |
| `b764c34` | style(schedule): 统一视觉风格 + 修复两项 bug | 表单/抽屉 UI 收敛；删除 loading 居中；骨架屏 shimmer | style |
| `d4f2e82` | feat: 三项遗留功能补齐 | 底部操作栏/下拉刷新/团队统计降级 | feat |
| `448c702` | fix: 底部操作栏从线索详情移至日程详情 | 回撤错误加到 lead_detail 的按钮 | fix |
| `871f864` | fix: 详情⋮菜单去掉「编辑」 | 编辑改由底部操作栏提供 | fix |
| `3ba2f01` | refactor(lead-detail): 聚合为 LeadDetailBundle | 四块合一请求+缓存+预加载+守卫 | refactor |
| `7f8d8b4` | feat(dial): 拨号完整实现 + 快捷备注 | url_launcher / onResume 弹面板 / 快捷备注 | feat |
| `2e2503f` | docs(ui): 线索详情页 UI 调整 + 交接文档 | **含 22 行 Dart UI 微调**（板块序/空态高度/图标） | docs+ui |
| `a9e9a0c` | docs: tenant/leads API 文档更新 | 纯文档 | docs |
| `a1fef91` | docs(milestones): 维护节点至 v0.11 | 纯文档 | docs |
| `3bc28d7` | docs: schedule API 文档与里程碑 | 纯文档 | docs |
| `38e3d62` | docs: 日程列表进度/里程碑/踩坑 | 纯文档 | docs |
| `120bcce` | docs: 日程详情/表单进度/里程碑/踩坑 | 纯文档 | docs |
| `f96e5a8` | docs: UI 风格指南/里程碑 v0.15/踩坑 §11.5-11.6 | 纯文档 | docs |
| `024f8f4` | docs: 补充日程 v0.15d 遗留 + 里程碑 | 纯文档 | docs |

> 文档类共 7 个：`a9e9a0c` `a1fef91` `3bc28d7` `38e3d62` `120bcce` `f96e5a8` `024f8f4`——**均为纯文档，无业务代码可审**，仅核对与代码实际一致；其中 `2e2503f` 夹带 22 行 UI 微调，单列说明。

### 客观门禁（实测，不靠声明）
| 手段 | 结果 |
|------|------|
| `flutter analyze`（当前 HEAD `024f8f4`） | **No issues found!（exit 0，0 issue）** ✅ 四轮守住 |
| `android.permission.INTERNET` 是否在 main 清单 | ✅ **已修复**（`0ddf4cd`，`AndroidManifest.xml:3`）—— 见下文「阻塞级修复」 |
| 巨型文件（>560 行） | ⚠️ **3 个超限**：`schedule_detail_page` **1024**、`schedule_form_sheet` **776**、`schedule_list_page` **570** |
| 死代码 | ✅ 旧 `schedule_dialog.dart` 已删除，新 `schedule_form_sheet` 在 3 处复用，无残留 |
| debugPrint / TODO | ✅ 全库清零（仅 `app.dart` 全局兜底 `print` 合理） |
| 文件头 `///` | ✅ 本轮新建文件均在顶部 |
| commit message 准确性 | 🟡 仍见夸大（`0ddf4cd`「修复 release 版无法联网」实为 1 行权限 + 5 项杂务的厨房水槽提交） |

## 二、逐提交 / 逐域评价

### 🔴 `0ddf4cd` — INTERNET 权限修复（release 联网根因）
- **根因**：`android.permission.INTERNET` 此前仅声明在 `src/debug/` 与 `src/profile/` 清单中，main 清单缺失。Release 构建只合并 main 清单 → 所有 release 包**无联网权限**，表现为「网络连接失败」。这正是你此前在小米手机上「应用联网」菜单消失、登录必败的根因。
- **修复**：已在 `android/app/src/main/AndroidManifest.xml:3` 显式声明 `INTERNET`（实测确认落在 HEAD）。
- **连带改动**：同提交还包含 Alice 懒加载单例（`alice_manager`/`api_client`/`app.dart` 浮标拖拽）、踩坑文档新增 §9 网络与权限坑点，并**修正了 §8.7 一条被推翻的错误结论**（诚实，值得肯定）。
- **问题（提交卫生）**：这是典型的**厨房水槽提交**——一条关键权限修复（1 行）夹了 5 项不相关改动（共 101 行 / 6 文件）。权限修复是 release 阻塞级，应**独占一个提交**以便精准 cherry-pick / 回滚 / bisect。一旦某天要单独回带这个修复，会被迫带上 Alice 改动。
- **结论**：🔴 修复**正确且必要（已验证）**，但**提交拆分不合格**——建议后续将阻塞级修复单独成提交。功能评级 ✅，卫生评级 🟡。

### ✅ `d29ea98` + `f78125c` — 日程列表页（v0.12 + 真机修复合集）
- **亮点（实测源码确认）**：
  - `schedule_list_provider` 引入 `_TabCache` + `_generation` 守卫：切 Tab / 切范围命中缓存不重加载，异步竞态用 generation 防跳变 ✅
  - `options_cache_service` 改 `await` 共享 Future，归属首查不再落空被缓存 ✅
  - 分组算法重写为语义桶（今天/明天/本周/本月/更早），消除同周多天重复头；`_dateKey` 补零避免 `DateTime.parse` 抛 `FormatException`（刷新变灰真修复）✅
  - 骨架屏 `ScheduleSkeleton` 抽出公共、吸顶头分割线 + 点击滚动、下拉刷新显 `isRefreshing` ✅
  - `schedule_card` 移除线索姓名+手机号行（详情页已展示，避免重复）✅
- **问题**：`schedule_list_page.dart` 当前 **570 行**，超出 560 红线 **10 行**。build 小、dispose 正确、const 到位，属"擦线"——但红线就是红线。
- **结论**：✅ 通过（功能强），🟡 行数擦线（570），需再抽 10+ 行（如 `_buildSectionHeader`/分组构造器外提）。

### ✅ `925c159` + `b764c34` + `d4f2e82` + `448c702` + `871f864` — 日程详情页 + 表单 + 遗留补齐
- **详情页亮点（实测）**：
  - 缓存优先加载（`ScheduleDetailCache`）+ 后台静默刷新，进详情秒开 ✅
  - `_currentLeadId`/`mounted` 双守卫防后台刷新覆盖当前页 ✅
  - 404/403/通用错误三态齐全；4 个操作（`_onComplete/_onCancel/_onReopen/_onDelete`）用 `_actionLoading` 守卫 + `finally` 复位 ✅
  - 权限门控 `_canEdit`/`_canDelete` 矩阵清晰 ✅
  - `d4f2e82` 下拉刷新（`RefreshIndicator` 套 `CustomScrollView` 调 `_load(force:true)`）、团队统计 TA/TM 优先 `/schedules/stats`、不可用时静默降级 `/stats/mine` ✅
  - `448c702`/`871f864` 把"编辑"从 ⋮ 菜单撤下、改由底部操作栏提供，并把误加到线索详情的底部按钮回撤——**交互收敛正确** ✅
- **问题 1（行数）**：`schedule_detail_page.dart` **1024 行**，超红线 **464 行**，是本轮最严重的超大文件。build 虽小、dispose（AnimationController）正确，但单文件体量过大，维护/审阅成本高。
- **问题 2（同构处理可抽）**：4 个操作 handler 高度同构（loading 守卫 + 调 service + 成功刷缓存 + 失败 toast + finally 复位），可抽 `_runAction(title, future)` 把样板降约 60%。非缺陷，但属明显去重机会。
- **结论**：✅ 功能完整、用户实测通过；🟡 `schedule_detail_page` 1024 行必须拆分（最优先），4 handler 建议抽 `_runAction`。

### 🟡 `schedule_form_sheet.dart`（776 行，来自 `925c159`）— 表单日期校验回归
- **亮点**：dispose 控制器正确、脏检查放弃确认、mounted 检查、复用 `TagChipRow`、编辑态"内容未变"校验 ✅
- **⚠️ 回归（明确指名）**：`_submit()` 仅校验 `selected.millisecondsSinceEpoch == 0`（拦截公元 1970 纪元），**不拦截过去时间**。日期/时间选择器均未设 `minDate`，用户可把日程定在任意过去时刻（昨天、上周）。而上轮被删的 `schedule_dialog` 是**强制"仅未来"**的。本次表单重构把这个保护**弄丢了**。
- **影响**：业务上"计划时间在过去"语义错误，列表的"今天/明天/逾期"分组也会出现怪异归属。属功能性回归，建议**阻塞下一轮开发前修复**。
- **行数**：`schedule_form_sheet.dart` **776 行**，超红线 **216 行**。
- **结论**：🟡 通过但带 **P1 回归**（日期下限校验）——必须补回"计划时间 ≥ 当前"校验。

### ✅ `3ba2f01` — 线索详情数据层重构（LeadDetailBundle）
- **做法**：后端升级为 `GET /api/tenant/leads/:id` 一次返回 lead+followups+calls+schedules；新增 `LeadDetailBundle` 一次解析四块；详情进页 3 请求→1 请求；内存缓存（10min TTL）+ 预加载下一个，切换秒开。
- **竞态处理（教科书级）**：`_fetchBundle` 写回 UI 前加 `_currentLeadId` 守卫，彻底消灭反复翻页闪跳；getter 代理兼容旧调用 ✅
- **顺手修**：`schedule_dialog` 建日程后不刷新详情的旧 bug 一并修掉 ✅
- **结论**：✅ 通过（标杆级重构，本轮最干净的提交）。

### ✅ `7f8d8b4` — 拨号功能（url_launcher tel:）
- **亮点**：用 `url_launcher` 的 `tel:` URI 而非 MethodChannel，跨平台稳；AndroidManifest 加 `ACTION_DIAL` queries（Android 11+ 包可见性）；`LaunchMode.externalApplication` 保 lifecycle 回调；`WidgetsBindingObserver` 监听 resumed 自动弹跟进面板；夜间免打扰窗口跨天逻辑正确、有确认弹窗；号码去空白 ✅
- **🟡 问题（静默失败）**：`canLaunchUrl` 失败时仅 `return`，**无用户反馈**。部分 ROM 禁用拨号或被管控时，用户点拨号"无反应"会以为是 bug。建议失败走 toast/降级提示。
- **结论**：✅ 通过；🟡 拨号失败需给用户明确反馈（P3）。

### 🟢 文档类 7 个提交 — 无业务代码
`a9e9a0c` `a1fef91` `3bc28d7` `38e3d62` `120bcce` `f96e5a8` `024f8f4` 均为进度/里程碑/踩坑/API 文档。**核对结论**：与代码实际一致（如 §11.5 全屏遮罩 Stack+Center 不能放零高度子组件、§11.6 ShimmerBlock 补 super.key、§9 release/main 清单权限差异铁律），**属真实踩坑沉淀，质量高**。
- **特别肯定**：`0ddf4cd` 顺手**修正了 §8.7 一条被推翻的错误结论**——这种"发现旧结论错就改"的态度，比单纯追加更可贵。
- **`2e2503f` 夹带 22 行 UI 微调**：lead_detail_page(6) / call_records_section(4) / follow_up_timeline(8) / schedule_section(4)——板块顺序（日程→跟进→通话）、空态高度/图标收窄、跟进空态图标改 `TDIcons.rollback`。改动小且合理，**与文档宣称"UI 调整"吻合**，通过。

## 三、跨提交观察（需关注）

1. **⚠️ 560 行红线被冲破 3 处（本轮最大回归）**：第三轮（SPRINT-REVIEW-2）刚把"全部巨型文件降至 560 以下"作为亮点表扬，本轮日程模块一口气引入 `schedule_detail_page` 1024、`schedule_form_sheet` 776、`schedule_list_page` 570 三个超限文件。**纪律出现回摆**。建议：要么下一轮开始前把这 3 个文件拆分到 560 以下（详情页最优先，可先拆操作链/信息卡片/区块组件），要么正式修订红线阈值并把理由写进 `STYLE_GUIDE.md`——不能"规则存在但不守"。
2. **⚠️ 日期下限校验回归（P1）**：表单能定在过去时间，是功能语义错误，且丢了上轮 dialog 的"仅未来"保护。**必须修**。
3. **🟡 提交卫生持续下滑**：`0ddf4cd` 厨房水槽（权限修复夹 5 项杂务）；commit message 仍带绝对词（`d29ea98`「共享统计」实为列表内统计角标，措辞略满）。建议：阻塞级修复**独占提交**；message 严格对应实际改动，禁"全部/统一/重构"类词除非真全覆盖（此条在第三轮已提，本轮复发）。
4. **✅ 客观质量门禁稳**：四轮 `flutter analyze` 0 issue 守住；死代码清理干净；文件头 `///` 通病在新文件已根治；踩坑文档真实且与代码一致。
5. **✅ 重构范式正向**：`LeadDetailBundle` 聚合 + 缓存 + 预加载 + 守卫，是本轮最佳实践，建议作为"详情页数据层"范本推广到其他详情页（客户/公海）。

## 四、开放项清单（顺延 / 新增）

| 优先级 | 事项 | 来源 | 状态 |
|--------|------|------|------|
| **P1** | `schedule_form_sheet` 补回"计划时间 ≥ 当前"下限校验（修复过去时间回归） | 本轮 `925c159` | ⚠️ 待修（建议阻塞下一功能） |
| **P1** | `schedule_detail_page` 1024 行拆分到 560 以下（最优先超大文件） | 本轮 | ⚠️ 待拆 |
| P2 | `schedule_form_sheet` 776 行、`schedule_list_page` 570 行拆分/收线到 560 | 本轮 | ⚠️ 待拆 |
| P2 | `schedule_detail_page` 4 个同构 handler 抽 `_runAction(title, future)` 去重 | 本轮 | ⚪ 观察 |
| P3 | 阻塞级修复（`0ddf4cd` 类）独占提交，禁厨房水槽 | 本轮 `0ddf4cd` | 🟡 待改进 |
| P3 | 提交 message 准确性（禁绝对词夸大） | 系统性（第三轮已提，本轮复发） | 🟡 待改进 |
| P3 | 拨号 `canLaunchUrl` 失败给用户明确反馈 | 本轮 `7f8d8b4` | ⚪ 观察 |
| P3 | `login_page` 601 行：拆或不拆并修正 `8afc9b1` message | 第三轮顺延 | ⚪ 仍未决 |
| P3 | `SelectChip` 合并进 `TagChipRow`（去过渡双实现） | 第三轮顺延 | ⚪ 观察 |

## 五、审阅结论

**客观指标**：四轮 `flutter analyze` 0 issue 守住；INTERNET 权限缺失（release 联网根因）已修复并验证；旧 `schedule_dialog` 死代码清理干净；文件头 `///` 通病在新文件已根治；踩坑文档真实且与代码一致。

**关键亮点**：
1. **`0ddf4cd` 解了 release 联网死局**——这是你小米手机上"应用联网"菜单消失、登录必败的真凶，已根治。
2. **`3ba2f01` 线索详情重构教科书级**——四块合一请求、缓存+预加载、守卫防闪跳，可作详情页范本。
3. **日程功能完整、你已实测通过**——列表/详情/表单/操作链/权限矩阵/团队统计降级，闭环质量高。

**主要短板（本轮回摆）**：
1. **560 行红线被冲破 3 处**（1024/776/570），直接抵消了第三轮最亮点。
2. **表单日期下限校验回归**（能定过去时间），丢了上轮 dialog 的"仅未来"保护——功能性 bug。
3. **提交卫生下滑**：厨房水槽提交 + message 夸大复发。

> **综合评级：A-**
> 比第三轮的 A（趋势 A+）下调一档，主因是**文件体量纪律回摆 + 一处功能性回归**，而非功能不完整。INTERNET 根因修复与详情重构是强正向。
> **放行条件（进入下一功能前必须完成）**：① 修表单过去时间校验（P1）；② 拆分 `schedule_detail_page`（P1）。这两件不做，下一轮仍记 A-。拆分另两个超大文件 + 提交卫生整改，建议在下一轮内闭环。
> 建议：CI 接入 `flutter analyze` 卡点（warning 不让合入），并把"560 红线 + 阻塞级修复独占提交 + message 如实"写入 `STYLE_GUIDE.md` 固化为团队硬规则。

> ✅ **已固化**：2026-07-24 组长裁定，三条已写入 `docs/dev/STYLE_GUIDE.md` —— ① §2.3 单文件行数红线（560 行，硬底线、无例外）；② §8.2「阻塞级 / 发布阻断修复必须独占提交」；③ §8.2「commit message 措辞如实（禁绝对词夸大）」。文档升至 v1.1。

— Mobile App Builder（移动端小组组长），2026-07-24
