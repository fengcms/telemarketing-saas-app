/// 线索列表页搜索栏 + 筛选标签栏
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';

/// 搜索栏 + 筛选标签栏
class LeadsSearchBar extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onShowFilter;
  final VoidCallback onShowSort;

  const LeadsSearchBar({
    super.key,
    required this.searchCtrl,
    required this.onSearch,
    required this.onShowFilter,
    required this.onShowSort,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leadListProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 搜索栏 ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(TDIcons.search,
                            size: 20, color: Color(0xFFA6A6A6)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onSubmitted: onSearch,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF181818)),
                          decoration: const InputDecoration(
                            hintText: '搜索线索姓名/电话/公司',
                            hintStyle: TextStyle(
                                fontSize: 14, color: Color(0xFFC5C5C5)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => searchCtrl.clear(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(TDIcons.close_circle,
                                size: 20, color: Color(0xFFA6A6A6)),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => onSearch(searchCtrl.text),
                        child: Container(
                          height: 34,
                          margin: const EdgeInsets.only(
                              top: 3, right: 3, bottom: 3),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052D9),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          alignment: Alignment.center,
                          child: const Text('搜索',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 筛选标签栏 ──
        Container(
          width: double.infinity,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (state.statusFilter != null && state.statusFilter!.isNotEmpty)
                  _buildTag(
                    '状态',
                    LeadConstants.displayName(state.statusFilter),
                    () => ref.read(leadListProvider.notifier).clearFilter('status'),
                  ),
                if (state.categoryId != null && state.categoryId!.isNotEmpty)
                  _buildTag(
                    '分类',
                    _findOptionName(state.categories, state.categoryId),
                    () => ref.read(leadListProvider.notifier).clearFilter('category'),
                  ),
                if (state.projectId != null && state.projectId!.isNotEmpty)
                  _buildTag(
                    '项目',
                    _findOptionName(state.projects, state.projectId),
                    () => ref.read(leadListProvider.notifier).clearFilter('project'),
                  ),
                if (state.dateFrom != null || state.dateTo != null)
                  _buildTag(
                    '时间',
                    '已选',
                    () => ref.read(leadListProvider.notifier).clearFilter('date'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, String value, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                '$label: $value',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0052D9)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                TDIcons.close,
                size: 16,
                color: Color(0xFF0052D9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _findOptionName(List<OptionItem> options, String? id) {
    if (id == null) return '';
    final found = options.where((o) => o.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }
}
