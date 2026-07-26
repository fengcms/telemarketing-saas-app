# 热修复：公海骨架溢出 + 日程搜索栏统一

> 日期：2026-07-26 | 范围：纯 UI 修复，业务逻辑零改动 | 分析见对话

## 一、公海线索搜索骨架屏越界（BUG 修复）

### 现象
公海线索搜索时，骨架屏每张卡片**底部**出现黄黑相间的英文横幅：`A RenderFlex overflowed by 18.0 pixels`。

### 根因
`leads_list_page._buildPublicSkeleton` 卡片容器固定 `height: 160`，内部 `Column` 含 5 个灰块 + 36px 按钮块，内容高 = 16+12+14+12+14+12+14+16+36 = **146px**；减去 `padding: 16*2 = 32` 后仅 **128px** 可用 → **垂直溢出 18px**。
调试模式（热重启）下 Flutter 会把溢出绘成黄黑横幅（即用户看到的"越界英文提示"）。

> 副作用：我们刚把真实 `PublicLeadCard` 压到约 95px，骨架仍 160px，加载完成时还会"卡片突然变矮"闪跳。

### 修复
- 去掉固定 `height`，改为 `Row`（信息列 `Expanded` + 右上角领取按钮占位 `LeadSkBlock(84×32)`），**由内容自然撑高**，消除溢出。
- 结构镜像真实 `PublicLeadCard`（姓名行 + 联系行 + 分类行 + 右上领取按钮），骨架高度≈真实卡，消除加载闪跳。
- 卡片 `margin` 12 → 10，对齐真实卡。

## 二、日程搜索页改用公共 AppSearchBar

### 确认结论
`schedule_search_page` 确实**未**用公共 `AppSearchBar`——手写 `_buildSearchBar()`（L187-257），缺两处公共组件行为：
- 聚焦时整块灰底显示品牌色圆角边框（`primaryLight` 1.5px）
- 点击图标/留白区自动聚焦输入框

而线索列表页、通话记录页均已用 `AppSearchBar`，表现不一致。

### 修复
- 删除手写 `_buildSearchBar`，改为 `AppSearchBar(controller: _searchCtrl, onSearch: _doSearch, hintText: '搜索手机号', keyboardType: TextInputType.phone)`。
- 新增 `import 'package:telemarketing_app/widgets/app_search_bar.dart';`
- 搜索/清空交互等价（`onSearch('')` 触发重载、`onSubmitted` 触发搜索），行为不变。

## 三、校验
- `flutter analyze` 两文件 `No issues`；全仓仍仅 `token_storage.dart` 11 个 `!` warning（既有，与本次无关）。
- 业务逻辑（公海搜索/分页/领取、日程搜索/分页/详情跳转）一行未动。

## 四、真机验证清单
1. 公海搜索：骨架屏底部**不再**有黄黑越界横幅；加载完成卡片高度无突变。
2. 公海搜索结果卡片与骨架屏高度一致、外观正常。
3. 日程搜索页：点搜索栏任意位置能聚焦、聚焦时有品牌色边框；搜索/清空/回车行为正常。
4. 线索列表、通话记录的搜索栏表现与日程搜索页一致（聚焦边框 + 点按聚焦）。
