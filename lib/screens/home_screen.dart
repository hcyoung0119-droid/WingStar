import 'package:flutter/material.dart';
import '../widgets/walking_panel.dart';
import 'package:wingstar/screens/ai_coach_screen.dart';
import 'package:wingstar/screens/esg_screen.dart';
import 'package:wingstar/screens/premium_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/step_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onOpenBreathing,
    required this.onOpenMind,
  });

  final AppStore store;
  final VoidCallback onOpenBreathing;
  final VoidCallback onOpenMind;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final dark = store.darkMode;
    final quote = store.todayQuote;
    return SkyBackground(
      dark: dark,
      hero: true,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _Header(store: store),
            const SizedBox(height: 14),
            GlassCard(
              color: WSColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 문장',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: WSColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quote.$1,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: WSColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '— ${quote.$2}',
                    style: const TextStyle(color: WSColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!store.isPremium)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () => _push(context, PremiumScreen(store: store)),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: WSColors.coin,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI 맞춤 습관 · 행동분석은 Premium',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '보기',
                        style: TextStyle(
                          color: WSColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Center(
              child: StepRing(
                progress: store.stepProgress,
                steps: store.steps,
                goal: store.stepGoal,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                style:
                    FilledButton.styleFrom(
                      backgroundColor: WSColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ).copyWith(
                      shadowColor: WidgetStatePropertyAll(
                        WSColors.primary.withValues(alpha: 0.45),
                      ),
                      elevation: const WidgetStatePropertyAll(6),
                    ),
                onPressed: store.syncing ? null : store.syncOrWalk,
                icon: Icon(
                  store.syncing
                      ? Icons.sync
                      : (store.walking
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded),
                  size: 22,
                ),
                label: Text(
                  store.syncing
                      ? '센서 준비 중…'
                      : (store.walking ? '걷기 종료' : '걷기 시작'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            WalkingPanel(store: store),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SoftActionTile(
                    label: '감정',
                    emoji: '💙',
                    color: WSColors.peach,
                    onTap: onOpenMind,
                  ),
                ),
                Expanded(
                  child: SoftActionTile(
                    label: '호흡',
                    emoji: '🌬️',
                    color: WSColors.lavender,
                    onTap: onOpenBreathing,
                  ),
                ),
                Expanded(
                  child: SoftActionTile(
                    label: '미소',
                    emoji: '😊',
                    color: WSColors.sunny,
                    onTap: onOpenMind,
                  ),
                ),
                Expanded(
                  child: SoftActionTile(
                    label: 'ESG',
                    emoji: '🌱',
                    color: WSColors.mint,
                    onTap: () => _push(context, EsgScreen(store: store)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '다음 Wing Coin까지',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${store.pendingSteps}/${RewardRules.stepsPerCoin}걸음',
                        style: const TextStyle(
                          color: WSColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: store.pendingProgress,
                      minHeight: 7,
                      color: WSColors.primary,
                      backgroundColor: WSColors.mutedBg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '200걸음=1코인 · 잔여 이월 · 일일 한도 ${store.remainingDailyCap}걸음 · 1코인≈${RewardRules.coinWorthKrw}원',
                    style: const TextStyle(
                      color: WSColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: WSColors.cal,
                  value: '${store.calories}',
                  label: '칼로리',
                ),
                const SizedBox(width: 8),
                _Metric(
                  icon: Icons.location_on_rounded,
                  iconColor: WSColors.dist,
                  value: store.distanceKm.toStringAsFixed(2),
                  label: 'GPS 거리 (km)',
                ),
                const SizedBox(width: 8),
                _Metric(
                  icon: Icons.favorite_rounded,
                  iconColor: WSColors.hr,
                  value: '${store.heartRate}',
                  label: '심박수 (예시)',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    onTap: onOpenMind,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '오늘 기분',
                                style: TextStyle(
                                  color: WSColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: WSColors.muted.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          store.todayMind == null
                              ? '🫥'
                              : _emoji(store.todayMind!.emotion),
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.todayMind == null ? '아직 기록이\n없어요' : '기록됨',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassCard(
                    onTap: () => _push(context, EsgScreen(store: store)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESG 임팩트',
                          style: TextStyle(color: WSColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${store.esgScore}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3CBF8A),
                                  height: 1,
                                ),
                              ),
                              const TextSpan(
                                text: ' /100',
                                style: TextStyle(
                                  color: WSColors.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '탄소 ${store.carbonSavedKg.toStringAsFixed(1)}kg',
                          style: const TextStyle(
                            fontSize: 12,
                            color: WSColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${store.sleepHours}시간',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '어젯밤 수면',
                          style: TextStyle(color: WSColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassCard(
                    onTap: store.checkAttendance,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                              color: WSColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${store.streak}일 연속',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '탭하여 출석체크!',
                          style: TextStyle(
                            color: WSColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () => _push(
                context,
                store.isPremium
                    ? AiCoachScreen(store: store)
                    : PremiumScreen(store: store),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: WSColors.primarySoft,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: WSColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'AI 코치 윙이',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 6),
                            if (!store.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: WSColors.sunny,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.isPremium
                              ? store.wingiMessage
                              : '응원은 Free · 행동패턴·맞춤 습관 추천은 Premium',
                          style: const TextStyle(
                            color: WSColors.muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '오늘의 미션',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${store.missions.where((m) => m.claimed).length} / ${store.missions.length} 완료',
                        style: const TextStyle(
                          color: WSColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final m in store.missions)
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: m.claimed
                                ? WSColors.mint.withValues(alpha: 0.45)
                                : WSColors.secondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            m.claimed ? '✓' : m.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final m in store.missions.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m.emoji}  ${m.title}${m.esgPillar != null ? ' · ESG' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${m.progress.clamp(0, m.target)}/${m.target}',
                            style: const TextStyle(
                              color: WSColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: WSColors.primarySoft,
                              foregroundColor: WSColors.primaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onPressed: m.ready
                                ? () => store.claimMission(m.id)
                                : null,
                            child: Text(m.claimed ? '완료' : '받기'),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onOpenBreathing,
                      icon: const Icon(
                        Icons.air_rounded,
                        color: WSColors.primary,
                      ),
                      label: const Text(
                        '1분 심호흡 미션',
                        style: TextStyle(color: WSColors.primaryDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌿  서비스직 힐링 팁 · ${store.job}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '퇴근길엔 오늘 잘한 일 한 가지를 떠올려보세요. 뇌는 기록된 성취를 기억합니다.',
                    style: TextStyle(color: WSColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '객실 ${store.cabinLabel} · ${store.membershipLabel} · ESG ${store.esgScore}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: WSColors.primaryDark,
                      fontWeight: FontWeight.w700,
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

  String _emoji(Emotion e) => switch (e) {
    Emotion.great => '😄',
    Emotion.good => '🙂',
    Emotion.okay => '😐',
    Emotion.hard => '😞',
    Emotion.exhausted => '😢',
  };
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
        const SizedBox(width: 8),
        _Pill(
          child: Badge(
            isLabelVisible: true,
            backgroundColor: WSColors.destructive,
            label: const Text('1', style: TextStyle(fontSize: 10)),
            child: Icon(
              Icons.notifications_none_rounded,
              color: WSColors.foreground.withValues(alpha: 0.75),
            ),
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: WSColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
