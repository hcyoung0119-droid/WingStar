import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wingstar/theme/app_theme.dart';

class BreathingSheet extends StatefulWidget {
  const BreathingSheet({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<BreathingSheet> createState() => _BreathingSheetState();
}

class _BreathingSheetState extends State<BreathingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  int secondsLeft = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        widget.onDone();
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() => secondsLeft--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '1분 심호흡',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const Text(
            '들이마시고… 천천히 내쉬세요',
            style: TextStyle(color: WSColors.muted),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: controller,
            builder: (_, _) {
              final scale = 0.85 + (controller.value * 0.35);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        WSColors.primary.withValues(alpha: 0.25),
                        WSColors.primary,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$secondsLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
