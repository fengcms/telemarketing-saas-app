/// 格式化时长工具
library;

/// 将秒格式化为"x分x秒"或"x秒"
String formatDuration(int seconds) {
  if (seconds <= 0) return '0秒';
  if (seconds < 60) return '$seconds秒';
  final min = seconds ~/ 60;
  final sec = seconds % 60;
  return '$min分$sec秒';
}
