import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/services/step_engine.dart';
import 'package:wingstar/services/location_engine.dart';

class TestStepEngine extends StepEngine {
  TestStepEngine({this.physical = true});
  final bool physical;
  @override
  bool get canUsePhysicalAccelerometer => physical;
  @override
  Future<void> start() async {
    steps = 0;
    status = physical ? StepEngineStatus.running : StepEngineStatus.unavailable;
    notifyListeners();
  }

  void emitSteps(int count) {
    steps = count;
    notifyListeners();
  }
}

class TestLocationEngine extends LocationEngine {
  int starts = 0;
  @override
  Future<void> start() async {
    starts++;
    distanceMeters = 0;
  }
}

void main() {
  test(
    'Sensor events update original ring and missions once across sessions',
    () async {
      final sensor = TestStepEngine();
      final location = TestLocationEngine();
      final store = AppStore(stepEngine: sensor, locationEngine: location);
      await store.syncOrWalk();
      expect(location.starts, 0);
      sensor.emitSteps(7);
      sensor.emitSteps(7);
      expect(store.steps, 7);
      expect(store.missions.first.progress, 7);
      await store.syncOrWalk();
      sensor.emitSteps(10);
      expect(store.steps, 7);
      await store.syncOrWalk();
      sensor.emitSteps(2);
      expect(store.steps, 9);
      expect(store.wsc, 120);
      store.dispose();
    },
  );

  test(
    'Desktop test steps do not award coins or advance actual activity',
    () async {
      final store = AppStore(
        stepEngine: TestStepEngine(physical: false),
        locationEngine: TestLocationEngine(),
      );
      store.simulateShake();
      expect(store.testSteps, 0);
      await store.syncOrWalk();
      store.simulateShake();
      expect(store.testSteps, 1);
      expect(store.steps, 0);
      expect(store.missions.first.progress, 0);
      expect(store.wsc, 120);
      await store.syncOrWalk();
      store.simulateShake();
      expect(store.testSteps, 1);
      store.dispose();
    },
  );

  test('GPS distance survives session changes and calibration retry', () async {
    final sensor = TestStepEngine();
    final location = TestLocationEngine();
    final store = AppStore(stepEngine: sensor, locationEngine: location)
      ..recordLocation = true;
    await store.syncOrWalk();
    expect(location.starts, 1);
    location.distanceMeters = 150;
    sensor.emitSteps(3);
    await store.retryCalibration();
    sensor.emitSteps(2);
    expect(store.steps, 5);
    await store.syncOrWalk();
    expect(store.distanceKm, 0.15);
    await store.syncOrWalk();
    location.distanceMeters = 50;
    expect(store.distanceKm, 0.2);
    store.dispose();
  });
}
