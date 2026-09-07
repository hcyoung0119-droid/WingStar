import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wingstar/theme/app_theme.dart';

class MeditationDurationDial extends StatelessWidget {
  const MeditationDurationDial({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.minimum = 1,
    this.maximum = 120,
    this.enabled = true,
  });
  final int minutes, minimum, maximum;
  final bool enabled;
  final ValueChanged<int> onChanged;
  static const diameter = 248.0;

  void _drag(Offset point, double size) {
    final offset = point - Offset(size / 2, size / 2);
    if (offset.distance < size * .25) return;
    final angle =
        (math.atan2(offset.dy, offset.dx) + math.pi / 2 + math.pi * 2) %
        (math.pi * 2);
    final value = (angle / (math.pi * 2) * maximum).round().clamp(
      minimum,
      maximum,
    );
    if (value != minutes) onChanged(value);
  }

  Future<void> _showWheel(BuildContext context) async {
    var draft = minutes;
    final controller = FixedExtentScrollController(
      initialItem: minutes - minimum,
    );
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '내가 정하는 명상 시간',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onChanged(draft);
                      Navigator.pop(context);
                    },
                    child: const Text('설정'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 210,
              child: CupertinoPicker(
                key: const Key('duration-wheel'),
                scrollController: controller,
                itemExtent: 46,
                onSelectedItemChanged: (index) => draft = minimum + index,
                children: [
                  for (var minute = minimum; minute <= maximum; minute++)
                    Center(
                      child: Text(
                        '$minute분',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(diameter, constraints.maxWidth);
          return Semantics(
            label: '명상 시간',
            value: '$minutes분',
            hint: '원을 돌리거나 시간을 눌러 설정',
            increasedValue: minutes < maximum ? '${minutes + 1}분' : null,
            decreasedValue: minutes > minimum ? '${minutes - 1}분' : null,
            onIncrease: enabled && minutes < maximum
                ? () => onChanged(minutes + 1)
                : null,
            onDecrease: enabled && minutes > minimum
                ? () => onChanged(minutes - 1)
                : null,
            child: GestureDetector(
              key: const Key('duration-dial'),
              behavior: HitTestBehavior.opaque,
              onPanDown: enabled
                  ? (details) => _drag(details.localPosition, size)
                  : null,
              onPanUpdate: enabled
                  ? (details) => _drag(details.localPosition, size)
                  : null,
              child: CustomPaint(
                painter: _DialPainter(
                  minutes / maximum,
                  Theme.of(context).brightness == Brightness.dark,
                ),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.spa_outlined,
                          color: Color(0xFF347B9A),
                          size: 25,
                        ),
                        TextButton(
                          key: const Key('duration-value'),
                          onPressed: enabled ? () => _showWheel(context) : null,
                          child: Text(
                            '$minutes분',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF347B9A),
                            ),
                          ),
                        ),
                        const Text(
                          'MY OWN PACE',
                          style: TextStyle(
                            fontSize: 10,
                            color: WSColors.muted,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: '1분 줄이기',
            onPressed: enabled && minutes > minimum
                ? () => onChanged(minutes - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Flexible(
            child: Text(
              '원을 돌려 설정 · $minimum–$maximum분',
              style: const TextStyle(fontSize: 12, color: WSColors.muted),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: '1분 늘리기',
            onPressed: enabled && minutes < maximum
                ? () => onChanged(minutes + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ],
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.progress, this.dark);
  final double progress;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.width / 2 - 18;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius - 14,
      Paint()..color = dark ? const Color(0xFF172F3D) : const Color(0xFFF0F9FA),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = dark ? Colors.white12 : const Color(0xFFE0EAF0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [Color(0xFF4CB8C4), Color(0xFF6997DB), Color(0xFFA79BDA)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 11,
    );
    for (var i = 0; i < 24; i++) {
      final angle = i / 24 * math.pi * 2 - math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 17),
        center + direction * (radius - (i % 6 == 0 ? 26 : 21)),
        Paint()
          ..color = WSColors.muted.withValues(alpha: .5)
          ..strokeWidth = 1.5,
      );
    }
    final angle = progress * math.pi * 2 - math.pi / 2;
    final handle = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(handle, 11, Paint()..color = const Color(0xFF347B9A));
    canvas.drawCircle(handle, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.dark != dark;
}
