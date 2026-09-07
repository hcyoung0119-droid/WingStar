import 'package:flutter/material.dart';

/// 마음서비스(mind-service) 디자인 토큰을 WingStar에 이식.
class WSColors {
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF1C2B36);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF6EC6FF);
  static const primarySoft = Color(0xFFE8F6FF);
  static const primaryDark = Color(0xFF3BA8E8);
  static const secondary = Color(0xFFF4F9FC);
  static const secondaryForeground = Color(0xFF3A4A57);
  static const muted = Color(0xFF7A8A99);
  static const mutedBg = Color(0xFFF4F7FA);
  static const accent = Color(0xFFAEE1FF);
  static const mint = Color(0xFF9FE5D2);
  static const lavender = Color(0xFFC9C4F2);
  static const peach = Color(0xFFFCDBB2);
  static const sunny = Color(0xFFFFE3A3);
  static const border = Color(0xFFE8EEF3);
  static const destructive = Color(0xFFFF6B6B);

  // aliases used across screens
  static const text = foreground;
  static const navy = Color(0xFF1C2B36);
  static const coin = Color(0xFFE8B84A);
  static const mind = lavender;
  static const danger = destructive;
  static const success = Color(0xFF3CBF8A);
  static const stress = Color(0xFFF4B459);
  static const cal = Color(0xFFFF9F43);
  static const dist = primary;
  static const hr = destructive;

  // legacy sky names → soft mind gradient
  static const skyTop = primarySoft;
  static const skyMid = Color(0xFFF7FBFE);
  static const skyBottom = background;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      fontFamily: 'NotoSansKR',
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: WSColors.primary,
        onPrimary: Colors.white,
        secondary: WSColors.secondary,
        onSecondary: WSColors.secondaryForeground,
        surface: WSColors.card,
        onSurface: WSColors.foreground,
        error: WSColors.destructive,
        outline: WSColors.border,
      ),
      scaffoldBackgroundColor: WSColors.background,
    );

    final textTheme = base.textTheme
        .apply(fontFamily: 'NotoSansKR')
        .apply(
          bodyColor: WSColors.foreground,
          displayColor: WSColors.foreground,
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: WSColors.background,
        foregroundColor: WSColors.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: WSColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WSColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: WSColors.secondary,
        selectedColor: WSColors.primarySoft,
        labelStyle: const TextStyle(
          color: WSColors.secondaryForeground,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WSColors.card,
        hintStyle: const TextStyle(color: WSColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WSColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WSColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: WSColors.primarySoft,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? WSColors.primaryDark : WSColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? WSColors.primary : WSColors.muted,
          );
        }),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      fontFamily: 'NotoSansKR',
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: WSColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1A22),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'NotoSansKR'),
    );
  }
}

/// 마음서비스형 소프트 그라데이션 배경 (+ 떠다니는 구름)
class SkyBackground extends StatelessWidget {
  const SkyBackground({
    super.key,
    required this.child,
    this.dark = false,
    this.hero = false,
  });

  final Widget child;
  final bool dark;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1A22), Color(0xFF152430), Color(0xFF1A2C3A)],
          ),
        ),
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                WSColors.primarySoft,
                Color(0xFFF7FBFE),
                WSColors.background,
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        if (hero) const Positioned.fill(child: _SoftClouds(opacity: 0.55)),
        child,
      ],
    );
  }
}

class _SoftClouds extends StatefulWidget {
  const _SoftClouds({this.opacity = 0.7});
  final double opacity;

  @override
  State<_SoftClouds> createState() => _SoftCloudsState();
}

class _SoftCloudsState extends State<_SoftClouds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              painter: _CloudPainter(t: _ctrl.value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    void cloud(double yFrac, double speed, double scale, double phase) {
      final x = ((t * speed + phase) % 1.4 - 0.2) * size.width;
      final y = size.height * yFrac;
      final w = 90.0 * scale;
      final h = 36.0 * scale;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.28, y - h * 0.35),
          width: w * 0.55,
          height: h * 0.9,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - w * 0.22, y - h * 0.2),
          width: w * 0.45,
          height: h * 0.75,
        ),
        paint,
      );
    }

    cloud(0.12, 1.0, 1.1, 0.0);
    cloud(0.28, 0.75, 0.8, 0.35);
    cloud(0.52, 1.15, 1.25, 0.15);
    cloud(0.7, 0.85, 0.9, 0.55);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => oldDelegate.t != t;
}

/// 마음서비스 Card — 흰 배경 · 20px 라운드 · soft shadow
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.radius = 20,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (dark ? const Color(0xCC1B2A44) : WSColors.card),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark ? Colors.white12 : WSColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2B36).withValues(alpha: dark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// 마음서비스형 floating bottom nav shell
class MindBottomBar extends StatelessWidget {
  const MindBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_rounded, '홈'),
    (Icons.favorite_rounded, '마인드'),
    (Icons.bar_chart_rounded, '기록'),
    (Icons.shopping_bag_rounded, '샵'),
    (Icons.person_rounded, '마이'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: WSColors.background.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: WSColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: WSColors.primary.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: index == i
                            ? WSColors.primarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _items[i].$1,
                            size: 22,
                            color: index == i
                                ? WSColors.primary
                                : WSColors.muted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: index == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: index == i
                                  ? WSColors.primary
                                  : WSColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 빠른 액션 아이콘 타일 (마음서비스 Home QUICK_ACTIONS)
class SoftActionTile extends StatelessWidget {
  const SoftActionTile({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WSColors.secondaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}
