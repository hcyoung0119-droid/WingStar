import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/screens/activity_screens.dart';
import 'package:wingstar/screens/walking_meditation_screen.dart';

class GreenWalkScreen extends StatelessWidget {
  const GreenWalkScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GREEN WALK')),
    body: SkyBackground(
      dark: store.darkMode,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              color: WSColors.mint.withValues(alpha: .4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPECIAL WALK · 캠페인 준비 중',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: WSColors.success,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '오늘은 나를 위해 걷고,\n지구를 위해 한 걸음 더.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '평소의 걷기 명상을 환경을 위한 행동으로 확장하는 특별 챌린지예요. 쓰레기 수를 겨루기보다, 나와 주변을 함께 돌보는 시간이 중심입니다.',
                    style: TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => WalkingMeditationScreen(
                          store: store,
                          greenWalk: true,
                        ),
                      ),
                    ),
                    child: const Text('「지구를 걷는 마음」 20분 미리 체험'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '예정된 참여 조건',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  for (final line in [
                    '걷기 명상 20분 완료',
                    'GPS로 기록한 거리 1km 이상',
                    '쓰레기 5개 이상 줍기',
                    '활동 후 사진 1장 · 운영진 확인',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('○  $line'),
                    ),
                  const Text(
                    '앱은 코스 시간·걸음·거리를 기록합니다. 쓰레기 수는 직접 기록하고, 사진을 통한 확인은 운영진이 맡습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: WSColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '운영 기간과 담당자가 미정이라 현재는 인증사진을 받거나 포인트를 지급하지 않습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: WSColors.primaryDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const GreenRewardPreview(),
            const SizedBox(height: 14),
            GlassCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PloggingScreen(store: store),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_note, color: WSColors.success),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '개인 플로깅 기록',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GreenRewardPreview extends StatelessWidget {
  const GreenRewardPreview({super.key});
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RE:WARD · GREEN POINT',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          '인증 후 포인트를 모아 버려진 자원으로 만든 굿즈로 연결합니다.',
          style: TextStyle(color: WSColors.muted, height: 1.5),
        ),
        const SizedBox(height: 12),
        const Text('예정 누적 포인트', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          '1회 100P · 3회 300P · 5회 600P · 10회 1,500P',
          style: TextStyle(fontSize: 13),
        ),
        const Divider(height: 28),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text('♻️', style: TextStyle(fontSize: 28)),
          title: Text('업사이클링 필통'),
          trailing: Text('1,000P'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text('👖', style: TextStyle(fontSize: 28)),
          title: Text('업사이클링 파우치'),
          trailing: Text('1,500P'),
        ),
        const SizedBox(height: 8),
        const Text(
          '기획 중인 리워드입니다. Green Point는 기존 윙코인과 별도로 운영할 예정이며, 지금은 포인트 적립·전환·굿즈 교환을 하지 않습니다.',
          style: TextStyle(fontSize: 12, color: WSColors.muted, height: 1.5),
        ),
      ],
    ),
  );
}
