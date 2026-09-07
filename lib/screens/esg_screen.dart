import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

class EsgScreen extends StatelessWidget {
  const EsgScreen({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESG 임팩트'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SkyBackground(
        dark: store.darkMode,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1B7A4E),
                    Color(0xFF3D9B6E),
                    Color(0xFF6BCB8B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '종합 ESG 점수',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${store.esgScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '탄소 약 ${store.carbonSavedKg.toStringAsFixed(2)}kg 상당 · '
                    '기부·응원·투명 보상으로 쌓이는 일상의 임팩트',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Pillar(
                  label: 'E 환경',
                  score: store.envScore,
                  color: const Color(0xFF2F9E44),
                ),
                const SizedBox(width: 8),
                _Pillar(
                  label: 'S 사회',
                  score: store.socialScore,
                  color: const Color(0xFF4C8DFF),
                ),
                const SizedBox(width: 8),
                _Pillar(
                  label: 'G 거버넌스',
                  score: store.govScore,
                  color: const Color(0xFF6B7FD7),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 ESG 액션',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _Line(
                    '🌱',
                    '에코 워킹',
                    '${NumberFormat('#,###').format(store.steps)}걸음 · 탄소 저감 추정',
                  ),
                  _Line('🤝', '응원·미소', '사회 액션 ${store.socialActions}회'),
                  _Line(
                    '📋',
                    '투명 보상',
                    '원장·품질 ${(store.qualityScore * 100).round()}%',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: store.markGovernanceReviewed,
                    child: const Text('보상 정책·원장 원칙 확인 (G)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESG 미션',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  for (final m in store.missions.where(
                    (m) => m.esgPillar != null,
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        m.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        m.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${m.progress.clamp(0, m.target)}/${m.target} · +${m.rewardWsc} · ${_pillar(m.esgPillar!)}',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: m.ready
                            ? () => store.claimMission(m.id)
                            : null,
                        child: Text(m.claimed ? '완료' : '받기'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () => store.setTab(3),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '샵에서 ESG 상품 교환',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '나무 기부권 · 리필 할인 · 봉사 배지를 Wing Coin으로 교환할 수 있어요.',
                    style: TextStyle(color: WSColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pillar(EsgPillar p) => switch (p) {
    EsgPillar.environment => 'E',
    EsgPillar.social => 'S',
    EsgPillar.governance => 'G',
  };
}

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: WSColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                color: color,
                backgroundColor: const Color(0xFFE9EDF5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.emoji, this.title, this.sub);
  final String emoji;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: WSColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
