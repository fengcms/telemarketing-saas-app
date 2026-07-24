# 开发计划：日程详情/表单 四项体验优化（v0.14）

> 版本：v0.14 | 制定日期：2026-07-24 | 平台：Flutter
> 触发：v0.13 日程详情 + 新建/编辑表单实测"基本可用"后，用户提出的 4 项打磨
> 设计参考：线索详情页 `lib/pages/leads/lead_detail_page.dart`、线索详情缓存 `lib/services/lead_detail_cache.dart`

---

## 0. 背景与目标

v0.13 已完成「日程详情页（doc 11）+ 全屏表单页（doc 12）」，真机实测基本可用。本轮针对实测反馈做 4 项优化，**不新增接口、不改变业务逻辑与权限矩阵**，纯客户端 UX / 性能打磨：

1. 详情页视觉与线索详情不一致 → 统一为「白卡片 + 灰间隔」
2. 详情页每次进入都重新请求 → 加缓存，状态变更后失效重拉
3. 底部三按钮风格混搭怪异 → 统一为等宽 TDButton 一致形状
4. 新建/编辑表单从全屏页改回抽屉，并抽成公共组件供两处共用

---

## 1. ① 视觉风格统一（参考线索详情）

**现状问题**：`schedule_detail_page.dart` 的 `_card()` 把卡片底色设成了灰 `0xFFF3F3F3`，而 `Scaffold` 背景也是灰 `0xFFF3F3F3` → 灰卡浮在灰底上，区块边界糊在一起，与线索详情（白底卡片）观感不一致。

**改法**（严格对齐线索详情）：
- `Scaffold` 背景保持灰 `0xFFF3F3F3`（已是）
- `_card()` 底色改为白 `Colors.white`，圆角 `12`、左右 `16`、上 `8` 不变 → 卡片之间露出 8px 灰缝，即"白卡片 + 灰间隔"
- 标题区块（当前 `_buildTitleSection` 自写白底无卡边距）也改用统一 `_card()` 包裹，保证五个区块视觉一致
- 骨架屏占位块维持灰色（加载态本就应是灰块），不受影响

**不涉及**：状态标签配色、逾期红字、顶栏品牌色逻辑（这些用户没提、且 OK）。

---

## 2. ② 详情数据缓存（照 `LeadDetailCache` 范式）

### 2.1 新增 `lib/services/schedule_detail_cache.dart`
- `class ScheduleDetailCache`：内存 `Map<String, _CacheEntry>`，**TTL = 10 分钟**（与 `LeadDetailCache` 一致），进程被杀即失效（不落盘）
- API 镜像 `LeadDetailCache`：
  - `ScheduleDetail? get(String id)`：命中且未过期返回 `detail`，否则清理并返回 `null`
  - `void put(String id, ScheduleDetail detail)`：写入（自行记录 `fetchedAt = now`，不依赖 model 字段）
  - `void invalidate(String id)`：单条失效（写操作后调用）
  - `void invalidateAll()`：全部失效（登出/列表重置时）
- 加 `scheduleDetailCacheProvider = Provider<ScheduleDetailCache>((ref) => ScheduleDetailCache());`

### 2.2 改造详情页 `_load`（缓存优先）
- 新增可选参数 `_load({bool force = false})`
- `force == false` 时先查缓存：
  - **命中** → 立即 `setState` 渲染缓存数据（不显示骨架屏，秒开），并 `unawaited(_fetchFromServer(force: true))` 后台静默刷新（保证数据新鲜）
  - **未命中** → 显示骨架屏 + 请求
- `force == true` → 始终请求，成功写入缓存
- 抽 `_fetchFromServer()` 承载旧 `_load` 的 try/catch + `getUserName` 映射逻辑

### 2.3 写操作后失效缓存
在以下成功后调用 `_cache.invalidate(widget.scheduleId)`：
- `_onComplete` / `_onCancel` / `_onReopen`：接口成功后、`_load(force:true)` 之前
- `_onDelete`：接口成功后（它直接 pop 回列表，无需重载本页）
- 编辑保存（`_onEdit` 的 sheet 回调返回 changed）：`invalidate` + `_load(force:true)`

> 效果：反复进同一日程详情 → 第一次拉接口，之后 10 分钟内秒开、后台静默刷新；任一处状态变更后下次进入重新拉取。

---

## 3. ③ 底部三按钮风格统一

**现状问题**：`_pendingActions` 里三个按钮混搭——`取消日程` 是 `TDButton(light)`、`拨号` 是裸 `IconButton`、`标记完成` 是 `TDButton(primary, round)` + 自定义 spinner，视觉与交互不一致。

**改法**：统一为**等宽一排 `TDButton`**，形状一致（`TDButtonShape.round`），仅配色区分主次：
- `取消日程` → `TDButton` `theme: light`（中性次要）
- `拨号` → `TDButton` `theme: light` + `iconWidget: Icon(Icons.call)`（与取消同一层级，不再裸图标）
- `标记完成` → `TDButton` `theme: primary`（主操作，视觉强调）
- 三者等高、等间距（`Spacer` 分隔）；`标记完成` 的 loading spinner 逻辑保留（`iconWidget` 切 spinner）
- `_doneActions`（重新打开）维持 `primary` 单钮，形状同步为 `round`

> 不引入新组件，复用 tdesign `TDButton`。用户若想三者同色（全 light / 全 primary），确认时告知即可微调。

---

## 4. ④ 恢复抽屉 + 抽象公共组件

**目标**：把全屏 `ScheduleFormPage` 改回「底部抽屉（BottomSheet）」，并将表单逻辑抽成**一处公共组件**，线索详情「日程」与详情页「编辑」都调用它。

