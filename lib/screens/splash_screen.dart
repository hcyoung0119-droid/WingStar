import 'package:flutter/material.dart';
import 'package:wingstar/theme/app_theme.dart';

/// 마음서비스 스플래시 톤 — soft gradient · clouds · sparkles.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _logo.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        hero: true,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _logo,
                  curve: Curves.easeOutBack,
                ),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: WSColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: WSColors.primary.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _logo,
                  curve: const Interval(0.35, 1),
                ),
                child: const Column(
                  children: [
                    Text(
                      'WingStar',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: WSColors.foreground,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '매일 조금씩, 몸과 마음을 돌보는 시간',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: WSColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: WSColors.primary.withValues(
                              alpha:
                                  0.3 + 0.7 * (((_pulse.value + i * 0.2) % 1)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
