/// 通话记录摘要组件（Section D）
///
/// 设计文档 §3.5 - 通话记录摘要
/// 展示最近 3 条通话记录，TM/TA 可见"补正"按钮。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'correct_call_dialog.dart';

/// 通话记录摘要组件（Section D）
///
/// 设计文档 §3.5 - 通话记录摘要
/// 展示最近 3 条通话记录，TM/TA 可见"补正"按钮。
class CallRecordsSection extends ConsumerWidget {
  final List<CallRecord> records;
  final int total;
  final bool isLoading;
  final String? errorMessage;

  const CallRecordsSection({
    super.key,
    required this.records,
    required this.total,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isManager = _isManager(authState.user?.role);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          _buildHeader(context),
          const SizedBox(height: 16),
          // 分割线
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          // 内容
          if (isLoading && records.isEmpty)
            _buildLoadingState()
          else if (errorMessage != null)
            _buildErrorState()
          else if (records.isEmpty)
            _buildEmptyState()
          else
            _buildRecordsList(context, isManager),
        ],
      ),
    );
  }

  // ── 标题 ──

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '最近通话',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181818),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            // Node 5: 跳转通话记录列表页
            // Navigator.push -> /lead/:id/calls
          },
          child: const Text(
            '查看全部',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF0052D9),
            ),
          ),
        ),
      ],
    );
  }

  // ── 加载态 ──

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // ── 错误态 ──

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          errorMessage ?? '加载失败',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFA6A6A6),
          ),
        ),
      ),
    );
  }

  // ── 空态 ──

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: const Column(
        children: [
          Icon(
            TDIcons.call,
            size: 40,
            color: Color(0xFFDCDCDC),
          ),
          SizedBox(height: 8),
          Text(
            '暂无通话记录',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF181818),
            ),
          ),
        ],
      ),
    );
  }

  // ── 记录列表 ──

  Widget _buildRecordsList(BuildContext context, bool isManager) {
    return Column(
      children: records.map((record) {
        return _buildRecordRow(record, isManager, context);
      }).toList(),
    );
  }

  Widget _buildRecordRow(CallRecord record, bool isManager, BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 电话图标
          Icon(
            TDIcons.call,
            size: 18,
            color: const Color(0xFFA6A6A6),
          ),
          const SizedBox(width: 8),
          // 时间
          Text(
            record.shortDateTime,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(width: 8),
          // 接听类型标签
          _buildAnswerTag(record.answerType),
          const SizedBox(width: 4),
          // 时长
          Text(
            record.durationText.isNotEmpty
                ? record.durationText
                : '-',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFA6A6A6),
            ),
          ),
          const Spacer(),
          // 补正按钮（仅 TM/TA）
          if (isManager)
            GestureDetector(
              onTap: () {
                showCorrectCallDialog(
                  context,
                  callId: record.id,
                  record: record,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '补正',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0052D9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerTag(String? answerType) {
    final label = LeadConstants.answerTypeLabel(answerType);
    final isAnswered = answerType == 'answered';
    final Color tagBg, tagColor;

    if (isAnswered) {
      tagBg = const Color(0x1A2BA471);
      tagColor = const Color(0xFF2BA471);
    } else {
      tagBg = const Color(0x1AD54941);
      tagColor = const Color(0xFFD54941);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
    );
  }

  bool _isManager(String? role) {
    return role == 'tenant_admin' || role == 'tenant_manager';
  }
}
