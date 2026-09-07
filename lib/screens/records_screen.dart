import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/detail_charts.dart';
import 'ranking_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => SkyBackground(
    dark: store.darkMode,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('기록')),
                  ButtonSegment(value: true, label: Text('랭킹')),
                ],
                selected: {store.recordsRanking},
                onSelectionChanged: (value) =>
                    store.selectRecordsSection(value.first),
              ),
            ),
          ),
          Expanded(
            child: store.recordsRanking
                ? RankingPanel(store: store)
                : _RecordDetails(store: store),
          ),
        ],
      ),
    ),
  );
}

class _RecordDetails extends StatelessWidget {
  const _RecordDetails({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return SkyBackground(
      dark: store.darkMode,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              '기록',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Text(
              '세부 그래프 · 걸음 검증 · 코인 원장 · ESG',
              style: TextStyle(color: WSColors.muted),
            ),
            const SizedBox(height: 14),
            if (store.meditationHistory.isNotEmpty) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '걷기 명상 기록',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    for (final entry in store.meditationHistory.take(10))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          entry['greenWalk'] == true
                              ? Icons.eco_outlined
                              : Icons.headphones_rounded,
                          color: WSColors.primary,
                        ),
                        title: Text(
                          '${entry['minutes']}분 ${entry['greenWalk'] == true ? '지구를 걷는 마음 · 체험' : '걷기 명상'}',
                        ),
                        subtitle: Text(
                          '${(entry['startedAt'] as String? ?? '').split('T').first} · ${entry['steps']}걸음 · ${((entry['distanceMeters'] as num? ?? 0) / 1000).toStringAsFixed(2)}km',
                        ),
                        trailing: Text(
                          entry['completed'] == true ? '완료' : '중도 종료',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            GlassCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  '활동 미션',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  for (final mission in store.missions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        mission.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(mission.title),
                      subtitle: Text(
                        '${mission.progress.clamp(0, mission.target)}/${mission.target} · +${mission.rewardWsc}',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: mission.ready
                            ? () => store.claimMission(mission.id)
                            : null,
                        child: Text(mission.claimed ? '완료' : '받기'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DetailChartsPanel(store: store),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '주간 케어 · ESG 요약',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _KV('명상', '${store.breathingSessions}회'),
                  _KV('플로깅', '${store.ploggingSessions}회'),
                  _KV(
                    'ESG 종합',
                    '${store.esgScore}점 (E${store.envScore}/S${store.socialScore}/G${store.govScore})',
                  ),
                  _KV('탄소 추정', '${store.carbonSavedKg.toStringAsFixed(2)}kg'),
                  _KV('플랜', store.membershipLabel),
                  if (!store.isPremium)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '상세 AI 리포트는 Premium에서 확인할 수 있어요.',
                        style: TextStyle(color: WSColors.muted, fontSize: 12),
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
                  const Text(
                    '보상 정산 현황',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _KV(
                    '다음 코인까지',
                    '${store.stepsToNextCoin}걸음 (잔여 ${store.pendingSteps})',
                  ),
                  _KV(
                    '오늘 남은 한도',
                    '${store.remainingDailyCap}걸음 / ${RewardRules.dailyHardCapSteps}',
                  ),
                  _KV('검증 품질', '${(store.qualityScore * 100).round()}%'),
                  _KV('최근 정산', store.lastSettleNote),
                  _KV('윙코인 잔액', '${store.wsc}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wing Coin 원장',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '앱에서 직접 가산하지 않고 서버 확정분만 기록',
                    style: TextStyle(color: WSColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  for (final item in store.ledger.take(8))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(
                        [
                          item.at,
                          if (item.note != null) item.note!,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        '${item.amount > 0 ? '+' : ''}${item.amount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: item.amount >= 0
                              ? WSColors.success
                              : WSColors.text,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              onTap: store.openRankings,
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.leaderboard_outlined,
                  color: WSColors.primaryDark,
                ),
                title: Text('친구 · 주간 랭킹'),
                subtitle: Text('내 아이디로 친구와 함께 걷기'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '미션 전체',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  for (final m in store.missions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        m.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(m.title),
                      subtitle: Text(
                        '${m.progress.clamp(0, m.target)}/${m.target} · +${m.rewardWsc} 코인',
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
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              k,
              style: const TextStyle(color: WSColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