### 4.1 新增 `lib/pages/schedules/widgets/schedule_form_sheet.dart`
- **`ScheduleFormContent`**（`ConsumerStatefulWidget`，承载原 `ScheduleFormPage` 的全部表单逻辑）：
  - 构造参数沿用原 `create` / `edit` 两套：`leadId`/`leadName`/`leadPhone`/`prefillContent`（创建）或 `scheduleId`/`initial`（编辑）
  - **自带抽屉头部**：顶部拖动把手 + 标题（"新建日程"/"编辑日程"）+ 右上角 `×` 关闭（点击触发与返回一致的"放弃确认"）
  - 主体：滚动表单（关联线索只读 / 计划时间 / 时间 / 标题 / 内容 / 归属人）—— 逻辑完全复用现有 `_initFields` / `_pickDate` / `_pickTime` / `_submit` / `_onBack`
  - 底部操作行：取消（触发放弃确认）/ 保存或创建（loading 防重复）
  - 提交成功 → `Navigator.of(context).pop(true)`；放弃/关闭 → 确认后 `pop(false)`
  - 移除原 `Scaffold` 与独立 `_buildTopBar`（由抽屉头部取代）
- **`showScheduleFormSheet(BuildContext, {create 参数} | {edit 参数})`** 静态方法：
  - `await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => Container(constraints: BoxConstraints(maxHeight: sh*0.92), child: ScheduleFormContent(...)))`
  - 返回 `bool?`（true=有变更，false/null=未变更/放弃）

### 4.2 两处入口改接抽屉
- **`lib/pages/leads/widgets/lead_action_bar.dart`** 「日程」按钮：
  - 从 `Navigator.push(ScheduleFormPage.create(...))` 改为
    `final changed = await showScheduleFormSheet(context, leadId:, leadName:, leadPhone:);`
  - `changed == true` 时：`ref.read(scheduleListProvider.notifier).refresh()` + `ref.read(leadDetailProvider.notifier).refreshBundle()`（刷新线索下的日程区）
- **`lib/pages/schedules/schedule_detail_page.dart`** `_onEdit`：
  - 从 `Navigator.push(ScheduleFormPage.edit(...))` 改为
    `final changed = await showScheduleFormSheet(context, scheduleId:, initial:);`
  - `changed == true` 时：`_cache.invalidate(id)` + `_load(force:true)`

### 4.3 删除
- **`lib/pages/schedules/schedule_form_page.dart`**（被抽屉组件取代）
- 同步更新导入：
  - `schedule_detail_page.dart`：`import 'schedule_form_page.dart'` → `import 'widgets/schedule_form_sheet.dart'`
  - `lead_action_bar.dart`：`...pages/schedules/schedule_form_page.dart` → `...pages/schedules/widgets/schedule_form_sheet.dart`

---

## 5. 复用资产（不重复造轮子）

| 资产 | 位置 | 用途 |
|------|------|------|
| `LeadDetailCache` API 范式 | `services/lead_detail_cache.dart` | `ScheduleDetailCache` 严格照抄（get/put/invalidate/invalidateAll + TTL） |
| `_load` / `getUserName` 映射 | 现有 `schedule_detail_page.dart` | 抽 `_fetchFromServer`，缓存优先逻辑 |
| 表单逻辑 | 现有 `schedule_form_page.dart` | 整段迁进 `ScheduleFormContent`，仅去 Scaffold/独立顶栏 |
| `TDButton` / `TDPicker.showDatePicker`（Map 回调+手动 pop） | tdesign 0.2.7 / 现有表单 | 按钮统一 + 选择器复用（不重踩坑） |
| `handleDial` | `pages/leads/widgets/dial_helper.dart` | 详情页拨号不变 |
| `scheduleListProvider` / `leadDetailProvider.refreshBundle` | 现有 provider | 创建/编辑后刷新列表与线索日程区 |

---

## 6. 待开发/改动文件清单

### 新建
- `lib/services/schedule_detail_cache.dart`（缓存，照 `LeadDetailCache`）
- `lib/pages/schedules/widgets/schedule_form_sheet.dart`（`ScheduleFormContent` + `showScheduleFormSheet`）

### 改写
- `lib/pages/schedules/schedule_detail_page.dart`
  - `_card()` 底色 → 白；标题区块改用 `_card()`
  - `_load` 改缓存优先（抽 `_fetchFromServer`）
  - 写操作成功后 `_cache.invalidate(id)`
  - `_onEdit` 改调 `showScheduleFormSheet`；底部三按钮统一
- `lib/pages/leads/widgets/lead_action_bar.dart`
  - 「日程」改调 `showScheduleFormSheet`；成功后刷新列表 + 线索日程区

### 删除
- `lib/pages/schedules/schedule_form_page.dart`

---

## 7. 验证清单（真机）

- [ ] 详情页视觉：白卡片 + 灰间隔，与线索详情一致；骨架屏仍正常
- [ ] 缓存：首次进拉接口；10 分钟内再进秒开（无骨架屏、无接口请求）；完成/取消/重开/编辑保存后再次进入重新拉取
- [ ] 底部三按钮：等宽一致形状；取消=浅、拨号=浅+图标、完成=主色；loading spinner 正常
- [ ] 线索详情「日程」→ 弹出底部抽屉，创建成功关闭、列表与线索日程区刷新
- [ ] 详情页「编辑」→ 弹出同一抽屉，回填数据，保存后详情更新、缓存失效
- [ ] 抽屉内：未保存返回/× 弹放弃确认；键盘弹起不挡底部按钮
- [ ] `flutter analyze` 零错误；无遗留 import / debug print
```
