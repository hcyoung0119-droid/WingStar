import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wingstar/theme/app_theme.dart';

/// PC(넓은 화면)에서는 폰 프레임으로, 폰/좁은 화면에서는 전체 화면으로 표시.
/// 같은 Flutter 앱이 Chrome(PC)·모바일 브라우저·Android에서 동일하게 동작합니다.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});

  final Widget child;

  static const frameWidth = 390.0;
  static const breakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final useFrame = size.width >= breakpoint;

    if (!useFrame) {
      // 모바일·좁은 창: 전체 화면 (터치·키보드 insets 유지)
      return MediaQuery(
        data: mq.copyWith(
          textScaler: TextScaler.linear(
            mq.textScaler.scale(1).clamp(0.9, 1.15),
          ),
        ),
        child: child,
      );
    }

    final frameHeight = min(844.0, max(640.0, size.height * 0.9));
    final innerW = frameWidth - 20;
    final innerH = frameHeight - 20;

    return ColoredBox(
      color: const Color(0xFFF4F9FC),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F6FF),
                  Color(0xFFF4F9FC),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: WSColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: WSColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'WingStar',
                        style: TextStyle(
                          color: WSColors.foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        kIsWeb ? 'PC · Web' : 'PC · Desktop',
                        style: TextStyle(
                          color: WSColors.muted.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '창을 좁히면 모바일 전체화면 · 넓으면 폰 프레임',
                    style: TextStyle(
                      color: WSColors.muted.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: frameWidth,
                    height: frameHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: WSColors.border, width: 8),
                      boxShadow: [
                        BoxShadow(
                          color: WSColors.primary.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: MediaQuery(
                        data: mq.copyWith(
                          size: Size(innerW, innerH),
                          viewInsets: EdgeInsets.only(
                            bottom: min(mq.viewInsets.bottom, innerH * 0.45),
                          ),
                          padding: EdgeInsets.only(
                            top: max(mq.padding.top > 0 ? 8 : 12, 8),
                            bottom: max(mq.padding.bottom, 0),
                          ),
                          viewPadding: const EdgeInsets.only(
                            top: 12,
                            bottom: 8,
                          ),
                          devicePixelRatio: mq.devicePixelRatio,
                          textScaler: TextScaler.linear(1.0),
                        ),
                        child: child,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '홈 · 마인드 · 기록 · 샵 · 마이',
                    style: TextStyle(
                      color: WSColors.primaryDark.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
