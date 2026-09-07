import 'package:flutter/material.dart';
import 'package:wingstar/screens/premium_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key, required this.store});
  final AppStore store;

  void _openPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PremiumScreen(store: store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = !store.isPremium;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 코칭'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SkyBackground(
        dark: store.darkMode,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: WSColors.primary),
                      SizedBox(width: 8),
                      Text(
                        '행동패턴 분석 · 맞춤 습관',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locked
                        ? '걸음·감정·ESG 데이터를 AI가 분석해 맞춤 습관을 추천합니다. Premium 이상 유료 서비스입니다.'
                        : 'Premium 혜택으로 상세 분석과 습관 추천을 이용 중이에요.',
                    style: const TextStyle(color: WSColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: WSColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: store.analyzingAi
                          ? null
                          : () async {
                              final ok = await store.runAiBehaviorAnalysis();
                              if (!ok && context.mounted) _openPaywall(context);
                            },
                      icon: Icon(
                        store.analyzingAi
                            ? Icons.hourglass_top
                            : Icons.psychology_alt_rounded,
                      ),
                      label: Text(
                        store.analyzingAi
                            ? '분석 중…'
                            : (locked ? '잠금 · Premium으로 분석' : 'AI 분석 실행'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (locked) ...[
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => _openPaywall(context),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: WSColors.coin),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '멤버십 비교 · 구독하기',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
            if (store.behaviorInsights.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                '행동패턴 인사이트',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final insight in store.behaviorInsights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                insight.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${insight.score}점',
                              style: const TextStyle(
                                color: WSColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          insight.detail,
                          style: const TextStyle(
                            color: WSColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (store.habitRecommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '맞춤 습관 추천',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final h in store.habitRecommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_pillarEmoji(h.esgPillar)}  ${h.title}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          h.reason,
                          style: const TextStyle(
                            color: WSColors.muted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${h.durationMin}분 · ${_pillarLabel(h.esgPillar)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: WSColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: h.accepted
                                ? null
                                : () => store.acceptHabit(h.id),
                            child: Text(h.accepted ? '포커스 중' : '습관 수락'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (store.weeklyDeepReport != null) ...[
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '주간 딥 리포트',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.weeklyDeepReport!,
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '※ 의료 진단·처방이 아닙니다. 라이프스타일 가이드입니다.',
                      style: TextStyle(fontSize: 11, color: WSColors.muted),
                    ),
                  ],
                ),
              ),
            ],
            if (store.isMembershipPlus && store.growthPlan != null) ...[
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Membership+ 자기개발 플랜',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.growthPlan!,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ] else if (store.isPremium && !store.isMembershipPlus) ...[
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => _openPaywall(context),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '더 세밀한 자기개발이 필요하신가요?',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Membership+에서 4주 성장 플랜·번아웃 밴드·습관 무제한을 열어보세요.',
                      style: TextStyle(color: WSColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _pillarEmoji(EsgPillar p) => switch (p) {
    EsgPillar.environment => '🌱',
    EsgPillar.social => '🤝',
    EsgPillar.governance => '📋',
  };

  String _pillarLabel(EsgPillar p) => switch (p) {
    EsgPillar.environment => 'Environment',
    EsgPillar.social => 'Social',
    EsgPillar.governance => 'Governance',
  };
}
