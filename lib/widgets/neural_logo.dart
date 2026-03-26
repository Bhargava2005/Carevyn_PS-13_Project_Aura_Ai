// lib/widgets/neural_logo.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class NeuralLogo extends StatelessWidget {
  final double size;
  final bool showContainer;
  const NeuralLogo({super.key, this.size = 60, this.showContainer = true});

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      size: Size(size * 0.72, size * 0.72),
      painter: _NeuralPainter(),
    );
    if (!showContainer) return painter;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF060D1C),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: size * 0.55, offset: Offset(0, size * 0.08)),
          BoxShadow(color: AppTheme.secondary.withOpacity(0.2), blurRadius: size * 0.8),
        ],
      ),
      child: Center(child: painter),
    );
  }
}

class _NeuralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;

    // Node positions: center + 8 orbit nodes
    final nodes = <Offset>[Offset(cx, cy)];
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      nodes.add(Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)));
    }
    // 4 inner ring nodes
    final innerR = r * 0.52;
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi - math.pi / 4;
      nodes.add(Offset(cx + innerR * math.cos(angle), cy + innerR * math.sin(angle)));
    }

    final linePaint = Paint()
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Draw spokes center → outer
    for (int i = 1; i <= 8; i++) {
      linePaint.shader = LinearGradient(
        colors: [
          const Color(0xFF00C9FF).withOpacity(0.7),
          const Color(0xFF7B5EA7).withOpacity(0.4),
        ],
      ).createShader(Rect.fromPoints(nodes[0], nodes[i]));
      canvas.drawLine(nodes[0], nodes[i], linePaint);
    }

    // Draw ring connections
    for (int i = 1; i <= 8; i++) {
      final next = i == 8 ? 1 : i + 1;
      linePaint.shader = LinearGradient(
        colors: [
          const Color(0xFF00C9FF).withOpacity(0.25),
          const Color(0xFF7B5EA7).withOpacity(0.25),
        ],
      ).createShader(Rect.fromPoints(nodes[i], nodes[next]));
      canvas.drawLine(nodes[i], nodes[next], linePaint);
    }

    // Inner ring connections
    for (int i = 9; i <= 12; i++) {
      final next = i == 12 ? 9 : i + 1;
      linePaint
        ..shader = null
        ..color = const Color(0xFF00C9FF).withOpacity(0.2);
      canvas.drawLine(nodes[i], nodes[next], linePaint);
      canvas.drawLine(nodes[0], nodes[i], linePaint);
    }

    // Draw nodes
    // Outer nodes
    for (int i = 1; i <= 8; i++) {
      final gPaint = Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF00C9FF), const Color(0xFF00C9FF).withOpacity(0)],
        ).createShader(Rect.fromCircle(center: nodes[i], radius: 5));
      canvas.drawCircle(nodes[i], 4.5, gPaint);
      canvas.drawCircle(nodes[i], 3.0,
          Paint()..color = const Color(0xFF00C9FF).withOpacity(0.9));
    }

    // Inner ring nodes
    for (int i = 9; i <= 12; i++) {
      canvas.drawCircle(nodes[i], 2.5,
          Paint()..color = const Color(0xFF7B5EA7).withOpacity(0.85));
    }

    // Center node — brightest
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF00E5FF), const Color(0xFF00C9FF).withOpacity(0)],
      ).createShader(Rect.fromCircle(center: nodes[0], radius: 12));
    canvas.drawCircle(nodes[0], 11, centerGlow);
    canvas.drawCircle(nodes[0], 7,
        Paint()..color = const Color(0xFF00C9FF).withOpacity(0.95));
    canvas.drawCircle(nodes[0], 3.5,
        Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}