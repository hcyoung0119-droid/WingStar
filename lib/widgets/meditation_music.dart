import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wingstar/services/platform_bridge.dart' as bridge;
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/services/walking_meditation.dart';
import 'package:wingstar/theme/app_theme.dart';

class MeditationMusic extends StatefulWidget {
  const MeditationMusic({super.key, required this.store});
  final AppStore store;
  @override
  State<MeditationMusic> createState() => _MeditationMusicState();
}

class _MeditationMusicState extends State<MeditationMusic> {
  Map<String, dynamic> data = {};
  Timer? timer;
  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }

  void refresh() {
    try {
      final next = jsonDecode(bridge.musicState()) as Map<String, dynamic>;
      if (mounted && jsonEncode(next) != jsonEncode(data)) {
        setState(() => data = next);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool get running =>
      widget.store.meditation.status == MeditationStatus.running;
  @override
  Widget build(BuildContext context) {
    final tracks = (data['tracks'] as List? ?? []).cast<Map>();
    final selected = tracks
        .where((t) => t['id'] == data['selected'])
        .firstOrNull;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '명상 음악',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              Switch(
                value: data['enabled'] == true,
                onChanged: !kIsWeb
                    ? null
                    : (value) {
                        bridge.enableMusic(value);
                        if (value && running) unawaited(bridge.playMusic());
                        refresh();
                      },
              ),
            ],
          ),
          if (tracks.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('${data['selected']}-${tracks.length}'),
              initialValue: data['selected'],
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '들을 음악',
                border: OutlineInputBorder(),
              ),
              items: tracks
                  .map(
                    (t) => DropdownMenuItem<String>(
                      value: t['id'],
                      child: Text(t['name'], overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                bridge.selectMusic(id);
                if (running) unawaited(bridge.playMusic());
                refresh();
              },
            ),
          const SizedBox(height: 8),
          Text(
            selected?['source'] ?? '기기 음악',
            style: const TextStyle(fontSize: 12, color: WSColors.muted),
          ),
          if (kIsWeb) ...[
            Row(
              children: [
                const Icon(Icons.volume_down_rounded, color: WSColors.muted),
                Expanded(
                  child: Slider(
                    value: (data['volume'] as num? ?? .45).toDouble(),
                    onChanged: (value) {
                      bridge.setMusicVolume(value);
                      refresh();
                    },
                    semanticFormatterCallback: (v) => '${(v * 100).round()}%',
                  ),
                ),
                IconButton(
                  tooltip: data['status'] == 'playing' ? '음악 일시정지' : '음악 미리 듣기',
                  onPressed: () {
                    if (data['status'] == 'playing') {
                      bridge.pauseMusic();
                    } else {
                      unawaited(bridge.playMusic().then((_) => refresh()));
                    }
                    refresh();
                  },
                  icon: Icon(
                    data['status'] == 'playing'
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: data['busy'] == true
                  ? null
                  : () {
                      if (running) {
                        widget.store.pauseMeditation(
                          reason: '음악을 고르는 동안 코스를 일시정지했어요.',
                        );
                      }
                      bridge.pickMusic();
                    },
              icon: const Icon(Icons.audio_file_outlined),
              label: Text(data['busy'] == true ? '음악 추가 중…' : '내 기기에서 음악 추가'),
            ),
            const Text(
              '선택한 파일만 이 브라우저에 저장합니다. MP3·M4A 권장, 최대 50MB. 브라우저 데이터를 지우면 다시 추가해야 해요.',
              style: TextStyle(
                color: WSColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (data['selected'] != null && data['selected'] != 'wingstar-calm')
              TextButton(
                onPressed: () async {
                  await bridge.removeMusic(data['selected']);
                  refresh();
                },
                child: const Text('이 음악 삭제'),
              ),
          ],
          if ((data['notice'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                data['notice'],
                style: const TextStyle(
                  fontSize: 12,
                  color: WSColors.primaryDark,
                ),
              ),
            ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('음악·음성 출처'),
                content: const SingleChildScrollView(
                  child: Text(
                    '고요한 발걸음\n제작·출처: WingStar 프로젝트 (2026.09)\n\n'
                    '이 앱을 위해 새로 작성한 합성 사운드입니다. 외부 곡·녹음 샘플을 사용하지 않고 부드러운 파형과 화음으로 재생합니다.\n\n'
                    '음성 안내는 WingStar의 문장을 기기의 한국어 음성으로 읽습니다. 지원 음성은 기기에 따라 다릅니다.\n\n'
                    '개인 음악의 출처와 이용 조건은 해당 파일에 따릅니다. 파일은 서버로 업로드하거나 공유하지 않습니다.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
            child: const Text('음악·음성 출처 보기'),
          ),
        ],
      ),
    );
  }
}
