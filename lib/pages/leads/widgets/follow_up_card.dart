/// 跟进时间线单条记录卡片
///
/// 设计文档 §3.4.3 - 单条跟进记录卡片
/// 包含：时间、跟进人、接听类型+时长、内容、分类变更、编辑/删除按钮
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../constants/lead_constants.dart';
import '../../../models/follow_up_record.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/options_provider.dart';

/// 跟进时间线单条记录卡片
///
/// 设计文档 §3.4.3 - 单条跟进记录卡片
/// 包含：时间、跟进人、接听类型+时长、内容、分类变更、编辑/删除按钮
class FollowUpCard extends ConsumerWidget {
  final FollowUpRecord record;
  final bool isLatest; // 是否为时间线最新一条
  final String? previousCategoryId; // 上一条记录的 categoryId，用于显示分类变更
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FollowUpCard({
    super.key,
    required this.record,
    this.isLatest = false,
    this.previousCategoryId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isManager = _isManager(currentUser?.role);
    final followerNameAsync = ref.watch(userNameProvider(record.userId));
    final categoryNameAsync = record.categoryId != null
        ? ref.watch(categoryNameProvider(record.categoryId!))
        : null;
    final prevCategoryNameAsync = previousCategoryId != null
        ? ref.watch(categoryNameProvider(previousCategoryId!))
        : null;
    final canEdit = _canEdit(currentUser?.id, isManager);
    final canDelete = _canDelete(currentUser?.id, isManager);

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRow(),
          const SizedBox(height: 4),
          _buildFollowerRow(followerNameAsync, currentUser),
          if (record.hasAnswerType) ...[
            const SizedBox(height: 2),
            _buildAnswerTypeRow(),
          ],
          const SizedBox(height: 4),
          _buildContentRow(),
          if (_hasCategoryChanged) ...[
            const SizedBox(height: 4),
            _buildCategoryChangeRow(prevCategoryNameAsync, categoryNameAsync),
          ],
          if (canEdit || canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildActionButtons(canEdit, canDelete),
            ),
        ],
      ),
    );
  }

  // ── 时间行 ──

  Widget _buildTimeRow() {
    return Text(
      _formatDateTime(record.createdAt),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF181818),
      ),
    );
  }

  // ── 跟进人行 ──

  Widget _buildFollowerRow(
      AsyncValue<String> nameAsync, User? currentUser) {
    return Text(
      '跟进人: ${_resolvedFollowerName(nameAsync, currentUser)}',
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFFA6A6A6),
      ),
    );
  }

  // ── 跟进内容 ──

  Widget _buildContentRow() {
    return Text(
      record.content,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF181818),
        height: 1.43,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── 分类变更行 ──

  Widget _buildCategoryChangeRow(
      AsyncValue<String>? prevName, AsyncValue<String>? currName) {
    return Text(
      '分类变更: ${_resolveCategoryName(prevName)} → ${_resolveCategoryName(currName)}',
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF366EF4),
      ),
    );
  }

  // ── 编辑/删除按钮 ──

  Widget _buildActionButtons(bool canEdit, bool canDelete) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (canEdit)
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(TDIcons.edit, size: 14,
                      color: Color(0xFF0052D9)),
                  SizedBox(width: 2),
                  Text(
                    '编辑',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0052D9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (canEdit && canDelete) const SizedBox(width: 8),
        if (canDelete)
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '删除',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD54941),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── 接听类型行 ──

  Widget _buildAnswerTypeRow() {
    final label = LeadConstants.answerTypeLabel(record.answerType);
    final isAnswered = record.answerType == 'answered';
    final Color tagBg, tagColor;

    if (isAnswered) {
      tagBg = const Color(0x1A2BA471);
      tagColor = const Color(0xFF2BA471);
    } else {
      tagBg = const Color(0x1AD54941);
      tagColor = const Color(0xFFD54941);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: tagColor,
            ),
          ),
        ),
        if (record.duration != null && record.duration! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '· ${record.durationText}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA6A6A6),
            ),
          ),
        ],
      ],
    );
  }

  // ── 角色判断 ──

  /// 获取跟进人的显示名（优先从 OptionsCacheService 解析）
  String _resolvedFollowerName(
      AsyncValue<String> nameAsync, User? currentUser) {
    // 如果已解析到真实姓名
    final resolvedName =
        nameAsync.when(data: (n) => n, loading: () => null, error: (_, _) => null);
    if (resolvedName != null && resolvedName != record.userId) {
      return resolvedName;
    }
    // 如果是当前用户，显示"我"
    if (currentUser != null && record.userId == currentUser.id) {
      return currentUser.name;
    }
    // 降级：显示 ID 前 4 位
    return record.userId.length > 4
        ? record.userId.substring(0, 4)
        : record.userId;
  }

  /// 获取分类名称（从已解析的 AsyncValue 中提取）
  String _resolveCategoryName(AsyncValue<String>? nameAsync) {
    if (nameAsync == null) return '';
    return nameAsync.when(
        data: (n) => n,
        loading: () => '',
        error: (_, _) => '');
  }

  bool _isManager(String? role) {
    return role == 'tenant_admin' || role == 'tenant_manager';
  }

  /// TE 编辑条件：userId === 当前用户 && createdAt ≤ 5 分钟
  /// TM/TA 编辑条件：全部
  bool _canEdit(String? currentUserId, bool isManager) {
    if (isManager) return true;
    if (currentUserId == null) return false;
    final userIdMatches = record.userId == currentUserId;
    final isWithinTimeLimit =
        (DateTime.now().millisecondsSinceEpoch / 1000) - record.createdAt <=
            300;
    return userIdMatches && isWithinTimeLimit;
  }

  /// TE 删除条件：userId === 当前用户
  /// TM/TA 删除条件：全部
  bool _canDelete(String? currentUserId, bool isManager) {
    if (isManager) return true;
    if (currentUserId == null) return false;
    return record.userId == currentUserId;
  }

  /// 分类是否发生变化（与上一条记录相比）
  bool get _hasCategoryChanged =>
      record.categoryId != null &&
      record.categoryId!.isNotEmpty &&
      previousCategoryId != null &&
      previousCategoryId != record.categoryId;

  /// 格式化时间戳为 YYYY-MM-DD HH:mm
  String _formatDateTime(int timestamp) {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
