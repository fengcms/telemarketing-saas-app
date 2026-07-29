/// 跟进面板接入点：显示底部弹出面板
///
/// 设计文档 §2.2 - 跟进面板
/// 内容：跟进内容 + 接听类型(5选1) + 通话时长(已接听时) + 修改分类(可选) + 提交按钮
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/utils/duration_format.dart';
import 'package:telemarketing_app/widgets/app_action_bar.dart';
import 'package:telemarketing_app/widgets/app_form_section.dart';
import 'package:telemarketing_app/widgets/app_bottom_sheet.dart';
import 'package:telemarketing_app/widgets/app_textarea.dart';
import 'package:telemarketing_app/widgets/tag_chip.dart';

/// 跟进面板接入点：显示底部弹出面板
///
/// 设计文档 §2.2 - 跟进面板
/// 内容：跟进内容 + 接听类型(5选1) + 通话时长(已接听时) + 修改分类(可选) + 提交按钮
void showFollowUpPanel(
  BuildContext context, {
  required String leadId,
  bool fromDial = false,
}) {
  AppBottomSheet.show<void>(
    context: context,
    title: '新增跟进记录',
    child: _FollowUpPanel(leadId: leadId, fromDial: fromDial),
  );
}

class _FollowUpPanel extends ConsumerStatefulWidget {
  final String leadId;
  final bool fromDial;

  const _FollowUpPanel({required this.leadId, this.fromDial = false});

  @override
  ConsumerState<_FollowUpPanel> createState() => _FollowUpPanelState();
}

class _FollowUpPanelState extends ConsumerState<_FollowUpPanel> {
  final _contentController = TextEditingController();
  String? _selectedAnswerType;
  String? _selectedCategoryId;
  bool _isSubmitting = false;
  List<OptionItem> _categories = [];
  List<OptionItem> _quickNotes = [];

  /// 通话记录查询相关
  bool _showDuration = false;
  int? _callTimeMs;        // 最新匹配通话的时间戳(ms); null=未查, -1=无记录, -2=无权限
  int _callDurationSec = 0; // 最新匹配通话的时长(秒)
  bool _isCheckingCallLog = false;

