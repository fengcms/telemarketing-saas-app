/// 线索列表筛选/排序面板
///
/// 从 [LeadsListPage] 拆分出的独立面板组件，用于控制 560 行红线。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/theme/user_color.dart';
import 'package:telemarketing_app/widgets/tag_chip.dart';

/// 排序面板
class LeadsSortSheet extends ConsumerWidget {
  final LeadListState state;

  const LeadsSortSheet({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '排序方式',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _sortOption(context, ref, '最近更新', '-updatedAt', state.sortBy),
          const Divider(height: 1),
          _sortOption(context, ref, '待跟进优先', 'nextFollowupAt', state.sortBy),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sortOption(
    BuildContext ctx,
    WidgetRef ref,
    String label,
    String value,
    String current,
  ) {
    final selected = value == current;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? const Color(0xFF0052D9) : const Color(0xFFA6A6A6),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF0052D9) : const Color(0xFF181818),
        ),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        if (!selected) {
          ref.read(leadListProvider.notifier).toggleSort();
        }
      },
    );
  }
}

/// 筛选面板（使用 StatefulBuilder 管理临时状态）
class LeadsFilterSheet extends ConsumerStatefulWidget {
  final LeadListState state;

  const LeadsFilterSheet({super.key, required this.state});

  @override
  ConsumerState<LeadsFilterSheet> createState() => _LeadsFilterSheetState();
}

class _LeadsFilterSheetState extends ConsumerState<LeadsFilterSheet> {
  String? _tempStatus;
  String? _tempCategoryId;
  String? _tempProjectId;
  String? _tempOwnerId;
  int? _tempDateFrom;
  int? _tempDateTo;

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.state.statusFilter;
    _tempCategoryId = widget.state.categoryId;
    _tempProjectId = widget.state.projectId;
    _tempOwnerId = widget.state.ownerId;
    _tempDateFrom = widget.state.dateFrom;
    _tempDateTo = widget.state.dateTo;
  }

  @override
  Widget build(BuildContext context) {
    // 归属人筛选仅对团队经理 / 管理员可见：
    // 员工（tenant_employee）后端 scope 固定为 'mine'，只能看自己的线索，
    // 展示「归属人」筛选无意义，且会与列表数据口径不一致。
    final role = ref.read(authProvider).user?.role;
    final canFilterByOwner =
        role == 'tenant_admin' || role == 'tenant_manager';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 16),
          if (canFilterByOwner) ...[
            _buildOwnerSection(),
            const SizedBox(height: 16),
          ],
          _buildStatusSection(),
          if (widget.state.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCategorySection(),
          ],
          if (widget.state.projects.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildProjectSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '筛选',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _tempStatus = null;
            _tempCategoryId = null;
            _tempProjectId = null;
            _tempOwnerId = null;
            _tempDateFrom = null;
            _tempDateTo = null;
          }),
          child: const Text(
            '重置',
            style: TextStyle(color: Color(0xFFA6A6A6)),
          ),
        ),
        TextButton(
          onPressed: () {
            ref.read(leadListProvider.notifier).applyFilters(
                  statusFilter: _tempStatus,
                  categoryId: _tempCategoryId,
                  projectId: _tempProjectId,
                  ownerId: _tempOwnerId,
                  dateFrom: _tempDateFrom,
                  dateTo: _tempDateTo,
                );
            Navigator.of(context).pop();
          },
          child: const Text(
            '确定',
            style: TextStyle(color: Color(0xFF0052D9)),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSection() {
    // 仅显示员工（排除管理员和经理）
    final users = widget.state.users
        .where((u) => u.role == 'tenant_employee')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('归属人',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ownerChip(null, '全部'),
              const SizedBox(width: 8),
              ...users.map((u) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ownerChip(u.id, u.name, userId: u.id),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ownerChip(String? value, String label, {String? userId}) {
    final selected = _tempOwnerId == value;
    return GestureDetector(
      onTap: () => setState(() => _tempOwnerId = value),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD9E1FF) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userId != null)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: userColor(userId),
                  shape: BoxShape.circle,
                ),
              ),
            if (userId != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? const Color(0xFF0052D9) : const Color(0xFF4E5969),
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final statuses = [
      ('pending', '待分配'),
      ('assigned', '待跟进'),
      ('following', '跟进中'),
      ('converted', '已转化'),
      ('invalid', '无效'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('状态',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TagChipRow(
          chips: statuses.map((s) {
            final selected = _tempStatus == s.$1;
            return TagChipData(
              label: s.$2,
              selected: selected,
              onTap: () =>
                  setState(() => _tempStatus = selected ? null : s.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('分类',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TagChipRow(chips: _buildOptionChips(widget.state.categories,
            _tempCategoryId, (id) {
          setState(
              () => _tempCategoryId = _tempCategoryId == id ? null : id);
        })),
      ],
    );
  }

  Widget _buildProjectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('项目',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TagChipRow(chips: _buildOptionChips(
            widget.state.projects, _tempProjectId, (id) {
          setState(
              () => _tempProjectId = _tempProjectId == id ? null : id);
        })),
      ],
    );
  }

  List<TagChipData> _buildOptionChips(
    List<OptionItem> options,
    String? selectedId,
    void Function(String id) onSelected,
  ) {
    return options
        .map((o) => TagChipData(
            label: o.name,
            selected: o.id == selectedId,
            onTap: () => onSelected(o.id)))
        .toList();
  }
}
