import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wingstar/theme/app_theme.dart';

class StepRing extends StatelessWidget {
  const StepRing({
    super.key,
    required this.progress,
    required this.steps,
    required this.goal,
    this.onSky = false,
  });

  final double progress;
  final int steps;
  final int goal;
  final bool onSky;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return SizedBox(
      width: 236,
      height: 236,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WSColors.primarySoft.withValues(alpha: 0.65),
              boxShadow: [
                BoxShadow(
                  color: WSColors.primary.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(236, 236),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                size: 20,
                color: WSColors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat('#,###').format(steps),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: WSColors.foreground,
                  height: 1.05,
                ),
              ),
              Text(
                '목표 ${NumberFormat('#,###').format(goal)}걸음',
                style: const TextStyle(color: WSColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: WSColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: WSColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    final bg = Paint()
      ..color = WSColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [WSColors.primary, WSColors.accent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