  /// 接听类型选项
  static const _answerTypes = [
    ('answered', '已接听'),
    ('no_answer', '无人接听'),
    ('rejected', '拒接'),
    ('empty_number', '空号'),
    ('suspended', '停机'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAnswerType = 'answered';
    _showDuration = true;
    _loadCategories();
    _loadQuickNotes();
    // 监听线索切换：用户通过底部导航「上一个/下一个」浏览时，
    // 面板中的 widget.leadId 不会自动更新，提交时会写到旧线索。
    // 检测到当前查看的线索已改变 → 自动关闭面板。
    _watchLeadChange();
  }

  /// 监听 [leadDetailProvider]，当详情页显示的线索 ID 与面板创建时的
  /// [widget.leadId] 不一致时（即用户导航到了其他线索），自动关闭面板。
  ///
  /// 用 [previous] 非空判断避免面板首次打开时因数据未加载而误关。
  ///
  /// 使用 [listenManual] 而非 [listen] 是因为此方法在 [initState] 中调用，
  /// 而 Riverpod 2.6.1 的 [listen] 仅允许在 [build] 方法内使用。
  /// [listenManual] 返回的订阅会在 widget dispose 时自动清理。
  void _watchLeadChange() {
    ref.listenManual(leadDetailProvider, (LeadDetailState? previous, LeadDetailState next) {
      // previous?.detail != null → 确保只在上次有数据后才触发检查
      //（面板刚打开时 detail 可能为 null，跳过避免误关闭）
      if (previous?.detail != null &&
          next.detail != null &&
          next.detail!.id != widget.leadId) {
        // 当前查看的线索已切换，关闭跟进面板
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  /// 从 OptionsCacheService 加载分类列表（供「线索分类」平铺选择）
  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(optionsCacheProvider).getCategories();
      // 获取线索本身的 categoryId
      final detail = ref.read(leadDetailProvider).detail;
      final leadCategoryId = detail?.categoryId;
      if (!mounted) return;
      setState(() {
        _categories = cats;
        // 默认选中线索本身的分类；若无匹配则回退到第一项
        if (leadCategoryId != null &&
            cats.any((c) => c.id == leadCategoryId)) {
          _selectedCategoryId = leadCategoryId;
        } else if (cats.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = cats.first.id;
        }
      });
    } catch (_) {
      // 静默失败，保持空列表
    }
  }

  /// 加载快捷备注选项（仅筛选 type=followup 的数据）
  Future<void> _loadQuickNotes() async {
    try {
      final notes = await ref.read(optionsCacheProvider).getQuickNotes();
      if (!mounted) return;
      setState(() => _quickNotes = notes.where((n) => n.type == 'followup').toList());
    } catch (_) {
      // 静默失败
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ① 接听类型
        _buildAnswerTypeSelector(),
        // 通话时长（已接听时显示来自系统通话记录的最近通话时间）
        if (_showDuration) ...[
          const SizedBox(height: 16),
          _buildCallLogDisplay(),
        ],
        // ② 线索分类（可选）
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 16),
        // ③ 跟进内容
        _buildContentField(),
        const SizedBox(height: 24),
        // 提交按钮
        _buildSubmitButton(),
      ],
    );
  }


  // ── 跟进内容输入 ──

  Widget _buildContentField() {
    final isAnswered = _selectedAnswerType == 'answered';
    return AppFormSection(
      label: '跟进内容',
      required: isAnswered,
      child: AppTextarea(
        controller: _contentController,
        hintText: '请输入跟进内容...',
        maxLength: 100,
        maxLines: 4,
        quickNotes: _quickNotes.map((n) => n.name).toList(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }


  // ── 接听类型选择 ──

  Widget _buildAnswerTypeSelector() {
    return AppFormSection(
      label: '接听类型',
      required: true,
      child: TagChipRow(
        scrollable: true,
        chips: _answerTypes.map((type) {
          final (value, label) = type;
          final isSelected = _selectedAnswerType == value;
          return TagChipData(
            label: label,
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedAnswerType = value;
                _showDuration = value == 'answered';
                if (_showDuration) {
                  _checkCallLog();
                } else {
                  _callTimeMs = null;
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // ── 通话记录查询与展示 ──

  /// 通过 MethodChannel 查询系统通话记录
  Future<void> _checkCallLog() async {
    setState(() => _isCheckingCallLog = true);

    try {
      // 获取线索手机号
      final detail = ref.read(leadDetailProvider).detail;
      final phone = detail?.phone ?? '';
      if (phone.isEmpty) {
        setState(() {
          _callTimeMs = -1;
          _callDurationSec = 0;
          _isCheckingCallLog = false;
        });
        return;
      }

      const channel = MethodChannel('com.example.telemarketing_app/call_log');
      final raw = await channel.invokeMethod('getLatestCallTime', {
        'phoneNumber': phone,
      });

      if (!mounted) return;

      setState(() {
        if (raw is List) {
          // raw = [timestamp(ms), durationSec]
          final ts = raw.isNotEmpty ? raw[0] : null;
          final dur = raw.length > 1 ? raw[1] : 0;

          if (ts is int) {
            _callTimeMs = ts;
          } else if (ts is double) {
            _callTimeMs = ts.toInt();
          } else {
            _callTimeMs = -1;
          }

          if (dur is int) {
            _callDurationSec = dur;
          } else if (dur is double) {
            _callDurationSec = dur.toInt();
          } else {
            _callDurationSec = 0;
          }
        } else {
          _callTimeMs = -1;
          _callDurationSec = 0;
        }
        _isCheckingCallLog = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _callTimeMs = -2;
        _callDurationSec = 0;
        _isCheckingCallLog = false;
      });
    }
  }

  /// 展示通话记录查询结果（左右一行：标签 + 时长）
  Widget _buildCallLogDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Text(
            '通话时间',
            style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
          ),
          const Spacer(),
          _buildCallLogContent(),
        ],
      ),
    );
  }

  /// 通话记录查询结果内容
  Widget _buildCallLogContent() {
    // 查询中
    if (_isCheckingCallLog) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            '正在查询通话记录...',
            style: TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
          ),
        ],
      );
    }

    // 未查询（尚未选择已接听）
    if (_callTimeMs == null) {
      return const Text(
        '选择「已接听」后将自动查询',
        style: TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
      );
    }

    // 无权限
    if (_callTimeMs == -2) {
      return const Text(
        '需要通话记录权限才能获取通话时间',
        style: TextStyle(fontSize: 13, color: Color(0xFFD54941)),
      );
    }

    // 无匹配通话记录 → 显示 0
    // 有匹配记录 → 显示通话时长 (x分x秒 / x秒)
    final dur = formatDuration(_callDurationSec);
    return Text(
      dur,
      style: TextStyle(
        fontSize: 13,
        color: _callTimeMs == -1 ? const Color(0xFFA6A6A6) : const Color(0xFF0052D9),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 将秒格式化为"x分x秒"或"x秒"

  // ── 修改分类（可选） ──

  Widget _buildCategorySelector() {
    return AppFormSection(
      label: '线索分类',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TagChipRow(
            scrollable: true,
            chips: _categories.map((c) => TagChipData(
              label: c.name,
              selected: _selectedCategoryId == c.id,
              onTap: () => setState(() => _selectedCategoryId = c.id),
            )).toList(),
          ),
          if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '暂无可选分类',
                style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
              ),
            ),
        ],
      ),
    );
  }

  /// 分类平铺 chip（选中态高亮）

  // ── 提交按钮 ──

  Widget _buildSubmitButton() {
    final isAnswered = _selectedAnswerType == 'answered';
    final isValid = _selectedAnswerType != null &&
        (!isAnswered || _contentController.text.trim().isNotEmpty);

    return AppActionBar.submit(
      text: '提交跟进',
      loading: _isSubmitting,
      enabled: isValid,
      onPressed: isValid ? _submitFollowUp : null,
    );
  }

  Future<void> _submitFollowUp() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(leadServiceProvider);
      final content = _contentController.text.trim();

      if (widget.fromDial) {
        // 拨号返回：走复合端点，原子创建通话+跟进
        final externalCallId =
            'dial_${widget.leadId}_${DateTime.now().microsecondsSinceEpoch}';
        final startedAt = (_callTimeMs != null && _callTimeMs! >= 0)
            ? _callTimeMs! ~/ 1000
            : DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final duration = (_showDuration && _callTimeMs != null && _callTimeMs! >= 0)
            ? _callDurationSec
            : null;

        await service.createCall(
          leadId: widget.leadId,
          startedAt: startedAt,
          externalCallId: externalCallId,
          answerType: _selectedAnswerType!,
          duration: duration != null && duration > 0 ? duration : null,
          content: content.isNotEmpty ? content : null,
          categoryId: _selectedCategoryId,
        );
      } else {
        // 手动跟进：走原有接口，仅创建跟进记录
        final duration = (_showDuration && _callTimeMs != null && _callTimeMs! >= 0)
            ? _callDurationSec
            : null;

        await service.createFollowUp(
          leadId: widget.leadId,
          content: content,
          answerType: _selectedAnswerType!,
          duration: duration != null && duration > 0 ? duration : null,
          categoryId: _selectedCategoryId,
        );
      }

      if (!mounted) return;

      // 关闭面板
      Navigator.of(context).pop();

      // 刷新详情聚合数据（跟进 + 通话）
      ref.read(leadDetailProvider.notifier).refreshBundle();

      // 显示成功提示
      AppToast.show(context, '跟进记录已添加');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.show(context, '提交失败，请重试');
    }
  }
}
