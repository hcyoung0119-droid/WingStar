import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/step_engine.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';

class WalkingPanel extends StatelessWidget {
  const WalkingPanel({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final engine = store.stepEngine;
    final elapsed = store.walkElapsed;
    final time =
        '${elapsed.inMinutes.toString().padLeft(2, '0')}:'
        '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            store.walking ? '걷기 측정 · $time' : '걷기 측정 설정',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            engine.statusMessage,
            style: const TextStyle(fontSize: 11, color: WSColors.muted),
          ),
          children: [
            if (engine.status == StepEngineStatus.calibrating) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: engine.calibrationProgress),
            ],
            if (store.walking && store.isTestSession) ...[
              const SizedBox(height: 8),
              Text(
                '테스트 ${store.testSteps}걸음 · 활동·보상 제외',
                style: const TextStyle(fontSize: 12),
              ),
              OutlinedButton.icon(
                onPressed: store.syncing ? null : store.simulateShake,
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('테스트 흔들림 +1'),
              ),
            ],
            if (store.walking &&
                engine.status == StepEngineStatus.calibrationFailed)
              TextButton(
                onPressed: store.syncing ? null : store.retryCalibration,
                child: const Text('센서 다시 보정'),
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: store.sensitivity,
              decoration: const InputDecoration(
                labelText: '걸음 감지 민감도',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('낮음')),
                DropdownMenuItem(value: 'normal', child: Text('보통')),
                DropdownMenuItem(value: 'high', child: Text('높음')),
              ],
              onChanged: (value) {
                if (value != null) store.setSensitivity(value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('GPS 거리 함께 기록', style: TextStyle(fontSize: 13)),
              value: store.recordLocation,
              onChanged: store.walking || store.syncing
                  ? null
                  : store.setRecordLocation,
            ),
            if (store.recordLocation)
              Text(
                store.locationEngine.message,
                style: const TextStyle(fontSize: 12, color: WSColors.muted),
              ),
            if (kIsWeb)
              const Text(
                '아이폰은 동작 권한을 허용하고 앱 화면을 켜둔 동안 측정해요. 건강 앱 걸음 수는 가져오지 않습니다.',
                style: TextStyle(fontSize: 12, color: WSColors.muted),
              ),
            const Text(
              '걸음 보상 서버는 아직 연결되지 않았어요. 샵·구독·기존 기록은 데모입니다.',
              style: TextStyle(
                fontSize: 11,
                color: WSColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
