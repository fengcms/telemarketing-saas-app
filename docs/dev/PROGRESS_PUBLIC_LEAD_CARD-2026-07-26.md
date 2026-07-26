# 公海线索卡片优化 — 进度文档

> 日期：2026-07-26
> 关联方案：`docs/dev/PUBLIC_LEAD_CARD_PLAN-2026-07-26.md`
> 模块：线索列表 / 公海线索列表

## 一、本次完成情况

### 1. 卡片内容过高 → 重排版压低高度
- 去掉底部「分割线 + 领取按钮条」（约省 52px）
- 领取按钮上移到头行右上角，紧凑胶囊样式（高度 32）
- 电话 + 更新时间合并为单行（移除原独立「最后更新」行）
- 内边距 16 → 14，行间距收紧
- 整卡由约 180px 降至约 120px（约矮 1/3）

### 2. 越权入口关闭（卡片不可点进详情）
- `public_lead_card.dart` 移除 `GestureDetector` 包裹与 `onTap` 参数 → 卡片纯展示
- `leads_list_page.dart:526` 删除 `onTap: () => Navigator.push(LeadDetailPage(...))`
- 唯一可点元素为「领取该线索」按钮（保留 `onClaim`/`claiming`）
- 员工须先领取 → 进入「我的线索」→ 再点详情，符合权限模型

### 3. 「商铺」硬编码分类 bug（顺带修复）
- `PublicLeadCard` 由 `StatelessWidget` 升级为 `ConsumerWidget`
- `_buildCategoryRow` 改用 `OptionsCacheService.getCategoryName(lead.categoryId)` + `getProjectName(...)` 的 `FutureBuilder`
- 显示**真实分类名**，项目名兜底 `lead.project?.name`（与 `LeadCard` 解析逻辑一致）

## 二、业务逻辑影响

| 项 | 状态 |
|----|------|
| 领取入口 `onClaim` | 不变 |
| 领取 loading 态 `claiming` | 不变 |
| 领取失败回退/提示 | 不变 |
| 「我的线索」卡详情跳转 | 不变（仍可达详情） |
| 公海数据加载/分页 | 不变 |

## 三、校验结果

- `flutter analyze`（公海卡 + 列表页）：**No issues**
- 全仓：仅 `token_storage.dart` 既有 11 个 `!` warning（web token 修复遗留，与本次无关）

## 四、真机验证清单

1. 公海卡片整体变矮、无底部按钮条、领取按钮在右上角
2. 点卡片任意位置**不再进详情**（仅「领取该线索」可点）
3. 分类标签显示**真实分类名**（不再是「商铺」）
4. 领取流程（loading / 成功 / 失败提示）与改造前一致
5. 「我的线索」卡片点按仍能正常进详情

确认视觉 OK 后 `commit & push`（按项目约定开发完需真机核对）。

## 五、后续：领取按钮改圆形主题色图标（用户真机实测反馈）

### 反馈
用户在真机实测发现两点：
1. 点「领取」loading 时胶囊按钮宽度收窄 → 左侧信息列重排「弹到右侧」
2. 领取按钮与姓名/状态行顶对齐，存在视觉错位

### 方案（用户提案，已采纳）
领取按钮改为**卡片右侧上下居中的圆形主题色图标**，loading 时仅中心图标换 spinner，宽高恒定。

### 实现
- `public_lead_card.dart`：
  - 卡片 `Row` 由 `CrossAxisAlignment.start` → `center`（按钮相对整列上下居中，消错位）
  - `_buildClaimButton` 重写为固定 44×44 圆形图标按钮：`Ink`+`InkWell(customBorder: CircleBorder)`，`BrandColors.primary` 填充 + 浅阴影；图标 `Icons.person_add`（语义=把该联系人领为己有）白色 22；外层 `Tooltip('领取该线索')`
  - **关键**：loading 时仅中心换 `CircularProgressIndicator(strokeWidth: 2.5, white)`，**宽高固定不变 → 零抖动**
  - `onClaim == null` → 转 `textDisabled` 灰且不可点；`claiming` → 保持 primary（忙碌非禁用）
  - `withOpacity` → `withValues(alpha:)`，消弃用提示
- `leads_list_page.dart._buildPublicSkeleton`：占位块 84×32 胶囊 → 44×44 `BoxShape.circle`，Row 对齐同步改 center，loading 态视觉一致

### 校验
- `flutter analyze`（公海卡 + 列表页）：**No issues found**
- 纯 UI，领取业务逻辑零改动

### 真机验证清单
1. 点领取时按钮**不再抖动**、信息列不重排（核心回归项）
2. 圆形按钮相对卡片右侧**上下居中**、与姓名行不再错位
3. 领取中按钮保持主题色 + 中心 spinner；领取成功/失败流程不变
4. 骨架屏占位为 44×44 圆形，与真实按钮一致
