import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/services/walking_meditation.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/meditation_music.dart';
import 'package:wingstar/widgets/meditation_duration_dial.dart';

class WalkingMeditationScreen extends StatefulWidget {
  const WalkingMeditationScreen({
    super.key,
    required this.store,
    this.greenWalk = false,
  });
  final AppStore store;
  final bool greenWalk;
  @override
  State<WalkingMeditationScreen> createState() =>
      _WalkingMeditationScreenState();
}

class _WalkingMeditationScreenState extends State<WalkingMeditationScreen> {
  late int selectedMinutes;
  final scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    selectedMinutes = widget.greenWalk ? 20 : 10;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  String clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store, session = store.meditation;
      final active = session.active;
      final running = session.status == MeditationStatus.running;
      final completed = session.status == MeditationStatus.completed;
      final showSession =
          active || completed || session.status == MeditationStatus.ended;
      final green = active ? session.greenWalk : widget.greenWalk;
      return Scaffold(
        appBar: AppBar(title: Text(green ? '지구를 걷는 마음' : '걷기 명상')),
        body: SkyBackground(
          dark: store.darkMode,
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  green ? 'WALK FOR EARTH' : 'WALK FOR ME',
                  style: const TextStyle(
                    color: WSColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  green
                      ? '${active ? session.minutes : selectedMinutes}분, 나와 지구를 위한 걷기'
                      : '오늘의 걷기 명상',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '천천히 걸으며 호흡에 집중해 보세요.',
                  style: TextStyle(color: WSColors.muted),
                ),
                if (green)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '캠페인 준비 중 · 지금은 코스를 미리 체험할 수 있어요. 포인트는 지급되지 않습니다.',
                      style: TextStyle(fontSize: 12, color: WSColors.muted),
                    ),
                  ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      if (completed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${session.minutes}분 코스 완료',
                            style: const TextStyle(
                              color: WSColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (!active)
                        MeditationDurationDial(
                          minutes: selectedMinutes,
                          minimum: green
                              ? WalkingMeditation.greenMinimumMinutes
                              : WalkingMeditation.minMinutes,
                          maximum: WalkingMeditation.maxMinutes,
                          enabled: !store.preparingMeditation,
                          onChanged: (value) =>
                              setState(() => selectedMinutes = value),
                        ),
                      if (active)
                        SizedBox(
                          width: 190,
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: active || completed
                                      ? session.progress
                                      : 0,
                                  strokeWidth: 9,
                                  backgroundColor: WSColors.primarySoft,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    active || completed
                                        ? clock(session.remainingSeconds)
                                        : clock(selectedMinutes * 60),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    running
                                        ? '걷고, 숨 쉬는 중'
                                        : session.status ==
                                              MeditationStatus.paused
                                        ? '일시정지'
                                        : completed
                                        ? '코스 완료'
                                        : '나를 위한 시간',
                                    style: const TextStyle(
                                      color: WSColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (active)
                        Text(
                          session.cues[session.phase],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (session.pauseReason != null &&
                          session.status == MeditationStatus.paused)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            session.pauseReason!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: WSColors.muted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: store.preparingMeditation
                              ? null
                              : running
                              ? store.pauseMeditation
                              : session.status == MeditationStatus.paused
                              ? store.resumeMeditation
                              : () async {
                                  await store.startWalkingMeditation(
                                    selectedMinutes,
                                    greenWalk: widget.greenWalk,
                                  );
                                  if (mounted && scrollController.hasClients) {
                                    await scrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                          icon: Icon(
                            running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            store.preparingMeditation
                                ? '센서와 음악 준비 중…'
                                : running
                                ? '일시정지'
                                : session.status == MeditationStatus.paused
                                ? '이어서 걷기'
                                : showSession
                                ? '새 코스 시작'
                                : '걷기 명상 시작',
                          ),
                        ),
                      ),
                      if (active)
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('이번 코스를 마칠까요?'),
                              content: const Text(
                                '지금까지 진행한 시간과 걸음을 기록합니다. 목표 시간 전에는 코스 완료로 처리하지 않습니다.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('계속하기'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    store.endMeditation();
                                  },
                                  child: const Text('마치기'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('이번 코스 마치기'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showSession
                            ? '${session.steps}걸음 · ${(session.distanceMeters / 1000).toStringAsFixed(2)} km · ${clock(session.elapsed.inSeconds)}'
                            : '코스별 걸음 · 거리 · 시간 기록',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (store.isTestSession && active)
                        const Text(
                          '이 기기에서는 실제 걸음 측정이 제한됩니다.',
                          style: TextStyle(fontSize: 12, color: WSColors.muted),
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('GPS 거리 기록'),
                        subtitle: Text(
                          store.recordLocation
                              ? store.locationEngine.message
                              : '거리 기록을 켜면 위치 권한을 요청합니다.',
                        ),
                        value: store.recordLocation,
                        onChanged:
                            active || store.walking || store.preparingMeditation
                            ? null
                            : store.setRecordLocation,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('음성 안내'),
                        subtitle: const Text('코스의 네 구간을 한국어 음성으로 안내'),
                        value: store.voiceGuidance,
                        onChanged: store.setVoiceGuidance,
                      ),
                      const Text(
                        '화면을 켠 상태로 이용해 주세요. 잠금·다른 앱으로 이동하면 코스와 음악이 일시정지됩니다. 주변 소리를 들을 수 있는 음량으로 걸어주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: WSColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MeditationMusic(store: store),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '코스 안내',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${clock((active ? session.minutes : selectedMinutes) * 60 * i ~/ 4)}–${clock((active ? session.minutes : selectedMinutes) * 60 * (i + 1) ~/ 4)} · '
                            '${green ? ['발이 땅에 닿는 감각', '소리와 풍경 알아차리기', '잠시 멈춰 주변을 돌보기', '나와 지구에게 감사하기'][i] : ['발걸음 느끼기', '호흡 바라보기', '생각을 흘려보내기', '몸과 마음 살피기'][i]}',
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
