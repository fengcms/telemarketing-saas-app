/// 跟进时间线组件（Section C）
///
/// 设计文档 §3.4 - 跟进时间线
/// 展示跟进记录的列表，包含时间线圆点+连线布局。
/// 数据为全量获取，前端本地切片实现"加载更多"。
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/models/follow_up_record.dart';
import 'follow_up_card.dart';
import 'edit_follow_up_dialog.dart';
import 'delete_confirm_dialog.dart';

/// 跟进时间线组件（Section C）
///
/// 设计文档 §3.4 - 跟进时间线
/// 展示跟进记录的列表，包含时间线圆点+连线布局。
/// 数据为全量获取，前端本地切片实现"加载更多"。
class FollowUpTimeline extends StatefulWidget {
  /// 全部跟进记录（按 createdAt 倒序）
  final List<FollowUpRecord> allRecords;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息（加载失败时）
  final String? errorMessage;

  /// 线索 ID（用于编辑/删除接口）
  final String leadId;

  const FollowUpTimeline({
    super.key,
    required this.allRecords,
    this.isLoading = false,
    this.errorMessage,
    required this.leadId,
  });

  @override
  State<FollowUpTimeline> createState() => _FollowUpTimelineState();
}

class _FollowUpTimelineState extends State<FollowUpTimeline> {
  /// 每批渲染的条数
  static const int _batchSize = 10;

  /// 当前已渲染的条数
  int _visibleCount = _batchSize;

  @override
  void didUpdateWidget(FollowUpTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 数据变化时重置可见数量
    if (oldWidget.allRecords != widget.allRecords) {
      _visibleCount = _batchSize;
    }
  }

  bool get _hasMore => _visibleCount < widget.allRecords.length;

  List<FollowUpRecord> get _visibleRecords =>
      widget.allRecords.take(_visibleCount).toList();

  @override
  Widget build(BuildContext context) {
    // 加载态
    if (widget.isLoading && widget.allRecords.isEmpty) {
      return _buildLoadingSkeleton();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          _buildHeader(),
          const SizedBox(height: 16),
          // 加载失败：行内重试
          if (widget.errorMessage != null)
            _buildErrorState()
          // 空态
          else if (widget.allRecords.isEmpty)
            _buildEmptyState()
          // 时间线列表
          else
            _buildTimelineList(),
        ],
      ),
    );
  }

  // ── 标题 ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text(
            '跟进记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(共${widget.allRecords.length}条)',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA6A6A6),
            ),
          ),
        ],
      ),
    );
  }

  // ── 错误态 ──

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              widget.errorMessage; // 父组件处理重试
            });
          },
          child: Text(
            widget.errorMessage!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFD54941),
            ),
          ),
        ),
      ),
    );
  }

  // ── 空态 ──

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      width: double.infinity,
      child: Column(
        children: [
          Icon(
            TDIcons.edit,
            size: 64,
            color: const Color(0xFFDCDCDC),
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无跟进记录',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击「跟进」按钮添加第一条记录',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFA6A6A6),
            ),
          ),
        ],
      ),
    );
  }

  // ── 加载骨架 ──

  Widget _buildLoadingSkeleton() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBlock(width: 100, height: 20),
          const SizedBox(height: 16),
          ...List.generate(3, (_) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SizedBox(width: 16),
                      SizedBox(width: 12, height: 12),
                      SizedBox(width: 12),
                    ],
                  ),
                  _skeletonBlock(width: 200, height: 14),
                  const SizedBox(height: 4),
                  _skeletonBlock(width: double.infinity, height: 14),
                  const SizedBox(height: 4),
                  _skeletonBlock(width: 160, height: 14),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _skeletonBlock(
      {double width = double.infinity, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── 时间线列表 ──

  Widget _buildTimelineList() {
    final records = _visibleRecords;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < records.length; i++) ...[
          _buildTimelineItem(records[i], i),
        ],
        // 加载更多
        if (_hasMore)
          _buildLoadMoreButton(),
      ],
    );
  }

  Widget _buildTimelineItem(FollowUpRecord record, int index) {
    final isLast = index == _visibleRecords.length - 1 && !_hasMore;
    final isLatest = index == 0; // 第一条（最新）
    final previousCategoryId = index < _visibleRecords.length - 1
        ? _visibleRecords[index + 1].categoryId
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 圆点 + 连线
        SizedBox(
          width: 28,
          child: Column(
            children: [
              const SizedBox(height: 2),
              // 圆点
              _buildDot(record, isLatest),
              // 连线
              if (!isLast)
                Container(
                  width: 2,
                  height: 120, // 大致高度，由卡片内容撑开
                  color: const Color(0xFFEEEEEE),
                ),
            ],
          ),
        ),
        // 卡片内容
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FollowUpCard(
              record: record,
              isLatest: isLatest,
              previousCategoryId: previousCategoryId,
              onEdit: () {
                showEditFollowUpDialog(
                  context,
                  leadId: widget.leadId,
                  followUpId: record.id,
                  currentContent: record.content,
                );
              },
              onDelete: () {
                showDeleteConfirmDialog(
                  context,
                  leadId: widget.leadId,
                  followUpId: record.id,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(FollowUpRecord record, bool isLatest) {
    final isAnswered = record.answerType == 'answered';
    final size = isLatest ? 16.0 : 12.0;

    if (isAnswered || isLatest) {
      // 实心圆
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0052D9),
        ),
      );
    } else {
      // 空心圆（描边）
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFFDCDCDC),
            width: 2,
          ),
        ),
      );
    }
  }

  // ── 加载更多按钮 ──

  Widget _buildLoadMoreButton() {
    return Center(
      child: SizedBox(
        height: 48,
        child: TDButton(
          text: '加载更多跟进记录',
          type: TDButtonType.text,
          size: TDButtonSize.small,
          onTap: () {
            setState(() {
              _visibleCount =
                  (_visibleCount + _batchSize)
                      .clamp(0, widget.allRecords.length);
            });
          },
        ),
      ),
    );
  }
}
