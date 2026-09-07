import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/services/ios_pedometer.dart';
import 'package:wingstar/services/step_engine.dart';
import 'package:wingstar/state/app_store.dart';

import 'walking_integration_test.dart' show TestLocationEngine;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const codec = StandardMethodCodec();
  final calls = <MethodCall>[];
  var nativeCount = 0;
  var day = DateTime.now().toIso8601String().substring(0, 10);
  var period = DateTime.now().millisecondsSinceEpoch;
  var token = '';
  var denied = false;

  Map<String, dynamic> snapshot([String? eventToken]) => {
    'token': eventToken ?? token,
    'steps': nativeCount,
    'day': day,
    'periodStartMs': period,
  };

  Future<void> emit([String? eventToken]) async {
    await messenger.handlePlatformMessage(
      'wingstar/walking/events',
      codec.encodeSuccessEnvelope(snapshot(eventToken)),
      (_) {},
    );
  }

  StepEngine sensor() => StepEngine(iosPedometer: IosPedometer());

  setUp(() {
    calls.clear();
    nativeCount = 0;
    token = '';
    denied = false;
    day = DateTime.now().toIso8601String().substring(0, 10);
    period = DateTime.now().millisecondsSinceEpoch;
    messenger.setMockMethodCallHandler(IosPedometer.methods, (call) async {
      calls.add(call);
      if (call.method == 'stop') return null;
      if (denied) throw PlatformException(code: 'permission_denied');
      if (call.method == 'start') token = call.arguments['token'] as String;
      return snapshot();
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('wingstar/walking/events'),
      (_) async => null,
    );
  });

  tearDown(() async {
    await Future<void>.delayed(Duration.zero);
    messenger.setMockMethodCallHandler(IosPedometer.methods, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('wingstar/walking/events'),
      null,
    );
  });

  test(
    'historical resume and repeated live snapshots count each step once',
    () async {
      final engine = sensor();
      final store = AppStore(
        stepEngine: engine,
        locationEngine: TestLocationEngine(),
      );
      await store.syncOrWalk();
      nativeCount = 80;
      await emit();
      expect(store.steps, 80);
      nativeCount = 310; // iOS collected these while Flutter was suspended.
      await engine.reconcile();
      await emit();
      nativeCount = 295; // An older live callback arrives after the query.
      await emit();
      expect(store.steps, 310);
      nativeCount = 340;
      await store
          .syncOrWalk(); // Final query must run before walking becomes false.
      expect(store.steps, 340);
      expect(store.walking, false);
      nativeCount = 400;
      await emit();
      expect(store.steps, 340);
      expect(store.wsc, 120);
      store.dispose();
    },
  );

  test(
    'reopening resumes the saved anchor without prompting or double credit',
    () async {
      String saved = '';
      AppStore open() => AppStore(
        stepEngine: sensor(),
        locationEngine: TestLocationEngine(),
        loadDeviceState: () => saved,
        saveDeviceState: (value) {
          saved = value;
          return true;
        },
      );
      final first = open();
      await first.syncOrWalk();
      nativeCount = 100;
      await emit();
      first.dispose();
      await Future<void>.delayed(Duration.zero);
      final checkpoint = jsonDecode(saved)['nativeWalk'];
      expect(checkpoint['accountedSteps'], 100);
      nativeCount = 160;
      final reopened = open();
      await reopened.restoreWalkingSession();
      expect(reopened.steps, 160);
      expect(reopened.walking, true);
      final start = calls.lastWhere((e) => e.method == 'start');
      expect(start.arguments['requestPermission'], false);
      expect(
        start.arguments['fromMs'],
        DateTime.parse(checkpoint['startedAt']).millisecondsSinceEpoch,
      );
      await emit();
      expect(reopened.steps, 160);
      await reopened.syncOrWalk();
      expect(jsonDecode(saved)['nativeWalk'], null);
      reopened.dispose();
      final stopped = open();
      await stopped.restoreWalkingSession();
      expect(stopped.walking, false);
      stopped.dispose();
    },
  );

  test(
    'history below the saved checkpoint never lowers its high water mark',
    () async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 10));
      final saved = jsonEncode({
        'date': day,
        'steps': 200,
        'nativeWalk': {
          'startedAt': startedAt.toIso8601String(),
          'day': day,
          'accountedSteps': 100,
        },
      });
      final store = AppStore(
        stepEngine: sensor(),
        locationEngine: TestLocationEngine(),
        loadDeviceState: () => saved,
      );
      nativeCount = 95;
      await store.restoreWalkingSession();
      nativeCount = 100;
      await emit();
      expect(store.steps, 200);
      nativeCount = 103;
      await emit();
      expect(store.steps, 203);
      store.dispose();
    },
  );

  test('old session and old day callbacks cannot enter a new count', () async {
    final engine = sensor();
    await engine.start();
    final oldToken = token;
    await engine.stop();
    await engine.start();
    nativeCount = 999;
    await emit(oldToken);
    expect(engine.steps, 0);
    nativeCount = 25;
    await emit();
    final yesterdayPeriod = period;
    period += const Duration(days: 1).inMilliseconds;
    day = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    nativeCount = 4;
    await emit();
    expect(engine.steps, 4);
    period = yesterdayPeriod;
    nativeCount = 1000;
    await emit();
    expect(engine.steps, 4);
    await engine.stop();
    engine.dispose();
  });

  test('denied motion permission never creates real steps', () async {
    denied = true;
    final store = AppStore(
      stepEngine: sensor(),
      locationEngine: TestLocationEngine(),
    );
    await store.syncOrWalk();
    expect(store.stepEngine.status, StepEngineStatus.unavailable);
    expect(store.stepEngine.statusMessage, contains('동작 및 피트니스'));
    expect(store.steps, 0);
    await store.syncOrWalk();
    expect(store.steps, 0);
    store.dispose();
  });
}
