import 'package:flutter/material.dart';
import 'package:wingstar/screens/activity_screens.dart';
import 'package:wingstar/screens/esg_screen.dart';
import 'package:wingstar/screens/green_walk_screen.dart';
import 'package:wingstar/screens/walking_meditation_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.onOpenMind});
  final AppStore store;
  final ValueChanged<MindSection> onOpenMind;

  void _push(BuildContext context, Widget Function() page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AnimatedBuilder(animation: store, builder: (_, _) => page()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = store.todayQuote;
    return SkyBackground(
      dark: store.darkMode,
      hero: true,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _Header(store: store),
            const SizedBox(height: 20),
            GlassCard(
              color: WSColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WALK FOR ME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: WSColors.primaryDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '오늘의 걷기 명상',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '내 마음을 돌보는 걸음에서,\n우리가 사는 지구를 돌보는 걸음으로.',
                    style: TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('home-walking-meditation'),
                    onPressed: () => _push(
                      context,
                      () => WalkingMeditationScreen(store: store),
                    ),
                    icon: const Icon(Icons.headphones_rounded),
                    label: Text(
                      store.meditation.active
                          ? '진행 중인 코스 이어서 보기'
                          : '5·10·20분 코스 고르기',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () =>
                        _push(context, () => GreenWalkScreen(store: store)),
                    icon: const Icon(Icons.eco_outlined),
                    label: const Text('SPECIAL WALK · GREEN WALK 살펴보기'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '내 활동 이어가기',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '오늘 필요한 활동을 골라보세요.',
              style: TextStyle(color: WSColors.muted),
            ),
            const SizedBox(height: 14),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 180,
              ),
              children: [
                _ActivityTile(
                  key: const Key('home-walking'),
                  title: '걷기',
                  icon: Icons.directions_walk_rounded,
                  color: WSColors.primary,
                  background: WSColors.primarySoft,
                  detail: '${store.steps}걸음',
                  subtitle: store.walking ? '측정 중 · 이어서 보기' : '내 속도로 가볍게',
                  onTap: () =>
                      _push(context, () => WalkingScreen(store: store)),
                ),
                _ActivityTile(
                  key: const Key('home-meditation'),
                  title: '명상',
                  icon: Icons.air_rounded,
                  color: WSColors.mind,
                  background: WSColors.lavender.withValues(alpha: .28),
                  detail: '${store.breathingSessions}회 완료',
                  subtitle: '숨을 고르는 시간',
                  onTap: () =>
                      _push(context, () => MeditationScreen(store: store)),
                ),
                _ActivityTile(
                  key: const Key('home-plogging'),
                  title: 'GREEN WALK',
                  icon: Icons.recycling_rounded,
                  color: WSColors.success,
                  background: WSColors.mint.withValues(alpha: .4),
                  detail: '환경 캠페인',
                  subtitle: '준비 중 · 개인 기록 가능',
                  onTap: () =>
                      _push(context, () => GreenWalkScreen(store: store)),
                ),
                _ActivityTile(
                  key: const Key('home-esg'),
                  title: 'ESG',
                  icon: Icons.public_rounded,
                  color: const Color(0xFFB18730),
                  background: WSColors.sunny.withValues(alpha: .48),
                  detail: '${store.esgScore}점',
                  subtitle: '함께 쌓는 좋은 변화',
                  onTap: () => _push(context, () => EsgScreen(store: store)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '마음 기록',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final item in [
                        (MindSection.emotion, '감정', '💙', WSColors.peach),
                        (MindSection.journal, '일기', '✍️', WSColors.lavender),
                        (MindSection.smile, '미소', '😊', WSColors.sunny),
                        (MindSection.calendar, '캘린더', '🗓️', WSColors.mint),
                      ])
                        Expanded(
                          child: SoftActionTile(
                            label: item.$2,
                            emoji: item.$3,
                            color: item.$4,
                            onTap: () => onOpenMind(item.$1),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              onTap: () => store.setTab(2),
              child: const Row(
                children: [
                  Icon(Icons.history_rounded, color: WSColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '활동 기록 · 미션',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              color: WSColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 문장',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: WSColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quote.$1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.detail,
    required this.subtitle,
    required this.onTap,
  });
  final String title, detail, subtitle;
  final IconData icon;
  final Color color, background;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    color: background,
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: WSColors.muted),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '좋은 하루예요',
                style: TextStyle(
                  fontSize: 13,
                  color: WSColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${store.name.isEmpty ? '친구' : store.name}님',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: WSColors.foreground,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        _Pill(
          onTap: () => store.setTab(3),
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${store.wsc}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: WSColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: WSColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: WSColors.border.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C2B36).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
