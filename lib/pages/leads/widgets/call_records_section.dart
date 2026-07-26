/// 通话记录摘要组件（Section D）
///
/// 设计文档 §3.5 - 通话记录摘要
/// 展示最近 3 条通话记录，TM/TA 可见"补正"按钮。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/widgets/app_card_section.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'correct_call_dialog.dart';

/// 通话记录摘要组件（Section D）
class CallRecordsSection extends ConsumerWidget {
  final List<CallRecord> records;
  final int total;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onViewAll;

  const CallRecordsSection({
    super.key,
    required this.records,
    required this.total,
    this.isLoading = false,
    this.errorMessage,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isManager = _isManager(authState.user?.role);

    return AppCardSection(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          const Divider(height: 1, color: BrandColors.border),
          const SizedBox(height: 8),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '最近通话',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: BrandColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: const Text('查看全部'),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          errorMessage ?? '加载失败',
          style: const TextStyle(fontSize: 13, color: BrandColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: const Column(
        children: [
          Icon(Icons.call, size: 40, color: BrandColors.textDisabled),
          SizedBox(height: 8),
          Text(
            '暂无通话记录',
            style: TextStyle(fontSize: 14, color: BrandColors.textPrimary),
          ),
        ],
      ),
    );
  }

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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: BrandColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.call, size: 18, color: BrandColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            record.shortDateTime,
            style: const TextStyle(fontSize: 13, color: BrandColors.textPrimary),
          ),
          const SizedBox(width: 8),
          _buildAnswerTag(record.answerType),
          const SizedBox(width: 4),
          Text(
            record.durationText.isNotEmpty ? record.durationText : '-',
            style: const TextStyle(fontSize: 13, color: BrandColors.textSecondary),
          ),
          const Spacer(),
          if (isManager)
            GestureDetector(
              onTap: () {
                showCorrectCallDialog(context, callId: record.id, record: record);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '补正',
                  style: TextStyle(fontSize: 12, color: BrandColors.primary),
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
      tagColor = BrandColors.success;
    } else {
      tagBg = const Color(0x1AD54941);
      tagColor = BrandColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: tagColor)),
    );
  }

  bool _isManager(String? role) {
    return role == 'tenant_admin' || role == 'tenant_manager';
  }
}
