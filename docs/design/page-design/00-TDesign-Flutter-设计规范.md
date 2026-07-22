# TDesign Flutter 设计规范 — 电销工作台 APP

> 本文档定义 APP 全局设计令牌（Design Tokens），所有页面设计文档共享此基础规范。
> 技术栈：Flutter + [TDesign Flutter](https://github.com/Tencent/tdesign-flutter)
> 版本：v1.0（2026-07-22）
>
> **与 [00-全局API约定](./00-全局API约定.md) 的分工**：本文件管**视觉 / 组件规范**（色彩、字号、间距、圆角、阴影、组件映射、图标、动效、适配）；接口响应信封、分页、过滤/排序、枚举值、错误码等 **API 约定**一律以 [00-全局API约定](./00-全局API约定.md) 为唯一事实来源，两份文档冲突时以该文件为准。

---

## 1. 色彩体系

### 1.1 主色 Brand

> **品牌色已确定：TDesign `brand-7` #0052D9（专业蓝）**，作为 APP 主色调，用于按钮、链接、激活态等核心场景（原"待确认/暂定"状态作废）。

TDesign 默认主色为 **蓝色 #0052D9**，以下为主色色板（brand-1 到 brand-10）：

| Token | 色值 | 用途 |
|-------|------|------|
| `brand-1` | #F2F3FF | 浅背景、选中态背景 |
| `brand-2` | #D9E1FF | 悬浮背景、Tag 填充 |
| `brand-3` | #B5C7FF | 次要边框装饰 |
| `brand-4` | #8EABFF | 图标高亮 |
| `brand-5` | #618DFF | 次级主色 |
| `brand-6` | #366EF4 | 悬浮态（hover） |
| `brand-7` | #0052D9 | **默认主色**，按钮、链接、激活态 |
| `brand-8` | #003CAB | 点击态（pressed） |
| `brand-9` | #00287A | 深色强调 |
| `brand-10` | #001553 | 极深强调 |

> **代码获取**：`TDTheme.of(context).brandNormalColor` 即 brand-7。

### 1.2 功能色

| 语义 | Token | 色值 | 使用场景 |
|------|-------|------|---------|
| 成功 | `success-7` | #2BA471 | 操作成功、转化、接通 |
| 警告 | `warning-7` | #E37318 | 逾期提醒、注意 |
| 错误 | `error-7` | #D54941 | 删除、失败、拒接、异常 |
| 信息 | `brand-7` | #0052D9 | 链接、引导、普通提示 |

### 1.3 中性色

| Token | 色值 | 用途 |
|-------|------|------|
| `gray-1` | #F3F3F3 | 页面背景 |
| `gray-2` | #EEEEEE | 分割线、卡片边框 |
| `gray-3` | #E7E7E7 | 禁用态边框 |
| `gray-4` | #DCDCDC | 禁用态填充 |
| `gray-5` | #C5C5C5 | 占位符文字 |
| `gray-6` | #A6A6A6 | 辅助文字、次级信息 |
| `gray-7` | #86909C | 次级正文 |
| `gray-8` | #6B7A90 | 次级正文（深） |
| `gray-9` | #4E5969 | 正文色 |
| `gray-10` | #3C3C3C | 标题色 |
| `gray-11` | #2C2C2C | 重要标题 |
| `gray-12` | #181818 | 最深文字 |
| `gray-13` | #FFFFFF | 纯白背景 |

### 1.4 业务语义色（APP 自定义）

| 语义 | 色值 | 使用场景 |
|------|------|---------|
| 跟进中 | #0052D9 (brand-7) | 线索状态标签 |
| 待跟进 | #E37318 (warning-7) | nextFollowupAt 今日到期 |
| 已转化 | #2BA471 (success-7) | 转化成功 |
| 已逾期 | #D54941 (error-7) | 日程逾期 |
| 已接听 | #2BA471 | 通话记录、跟进时间线圆点 |
| 无人接听 | #A6A6A6 (gray-6) | 通话记录 |
| 拒接 | #D54941 (error-7) | 通话记录 |
| 公海 | #366EF4 (brand-6) | 公海线索标识 |

---

## 2. 字体排版

### 2.1 字体家族

```
fontFamily: 'PingFang SC', 'Helvetica Neue', 'Microsoft YaHei', sans-serif
```

Flutter 中通过 `ThemeData.fontFamily` 全局设置，中文系统自动回退。

### 2.2 字号层级

> **字号单位说明**：本文档字号单位 `sp` 为逻辑像素，Flutter 中随系统字体缩放（`textScaler`）等比放大，即设计值 = 逻辑像素值；组件尺寸（间距/圆角/高度）单位为 `dp`，不随字体缩放。

| Token | 字号 | 行高 | 字重 | 使用场景 |
|-------|------|------|------|---------|
| `fontDisplayLarge` | 36sp | 44sp | Bold (700) | 超大数字展示（首页统计数字） |
| `fontHeadlineLarge` | 28sp | 36sp | Bold (700) | 页面大标题 |
| `fontHeadlineMedium` | 24sp | 32sp | Bold (700) | 区块标题 |
| `fontTitleLarge` | 20sp | 28sp | SemiBold (600) | 卡片标题、弹窗标题 |
| `fontTitleMedium` | 18sp | 26sp | SemiBold (600) | 列表标题、区域标题 |
| `fontTitleSmall` | 16sp | 24sp | Medium (500) | 小标题、按钮文字 |
| `fontBodyLarge` | 15sp | 22sp | Regular (400) | 正文（大） |
| `fontBodyMedium` | 14sp | 22sp | Regular (400) | **正文（默认）** |
| `fontBodySmall` | 13sp | 20sp | Regular (400) | 辅助文字 |
| `fontBodyExtraSmall` | 12sp | 18sp | Regular (400) | 角标、时间戳、最小文字 |
| `fontCaption` | 10sp | 16sp | Regular (400) | 极小标注（Badge 数字等） |

### 2.3 排版规则

- Flutter **不自动处理**中英文间距，需引入 `flutter_pangu` 包在渲染层自动加空格，或在文案规范中约定手动加空格（本 APP 采用 `flutter_pangu` 方案）
- 数字使用等宽数字字体（`fontFeatures: [FontFeature.tabularFigures()]`）便于对齐
- 金额/统计数字使用 `fontBodyLarge` 或更大 + `fontWeight: Bold`
- 正文行高统一 1.5~1.6 倍

---

## 3. 间距系统

TDesign 基于 **4px** 基准的间距体系：

| Token | 值 | 使用场景 |
|-------|-----|---------|
| `spacer4` | 4px | 图标与文字间距、紧凑元素内间距 |
| `spacer8` | 8px | 列表项内元素间距、卡片内 padding |
| `spacer12` | 12px | 表单字段间距、卡片内 padding |
| `spacer16` | 16px | **标准间距**，卡片内 padding、列表项间距 |
| `spacer24` | 24px | 区块间距、区域分隔 |
| `spacer32` | 32px | 大区块分隔 |
| `spacer48` | 48px | 页面级分隔 |

### 页面边距

- 页面水平 padding：**16px**（标准）
- 卡片内 padding：**16px**
- 卡片间距：**12px**
- 列表项高度：**56px**（标准）、**72px**（双行）、**88px**（三行）

---

## 4. 圆角系统

| Token | 值 | 使用场景 |
|-------|-----|---------|
| `radiusSmall` | 4px | 小按钮、Tag、Chip |
| `radiusMedium` | 8px | 输入框、下拉框、小卡片 |
| `radiusLarge` | 12px | 卡片、弹窗、BottomSheet |
| `radiusExtraLarge` | 16px | 大卡片、浮层 |
| `radiusRound` | 999px | 圆形按钮、胶囊标签 |
| `radiusCircle` | 50% | 头像、圆形图标 |

---

## 5. 阴影系统

| Token | 参数 | 使用场景 |
|-------|------|---------|
| `shadowBase` | `offset(0,1), blur 4, color gray-3 @20%` | 列表项微弱浮起 |
| `shadowMedium` | `offset(0,4), blur 12, color gray-3 @25%` | **卡片默认阴影** |
| `shadowLarge` | `offset(0,8), blur 24, color gray-3 @30%` | 弹窗、BottomSheet、悬浮按钮 |
| `shadowNavBar` | `offset(0,-2), blur 8, color gray-3 @15%` | 顶部导航栏底部阴影 |

> TDesign 的阴影偏柔和、扩散范围大、透明度低，视觉上比 Material Design 更轻盈。

---

## 6. 核心组件映射

以下为 APP 页面设计中使用的 TDesign Flutter 组件对照表。页面文档中统一使用此表中的组件名。

| 功能需求 | TDesign Flutter 组件 | 说明 |
|---------|---------------------|------|
| 底部导航栏 | `TDBottomTabBar` | 4 Tab 导航，支持 Badge |
| 顶部导航栏 | `TDNavBar` | 支持标题、左右操作区 |
| 主按钮 | `TDButton(theme: TDButtonTheme.primary)` | brand-7 填充，白色文字 |
| 次要按钮 | `TDButton(theme: TDButtonTheme.secondary)` | brand-1 填充，brand-7 文字 |
| 文字按钮 | `TDButton(theme: TDButtonTheme.text)` | 无背景，brand-7 文字 |
| 危险按钮 | `TDButton(theme: TDButtonTheme.danger)` | error-7 填充 |
| 圆角按钮 | `TDButton(shape: TDButtonShape.round)` | 胶囊形状 |
| 输入框 | `TDInput` | 支持前缀图标、清除、密码切换 |
| 文本域 | `TDTextarea` | 多行输入，支持字数统计 |
| 搜索框 | `TDSearchBar` | 支持防抖、回调 |
| 标签选择 | `TDTag` / `TDCheckTag` | 状态标签、筛选标签 |
| 筛选标签组 | `TDTagGroup` | 横向排列的筛选 Chip |
| 下拉选择 | `TDPicker` / `TDMultiPicker` | 日期/时间/通用选择器 |
| 日期选择 | `TDCalendarPicker` | 日历选择器 |
| 时间选择 | `TDDatePicker(mode: time)` | 时间滚轮 |
| 底部弹出面板 | `TDPopup` | BottomSheet 弹出层 |
| 对话框 | `TDDialog` | 确认弹窗、信息弹窗 |
| 消息提示 | `TDToast` | 轻提示（成功/失败/加载中） |
| 通知栏 | `TDNoticeBar` | 顶部通知条 |
| 空状态 | `TDEmpty` | 空数据占位 |
| 骨架屏 | `TDSkeleton` | 加载占位 |
| 下拉刷新 | `TDRefreshHeader` | 下拉刷新 |
| 无限滚动 | `TDLoadMore` | 上拉加载更多 |
| 列表项 | `TDCell` | 标准列表项 |
| 分组列表 | `TDCellGroup` | 分组列表容器 |
| 侧边弹出 | `TDSideBar` | 侧边筛选面板 |
| 进度条 | `TDProgress` | 线性/环形进度 |
| 徽标 | `TDBadge` | 数字/红点徽标 |
| 步进器 | `TDStepper` | 数量增减 |
| 滑动操作 | `TDSwipeCell` | 列表项左滑操作 |
| 分段选择 | `TDTabBar` | 顶部分页切换 |
| 折叠面板 | `TDCollapse` | 可折叠区域 |
| 分隔线 | `TDDivider` | 分割线 |
| 宫格 | `TDGrid` | 2x2 / 3列宫格布局 |
| 头像 | `TDAvatar` | 圆形头像 |
| 图片 | `TDImage` | 图片展示 |
| 图标 | `TDIcons` | TDesign 内置图标库 |
| 倒计时 | 自定义 + `Timer` | 日程到期倒计时 |
| 轮播 | `TDSwiper` | 轮播图（首页备用） |

---

## 7. 图标规范

TDesign 内置图标库 `TDIcons`，APP 中常用图标映射：

| 语义 | 图标名 | 使用位置 |
|------|--------|---------|
| 首页 | `TDIcons.home` | 底部 Tab 1 |
| 线索 | `TDIcons.task` | 底部 Tab 2 |
| 日程 | `TDIcons.calendar` | 底部 Tab 3 |
| 我的 | `TDIcons.user` | 底部 Tab 4 |
| 拨号 | `TDIcons.call` | 线索详情拨号按钮 |
| 搜索 | `TDIcons.search` | 搜索框图标 |
| 筛选 | `TDIcons.filter` | 筛选按钮 |
| 排序 | `TDIcons.sort` | 排序按钮 |
| 编辑 | `TDIcons.edit` | 编辑按钮 |
| 删除 | `TDIcons.delete` | 删除按钮 |
| 添加 | `TDIcons.add` | 新建按钮 |
| 关闭 | `TDIcons.close` | 关闭/取消 |
| 返回 | `TDIcons.chevron_left` | 返回箭头 |
| 更多 | `TDIcons.ellipsis` | 更多操作 |
| 成功 | `TDIcons.check_circle` | 成功状态 |
| 警告 | `TDIcons.error_circle` | 警告状态 |
| 信息 | `TDIcons.info_circle` | 信息提示 |
| 电话已接 | `TDIcons.call` (success色) | 跟进时间线 |
| 无人接听 | `TDIcons.call_off` (gray色) | 跟进时间线 |
| 拒接 | `TDIcons.close_circle` (error色) | 跟进时间线 |
| 日程逾期 | `TDIcons.time` (error色) | 日程卡片 |
| 公海 | `TDIcons.pool` (brand色) | 公海线索标识 |

> 图标尺寸规范：底部 Tab 24px、AppBar 操作 24px、列表项前缀 20px、按钮内图标 20px、状态标签内 12px。

---

## 8. 动效规范

### 8.1 转场动画

| 场景 | 动画 | 时长 | 曲线 |
|------|------|------|------|
| 页面 push | 从右侧滑入 | 300ms | `Curves.easeInOut` |
| 页面 pop | 向右侧滑出 | 250ms | `Curves.easeInOut` |
| BottomSheet 弹出 | 从底部滑入 | 300ms | `Curves.easeOut` |
| BottomSheet 关闭 | 向底部滑出 | 250ms | `Curves.easeIn` |
| Dialog 弹出 | 缩放 + 淡入 | 200ms | `Curves.easeOut` |
| Dialog 关闭 | 缩放 + 淡出 | 150ms | `Curves.easeIn` |

### 8.2 交互动效

| 场景 | 动效描述 |
|------|---------|
| 按钮点击 | 轻微缩放（0.96）+ 水波纹扩散（TDesign 内置） |
| 卡片点击 | 阴影加深 + 轻微下沉（offset 增大） |
| Tab 切换 | 指示器滑动过渡（200ms easeInOut） |
| 列表项操作完成 | 轻微弹性缩放 + Toast 反馈 |
| 下拉刷新 | TDesign 自定义刷新头（品牌色旋转动画） |
| 数字变化 | 滚动数字动画（首页统计数字） |
| 状态切换 | 颜色渐变过渡（如日程完成：pending→completed） |

### 8.3 特殊动效

| 场景 | 动效描述 |
|------|---------|
| 跟进时间线展开 | 从顶部依次淡入（staggered animation，每项延迟 50ms） |
| 拨号按钮长按 | 震动反馈 + 按钮呼吸光晕效果 |
| 领取公海线索成功 | 卡片飞入"我的线索"动画（shared element transition） |
| 日程到期提醒条 | 从顶部滑入 + 左侧色条呼吸闪烁 |

---

## 9. 深色模式

TDesign Flutter 原生支持深色模式（通过 `TDTheme.needMultiTheme()` 启用）。

APP 跟随系统设置自动切换，不单独提供切换开关。

| 属性 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 页面背景 | #F3F3F3 (gray-1) | #181818 (gray-12) |
| 卡片背景 | #FFFFFF | #2C2C2C |
| 主文字 | #181818 (gray-12) | #F3F3F3 (gray-1) |
| 次文字 | #6B7A90 (gray-8) | #A6A6A6 (gray-6) |
| 分割线 | #EEEEEE (gray-2) | #3C3C3C |
| 主色 | #0052D9 (brand-7) | #366EF4 (brand-6，深色模式下提亮) |

---

## 10. 无障碍

- 所有可点击区域最小 **48x48px**（TDesign 组件已内置）
- 文字与背景对比度 ≥ **4.5:1**（WCAG AA 标准）
- 图标按钮必须提供 `semanticsLabel`
- 动画支持系统"减少动画"设置（`MediaQuery.of(context).disableAnimations`）

---

## 11. 适配

- **APP 全程竖屏锁定（portrait only），不适配横屏**（启动时 `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`）
- 设计基准宽度：**375px**（iPhone SE / 标准安卓手机）
- 使用 `MediaQuery` + `LayoutBuilder` 做响应式适配
- 大屏（平板）：线索列表和统计页可采用双栏布局
- 文字缩放：支持系统字体大小设置（`MediaQuery.textScaleFactor`），但统计数字不跟随缩放

---

> 本文档为全局设计基础。各页面文档（01-23）中的组件引用、色值、间距、字号均以此文档为准。
