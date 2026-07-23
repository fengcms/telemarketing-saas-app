import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../providers/lead_detail_provider.dart';
import '../../../providers/lead_list_provider.dart';

/// 跟进面板接入点：显示底部弹出面板
///
/// 设计文档 §2.2 - 跟进面板
/// 内容：跟进内容 + 接听类型(5选1) + 通话时长(已接听时) + 修改分类(可选) + 提交按钮
void showFollowUpPanel(
  BuildContext context, {
  required String leadId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FollowUpPanel(leadId: leadId),
  );
}

class _FollowUpPanel extends ConsumerStatefulWidget {
  final String leadId;

  const _FollowUpPanel({required this.leadId});

  @override
  ConsumerState<_FollowUpPanel> createState() => _FollowUpPanelState();
}

class _FollowUpPanelState extends ConsumerState<_FollowUpPanel> {
  final _contentController = TextEditingController();
  String? _selectedAnswerType;
  int _durationMinutes = 0;
  int _durationSeconds = 0;
  String? _selectedCategoryId;
  bool _isSubmitting = false;
  bool _showDuration = false;

  /// 接听类型选项
  static const _answerTypes = [
    ('answered', '已接听'),
    ('no_answer', '无人接听'),
    ('rejected', '拒接'),
    ('empty_number', '空号'),
    ('suspended', '停机'),
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题 + 拖拽手柄
              _buildHeader(),
              const SizedBox(height: 20),
              // 跟进内容
              _buildContentField(),
              const SizedBox(height: 16),
              // 接听类型
              _buildAnswerTypeSelector(),
              // 通话时长（已接听时显示）
              if (_showDuration) ...[
                const SizedBox(height: 16),
                _buildDurationInput(),
              ],
              // 修改分类（可选）
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              // 提交按钮
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 拖拽手柄
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDCDCDC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        const Text(
          '新增跟进记录',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181818),
          ),
        ),
        const Spacer(),
        // 关闭按钮
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, size: 20, color: Color(0xFFA6A6A6)),
        ),
      ],
    );
  }

  // ── 跟进内容输入 ──

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '跟进内容',
              style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
            ),
            Text(
              ' *',
              style: TextStyle(fontSize: 14, color: Color(0xFFD54941)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: TDTextarea(
            hintText: '请输入跟进内容...',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_contentController.text.length}/2000',
            style: TextStyle(
              fontSize: 12,
              color: _contentController.text.length >= 2000
                  ? const Color(0xFFD54941)
                  : const Color(0xFFA6A6A6),
            ),
          ),
        ),
      ],
    );
  }

  // ── 接听类型选择 ──

  Widget _buildAnswerTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '接听类型',
              style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
            ),
            Text(
              ' *',
              style: TextStyle(fontSize: 14, color: Color(0xFFD54941)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _answerTypes.map((type) {
            final (value, label) = type;
            final isSelected = _selectedAnswerType == value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAnswerType = value;
                  _showDuration = value == 'answered';
                });
              },
              child: Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0052D9)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0052D9)
                        : const Color(0xFFE7E7E7),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF181818),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 通话时长输入 ──

  Widget _buildDurationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '通话时长',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TDStepper(
                value: _durationMinutes,
                min: 0,
                max: 99,
                onChange: (v) =>
                    setState(() => _durationMinutes = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '分',
                style: TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TDStepper(
                value: _durationSeconds,
                min: 0,
                max: 59,
                step: 5,
                onChange: (v) =>
                    setState(() => _durationSeconds = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '秒',
                style: TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 修改分类（可选） ──

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '修改分类（可选）',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // 使用 showDialog 展示分类选择
            // TODO: 接入 OptionsCacheService 获取分类列表
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  _selectedCategoryId ?? '请选择分类',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedCategoryId != null
                        ? const Color(0xFF181818)
                        : const Color(0xFFC5C5C5),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFA6A6A6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 提交按钮 ──

  Widget _buildSubmitButton() {
    final isValid = _contentController.text.trim().isNotEmpty &&
        _selectedAnswerType != null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TDButton(
        text: '提交跟进',
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        disabled: !isValid || _isSubmitting,
        onTap: isValid ? _submitFollowUp : null,
      ),
    );
  }

  Future<void> _submitFollowUp() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(leadServiceProvider);
      final duration = _showDuration
          ? _durationMinutes * 60 + _durationSeconds
          : null;

      await service.createFollowUp(
        leadId: widget.leadId,
        content: _contentController.text.trim(),
        answerType: _selectedAnswerType!,
        duration: duration != null && duration > 0 ? duration : null,
        categoryId: _selectedCategoryId,
      );

      if (!mounted) return;

      // 关闭面板
      Navigator.of(context).pop();

      // 刷新跟进时间线
      ref.read(leadDetailProvider.notifier).refreshFollowUps();

      // 显示成功提示
      TDToast.showText('跟进记录已添加', context: context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText('提交失败，请重试', context: context);
    }
  }
}
