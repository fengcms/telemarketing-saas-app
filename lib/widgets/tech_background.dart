/// 蓝色科技感动画背景
///
/// 从深蓝渐变背景 + 浮动光点 + 量子连线组成，
/// 光点缓慢漂移，临近节点之间自动连线。
library;

import 'dart:math';
import 'package:flutter/material.dart';

/// 带量子连线特效的科技背景
class TechBackground extends StatefulWidget {
  final Widget child;

  const TechBackground({super.key, required this.child});

  @override
  State<TechBackground> createState() => _TechBackgroundState();
}

class _TechBackgroundState extends State<TechBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Node> _nodes;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final rand = Random(42);
    _nodes = List.generate(30, (_) => _Node(
          x: rand.nextDouble(),
          y: rand.nextDouble(),
          vx: (rand.nextDouble() - 0.5) * 0.004,
          vy: (rand.nextDouble() - 0.5) * 0.004,
          radius: rand.nextDouble() * 2.5 + 1.0,
        ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        // 更新节点位置
        for (final n in _nodes) {
          n.x += n.vx;
          n.y += n.vy;
          if (n.x < -0.05 || n.x > 1.05) n.vx = -n.vx;
          if (n.y < -0.05 || n.y > 1.05) n.vy = -n.vy;
          n.x = n.x.clamp(-0.05, 1.05);
          n.y = n.y.clamp(-0.05, 1.05);
        }
        return Stack(
          children: [
            // 渐变背景
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF060E1E),
                    Color(0xFF0D1F3C),
                    Color(0xFF132D5E),
                  ],
                ),
              ),
            ),
            // 量子连线画布
            RepaintBoundary(
              child: CustomPaint(
                painter: _QuantumPainter(_nodes),
                size: Size.infinite,
              ),
            ),
            // 内容层
            widget.child,
          ],
        );
      },
    );
  }
}

class _Node {
  double x, y, vx, vy, radius;
  _Node({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class _QuantumPainter extends CustomPainter {
  final List<_Node> nodes;
  _QuantumPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;

    const maxDist = 0.28;

    for (int i = 0; i < nodes.length; i++) {
      final a = nodes[i];
      final ax = a.x * size.width;
      final ay = a.y * size.height;

      // 光点
      dotPaint.color = const Color(0xFF00D4FF).withValues(alpha: 0.7);
      canvas.drawCircle(Offset(ax, ay), a.radius, dotPaint);

      // 光晕
      dotPaint.color = const Color(0xFF00D4FF).withValues(alpha: 0.15);
      canvas.drawCircle(Offset(ax, ay), a.radius * 3, dotPaint);

      // 连线
      for (int j = i + 1; j < nodes.length; j++) {
        final b = nodes[j];
        final bx = b.x * size.width;
        final by = b.y * size.height;

        final dx = (a.x - b.x).abs();
        final dy = (a.y - b.y).abs();

        if (dx < maxDist && dy < maxDist) {
          final dist = sqrt(dx * dx + dy * dy);
          final opacity = (1 - dist / maxDist) * 0.25;
          final paint = Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: opacity)
            ..strokeWidth = 0.6;
          canvas.drawLine(Offset(ax, ay), Offset(bx, by), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumPainter oldDelegate) => true;
}
