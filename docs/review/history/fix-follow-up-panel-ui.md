# 跟进面板 UI 调整 + 系统通话记录查询

> 审查人：Mobile App Builder
> 日期：2026-07-23
> 基于：82e6ec9 (feat: 线索详情页完整开发)

## 改动清单

### 跟进面板 `follow_up_panel.dart`
- 跟进按钮图标：`TDIcons.edit` → `TDIcons.rollback`（与编辑按钮区分）
- Textarea：圆角矩形灰边框（`textareaDecoration`），`minLines: 2`，`maxLength: 100`，`indicator: true` 内置计数
- 内填充：`inputDecoration.contentPadding(12,10,12,10)` 控制输入框内部间距
- 外间距：`padding: EdgeInsets.zero` + `margin: EdgeInsets.zero` 去除 Textarea 外部白边
- 接听类型：改用 `count = 5` 一行平铺（原 4 个）
- 通话时长：删除手动 TDStepper 输入，改为 Android 系统通话记录查询
- 分类选择：标签改为"线索分类"，去掉"不修改"chip，默认选中线索自身 `categoryId`
- 提交按钮：`_isSubmitting` 时显示白色转圈（`iconWidget` + 清空文字），与登录页一致
- 通话时长格式：`_formatDuration()` 输出"x分x秒"/"x秒"，无记录显示"0秒"

### 系统通话记录查询（Android 原生）
- `AndroidManifest.xml`：添加 `<uses-permission android:name="android.permission.READ_CALL_LOG" />`
- `MainActivity.kt`：添加 MethodChannel `com.example.telemarketing_app/call_log`
  - `getLatestCallTime(phoneNumber)` 查询最近 5 分钟匹配号码的通话
  - 返回 `[timestamp(ms), durationSec]`，无匹配返回 `[-1, 0]`
  - 权限未授权时自动弹出系统权限请求，回调后继续查询

### 其他
- `api_client.dart`：清理上次诊断调试拦截器
- `lead_action_bar.dart`：跟进图标改 rollback

## 涉及文件

| 文件 | 类型 | 说明 |
|------|------|------|
| `lib/pages/leads/widgets/follow_up_panel.dart` | modify | 跟进面板重构 |
| `lib/pages/leads/widgets/lead_action_bar.dart` | modify | 跟进图标 |
| `lib/services/api_client.dart` | modify | 清理调试代码 |
| `android/app/src/main/AndroidManifest.xml` | modify | READ_CALL_LOG 权限 |
| `android/app/src/main/kotlin/.../MainActivity.kt` | modify | MethodChannel 通话记录查询 |

## 审查总结

- **`flutter analyze`**：0 error / 3 info（仅 `unnecessary_brace_in_string_interps`，不影响）
- **真机验证**：Redmi K60 / Android 16 启动无崩溃，跟进面板 UI 正常
- **已知风险**：`READ_CALL_LOG` 为危险权限，MIUI 需用户手动允许；5 分钟查询窗口为硬编码
