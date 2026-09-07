import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/services/walking_meditation.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/screens/walking_meditation_screen.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'walking_integration_test.dart' show TestStepEngine, TestLocationEngine;

void main() {
  test('5/10/20 minute courses complete once at the deadline', () {
    for (final minutes in [5, 10, 20]) {
      var now = Duration.zero;
      final session = WalkingMeditation(elapsedClock: () => now);
      session.start(
        courseMinutes: minutes,
        campaign: false,
        totalSteps: 0,
        totalMeters: 0,
      );
      now = Duration(seconds: minutes * 60 - 1);
      session.tick();
      expect(session.status, MeditationStatus.running);
      now = Duration(seconds: minutes * 60 + 7);
      session.tick();
      expect(session.status, MeditationStatus.completed);
      expect(session.elapsed.inSeconds, minutes * 60);
      session.tick();
      expect(session.toRecord()['completed'], true);
      session.dispose();
    }
  });

  test(
    'Paused time and movement are excluded; ending early is not completion',
    () {
      var now = Duration.zero;
      final session = WalkingMeditation(elapsedClock: () => now);
      session.start(
        courseMinutes: 20,
        campaign: true,
        totalSteps: 500,
        totalMeters: 250,
      );
      now = const Duration(seconds: 300);
      session.sample(900, 500);
      session.pause(reason: '화면 잠금');
      now = const Duration(seconds: 900);
      session.sample(1500, 1000);
      expect(session.elapsed.inSeconds, 300);
      expect(session.steps, 400);
      expect(session.distanceMeters, 250);
      session.resume(totalSteps: 1500, totalMeters: 1000);
      now = const Duration(seconds: 960);
      session.sample(1600, 1200);
      session.end();
      expect(session.elapsed.inSeconds, 360);
      expect(session.steps, 500);
      expect(session.distanceMeters, 450);
      expect(session.toRecord()['completed'], false);
      expect(
        () => session.start(
          courseMinutes: 5,
          campaign: true,
          totalSteps: 0,
          totalMeters: 0,
        ),
        throwsArgumentError,
      );
      session.dispose();
    },
  );

  test(
    'Completed course records once, stops owned walking and never grants campaign points or coins',
    () async {
      var now = Duration.zero;
      final session = WalkingMeditation(elapsedClock: () => now);
      final sensor = TestStepEngine();
      final store = AppStore(
        stepEngine: sensor,
        locationEngine: TestLocationEngine(),
        meditation: session,
      );
      final coins = store.wsc;
      await store.startWalkingMeditation(20, greenWalk: true);
      sensor.emitSteps(100);
      now = const Duration(minutes: 20);
      session.tick();
      await Future<void>.delayed(Duration.zero);
      expect(store.meditationHistory.length, 1);
      expect(store.meditationHistory.first['steps'], 100);
      expect(store.walking, false);
      expect(store.wsc, coins);
      session.tick();
      expect(store.meditationHistory.length, 1);
      store.dispose();
    },
  );

  testWidgets(
    'Course selection and pause keep a single session across page navigation',
    (tester) async {
      final store = AppStore(
        stepEngine: TestStepEngine(),
        locationEngine: TestLocationEngine(),
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: WalkingMeditationScreen(store: store),
        ),
      );
      await tester.tap(find.text('5분'));
      await tester.pump();
      expect(find.text('05:00'), findsOneWidget);
      await tester.ensureVisible(find.text('걷기 명상 시작'));
      await tester.tap(find.text('걷기 명상 시작'));
      await tester.pump();
      expect(store.meditation.minutes, 5);
      expect(store.meditation.status, MeditationStatus.running);
      await tester.tap(find.text('일시정지').last);
      await tester.pump();
      expect(store.meditation.status, MeditationStatus.paused);
      final id = store.meditation.id;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: WalkingMeditationScreen(store: store, greenWalk: true),
        ),
      );
      expect(store.meditation.id, id);
      expect(store.meditation.greenWalk, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
