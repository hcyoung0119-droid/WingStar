import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/services/walking_meditation.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/screens/walking_meditation_screen.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'walking_integration_test.dart' show TestStepEngine, TestLocationEngine;

void main() {
  test('Custom minute courses complete once at their chosen deadline', () {
    for (final minutes in [1, 7, 17, 43, 120]) {
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
      final dial = tester.getRect(find.byKey(const Key('duration-dial')));
      final angle = 17 / 120 * 2 * math.pi - math.pi / 2;
      await tester.tapAt(
        dial.center +
            Offset(math.cos(angle), math.sin(angle)) * (dial.width / 2 - 18),
      );
      await tester.pump();
      expect(find.text('17분'), findsOneWidget);
      await tester.ensureVisible(find.text('걷기 명상 시작'));
      await tester.tap(find.text('걷기 명상 시작'));
      await tester.pump();
      expect(store.meditation.minutes, 17);
      expect(store.meditation.status, MeditationStatus.running);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('일시정지').last);
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

  testWidgets(
    'Time wheel selects arbitrary minutes and Green Walk keeps its minimum',
    (tester) async {
      final store = AppStore(
        stepEngine: TestStepEngine(),
        locationEngine: TestLocationEngine(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: WalkingMeditationScreen(store: store, greenWalk: true),
        ),
      );
      await tester.tap(find.byKey(const Key('duration-value')));
      await tester.pumpAndSettle();
      final wheel = tester.widget<CupertinoPicker>(
        find.byKey(const Key('duration-wheel')),
      );
      wheel.scrollController!.jumpToItem(17);
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      expect(find.text('37분'), findsOneWidget);
      await tester.ensureVisible(find.text('걷기 명상 시작'));
      await tester.tap(find.text('걷기 명상 시작'));
      await tester.pump();
      expect(store.meditation.minutes, 37);
      expect(store.meditation.greenWalk, true);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  test('Invalid durations never start sensors or create a session', () async {
    final store = AppStore(
      stepEngine: TestStepEngine(),
      locationEngine: TestLocationEngine(),
    );
    for (final minutes in [0, -5, 121]) {
      await store.startWalkingMeditation(minutes);
      expect(store.walking, false);
      expect(store.meditation.status, MeditationStatus.idle);
    }
    await store.startWalkingMeditation(19, greenWalk: true);
    expect(store.walking, false);
    store.dispose();
  });
}
