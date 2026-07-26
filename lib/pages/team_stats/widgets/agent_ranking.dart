/// 团队统计 - 坐席绩效排行
///
/// 可排序（转化率 / 转化数 / 跟进数 / 接通数），
/// 前 10 + "查看全部 N 名"，Top3 金/银/铜徽标。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/team_stats.dart';
import 'package:telemarketing_app/theme/chart_colors.dart';

/// 坐席绩效排行
class AgentRanking extends StatefulWidget {
  final List<AgentPerf> agents;

  const AgentRanking({super.key, required this.agents});

  @override
  State<AgentRanking> createState() => _AgentRankingState();
}

class _AgentRankingState extends State<AgentRanking> {
  late String _sortBy;
  bool _expanded = false;

  final Map<String, String> _sortLabels = const {
    'rate': '转化率',
    'converted': '转化数',
    'followup': '跟进数',
    'answered': '接通数',
  };

  @override
  void initState() {
    super.initState();
    _sortBy = 'rate';
  }

  List<AgentPerf> _sorted() {
    final list = List<AgentPerf>.from(widget.agents);
    list.sort((a, b) {
      switch (_sortBy) {
        case 'converted':
          return b.convertedCount.compareTo(a.convertedCount);
        case 'followup':
          return b.followupCount.compareTo(a.followupCount);
        case 'answered':
          return b.answeredCount.compareTo(a.answeredCount);
        case 'rate':
        default:
          return b.conversionRate.compareTo(a.conversionRate);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = _sorted();
    final visible = (_expanded || sorted.length <= 10)
        ? sorted
        : sorted.take(10).toList();
    const rankColors = [
      Color(0xFFF5C518), // 金
      Color(0xFFB0B7C0), // 银
      Color(0xFFCD7F32), // 铜
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: _sortLabels.entries.map((e) {
              final selected = _sortBy == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                selectedColor: ChartColors.brand.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: selected ? ChartColors.brand : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (_) => setState(() => _sortBy = e.key),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        ...visible.asMap().entries.map((entry) {
          final index = entry.key;
          final a = entry.value;
          final rank = index + 1;
          final rankColor = rank <= 3 ? rankColors[rank - 1] : null;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: rankColor != null
                      ? CircleAvatar(
                          radius: 11,
                          backgroundColor: rankColor,
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '拥有 ${a.ownedLeads} · 跟进 ${a.followupCount} · 接通 ${a.answeredCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${a.convertedCount}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${a.conversionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: ChartColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        if (!_expanded && sorted.length > 10)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = true),
              child: Text('查看全部 ${sorted.length} 名'),
            ),
          ),
      ],
    );
  }
}
