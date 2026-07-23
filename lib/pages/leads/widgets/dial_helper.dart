import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 拨号辅助工具
///
/// 设计文档 §4.2 - 拨号流程
/// 检查夜间禁呼时段 → 非禁呼直接拨号 → 禁呼弹出确认弹窗
///
/// [phone] 电话号码
/// [context] BuildContext
/// [noCallWindow] 禁呼时段配置，默认 {enabled: true, start: "21:00", end: "09:00"}
Future<void> handleDial({
  required String phone,
  required BuildContext context,
  Map<String, dynamic>? noCallWindow,
}) async {
  // 检查夜间禁呼
  final noCallEnabled = noCallWindow?['enabled'] as bool? ?? true;
  if (noCallEnabled) {
    final start = noCallWindow?['start'] as String? ?? '21:00';
    final end = noCallWindow?['end'] as String? ?? '09:00';

    if (_isInNoCallWindow(start, end)) {
      final shouldDial = await _showNightCallDialog(context, start, end);
      if (!shouldDial) return;
    }
  }

  // 调用系统拨号盘
  await _launchDialer(phone);
}

/// 检查当前时间是否在禁呼时段内
bool _isInNoCallWindow(String start, String end) {
  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;

  final startParts = start.split(':');
  final endParts = end.split(':');
  final startMinutes =
      int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
  final endMinutes =
      int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

  if (startMinutes <= endMinutes) {
    // 同一天内，如 00:00-09:00
    return currentMinutes >= startMinutes &&
        currentMinutes < endMinutes;
  } else {
    // 跨天，如 21:00-09:00
    return currentMinutes >= startMinutes ||
        currentMinutes < endMinutes;
  }
}

/// 夜间禁呼确认弹窗
Future<bool> _showNightCallDialog(
  BuildContext context,
  String start,
  String end,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE37318), size: 20),
          SizedBox(width: 8),
          Text(
            '非工作时段提醒',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      content: Text('当前为非工作时段（$start - $end），是否仍要拨号？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            '取消',
            style: TextStyle(color: Color(0xFF181818)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            '继续拨号',
            style: TextStyle(color: Color(0xFF0052D9)),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 调用系统拨号盘
Future<void> _launchDialer(String phone) async {
  final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    debugPrint('无法启动拨号盘: $uri');
  }
}
