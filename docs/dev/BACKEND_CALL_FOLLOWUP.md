# 通话复合端点跟进记录缺失问题分析

> 作者：前端开发
> 日期：2026-07-29
> 目的：分析「拨号提交空号/停机等非接听类型后，有通话记录但无跟进记录」问题的根因，提供
> 前端修复方案说明，并邀请后端评估是否需要在服务端做补充逻辑。

---

## 一、问题现象

**操作路径：**
1. 线索详情页 → 点击「拨号」按钮
2. 系统拨号 → 用户结束通话返回 APP
3. 自动弹出跟进面板（`fromDial=true`）
4. 用户选择接听类型为「空号」或「停机」（无需输入跟进内容）
5. 点击「提交跟进」
6. 刷新详情页面后：
   - ✅ 页面底部出现一条通话记录
   - ❌ 跟进时间线为空，没有跟进记录
   - ❌ 线索状态仍为「待跟进」未变化

---

## 二、数据流追溯

### 2.1 前端提交逻辑

前端调用 `POST /api/tenant/leads/:id/calls`（复合「完成通话」端点），请求体：

```json
{
  "startedAt": 1722235200,
  "externalCallId": "dial_xxx_1722235200123456",
  "answerType": "empty_number",
  "direction": "outbound"
}
```

**不包含 `content` 字段。**

### 2.2 后端契约（前端理解）

根据 API 文档：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| answerType | string | 是 | 接听类型 |
| content | string | 否 | 跟进内容，**非空时自动建跟进** |
| ... | | | |

即：`content` 不存在或为空字符串时，端点**只创建通话记录，不创建跟进记录**。

### 2.3 前端改动（已修复）

当用户未输入跟进内容时，前端之前传 `content: null`，现在改为**根据 `answerType` 自动生成默认内容**：

| 接听类型 | 自动生成的 content |
|---------|------------------|
| `answered` | 用户输入的内容（有输入时）或 `"已接听"` |
| `no_answer` | `"无人接听"` |
| `rejected` | `"拒接"` |
| `empty_number` | `"空号"` |
| `suspended` | `"停机"` |

修复后请求体变为：

```json
{
  "startedAt": 1722235200,
  "externalCallId": "dial_xxx_1722235200123456",
  "answerType": "empty_number",
  "direction": "outbound",
  "content": "空号"
}
```

→ `content` 非空 → 后端按现有逻辑即可创建跟进记录。

**改动文件**：`lib/pages/leads/widgets/follow_up_panel.dart`

---

## 三、后端可选的增强方案（供评估）

前端修复后功能正常。但如果后端希望更语义化地处理「非接听类型」，可以考虑以下增强：

### 方案 A：根据 `answerType` 自动生成跟进内容（推荐）

当 `content` 不存在或为空时，后端根据 `answerType` 自动填充默认内容：

```javascript
// 伪代码
if (!body.content) {
  const contentMap = {
    'no_answer':    '无人接听',
    'rejected':     '拒接',
    'empty_number': '空号',
    'suspended':    '停机',
    'answered':     '已接听',   // answered 不带内容时用默认
  };
  body.content = contentMap[body.answerType] || '跟进';
}
```

**好处**：无论前端传不传 `content`，只要有一个合法的 `answerType`，就一定能生成跟进记录。防御性更强，兼容旧版客户端。

### 方案 B：保持现状，依赖前端传 content

前端已修复（自动生成），后端不做额外改动。

**风险**：如果其他客户端（如有）或后续版本改逻辑后忘记传 `content`，问题会再现。

---

## 四、总结

| 项目 | 内容 |
|------|------|
| **根因** | 前端拨号提交时，`content` 为空则传 `null`，后端按契约不创建跟进记录 |
| **前端修复** | ✅ 已完成。`content` 为空时根据 `answerType` 自动生成默认文本 |
| **后端是否需改** | 非必须。如果后端希望防御性更强，可在服务端也做 `answerType → content` 映射 |

如有疑问欢迎沟通。
