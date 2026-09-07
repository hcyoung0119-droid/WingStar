import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/breathing_sheet.dart';
import 'package:wingstar/widgets/step_ring.dart';
import 'package:wingstar/widgets/walking_panel.dart';
import 'package:wingstar/screens/walking_meditation_screen.dart';

class WalkingScreen extends StatelessWidget {
  const WalkingScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => _ActivityPage(
      title: '걷기',
      dark: store.darkMode,
      children: [
        const Text('내 속도로 가볍게 걸어보세요.', style: TextStyle(color: WSColors.muted)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => WalkingMeditationScreen(store: store),
            ),
          ),
          icon: const Icon(Icons.headphones_rounded),
          label: const Text('음악과 함께 걷기 명상'),
        ),
        const SizedBox(height: 20),
        Center(
          child: StepRing(
            progress: store.stepProgress,
            steps: store.steps,
            goal: store.stepGoal,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: store.syncing ? null : store.syncOrWalk,
          icon: Icon(
            store.walking ? Icons.stop_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            store.syncing
                ? '센서 준비 중…'
                : store.walking
                ? '걷기 종료'
                : '걷기 시작',
          ),
        ),
        const SizedBox(height: 14),
        WalkingPanel(store: store),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GPS 거리 ${store.distanceKm.toStringAsFixed(2)} km',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '활동 ${store.walkElapsed.inMinutes}분 · 소모 ${store.calories} kcal',
                style: const TextStyle(color: WSColors.muted),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: store.pendingProgress),
              const SizedBox(height: 6),
              Text(
                '다음 적립까지 ${store.stepsToNextCoin}걸음',
                style: const TextStyle(color: WSColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => _ActivityPage(
      title: '명상',
      dark: store.darkMode,
      children: [
        GlassCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => WalkingMeditationScreen(store: store),
            ),
          ),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.headphones_rounded, color: WSColors.mind),
            title: Text(
              '걷기 명상 코스',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('5·10·20분 · 음악과 함께 내 속도로'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          color: WSColors.lavender.withValues(alpha: .25),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.air_rounded, size: 64, color: WSColors.mind),
              const SizedBox(height: 16),
              const Text(
                '잠시 멈추는 1분',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                '편안히 앉아 어깨의 힘을 빼고,\n들이쉬고 내쉬는 숨에 집중해 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WSColors.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      BreathingSheet(onDone: store.completeBreathing),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('1분 호흡 명상 시작'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Text(
            '완료한 호흡 명상 ${store.breathingSessions}회',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class PloggingScreen extends StatefulWidget {
  const PloggingScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<PloggingScreen> createState() => _PloggingScreenState();
}

class _PloggingScreenState extends State<PloggingScreen> {
  int pieces = 1;
  bool saved = false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => _ActivityPage(
      title: '플로깅',
      dark: widget.store.darkMode,
      children: [
        GlassCard(
          color: WSColors.mint.withValues(alpha: .3),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.recycling_rounded, size: 48, color: WSColors.success),
              SizedBox(height: 16),
              Text(
                '산책길에 작은 실천',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              Text(
                '장갑과 봉투를 챙기고, 길에서 만난 쓰레기를 주워 분리배출해 주세요.',
                style: TextStyle(height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            children: [
              const Text(
                '이번에 주운 쓰레기',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: '쓰레기 수 줄이기',
                    onPressed: saved || pieces <= 1
                        ? null
                        : () => setState(() => pieces--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '$pieces개',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '쓰레기 수 늘리기',
                    onPressed: saved || pieces >= 999
                        ? null
                        : () => setState(() => pieces++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: saved
                    ? null
                    : () {
                        widget.store.recordPlogging(pieces);
                        setState(() => saved = true);
                      },
                child: Text(saved ? '기록 저장 완료' : '플로깅 기록 저장'),
              ),
              if (saved)
                TextButton(
                  onPressed: () => setState(() {
                    saved = false;
                    pieces = 1;
                  }),
                  child: const Text('새 활동 기록'),
                ),
              const SizedBox(height: 6),
              const Text(
                '직접 기록한 환경 실천으로 ESG 활동에 반영됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: WSColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '누적 ${widget.store.ploggingSessions}회 · ${widget.store.litterCollected}개',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (widget.store.lastPloggingAt != null)
                Text(
                  '최근 활동 ${DateFormat('yyyy.MM.dd').format(widget.store.lastPloggingAt!.toLocal())}',
                  style: const TextStyle(color: WSColors.muted),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({
    required this.title,
    required this.dark,
    required this.children,
  });
  final String title;
  final bool dark;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
    body: SkyBackground(
      dark: dark,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: children,
        ),
      ),
    ),
  );
}
