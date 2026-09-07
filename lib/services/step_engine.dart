import 'dart:async';
import 'platform_bridge.dart' as bridge;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum StepEngineStatus {
  idle,
  calibrating,
  running,
  calibrationFailed,
  unavailable,
}

class StepEngine extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _calibrationWatchdog;

  final List<double> _samples = <double>[];
  DateTime? _calibrationStartedAt;
  DateTime? _lastStepAt;
  DateTime? _peakRaisedAt;

  bool _peakRaised = false;
  bool _disposed = false;

  StepEngineStatus status = StepEngineStatus.idle;

  int steps = 0;
  double gravityBaseline = 9.9;
  double currentMagnitude = 0;
  double currentMovement = 0;
  double calibrationProgress = 0;
  String statusMessage = 'FLOW를 시작하면 걸음 센서를 준비해요.';

  // Wingstar MVP 기본값.
  double highThreshold = 2.2;
  double lowThreshold = 0.9;
  Duration stepCooldown = const Duration(milliseconds: 300);
  Duration maxPeakDuration = const Duration(milliseconds: 800);

  static const Duration minCalibration = Duration(seconds: 3);
  static const Duration maxCalibration = Duration(seconds: 5);

  bool get isDesktop {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  bool get canUsePhysicalAccelerometer {
    if (kIsWeb) return bridge.browserMotionSupported;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> start() async {
    // Invoke iOS permission synchronously while the start tap is still active.
    final webPermission = kIsWeb ? bridge.requestMotionAccess() : null;
    await stop(resetStatusOnly: true);
    if (_disposed) return;

    steps = 0;
    currentMagnitude = 0;
    currentMovement = 0;
    gravityBaseline = 9.9;
    calibrationProgress = 0;
    _samples.clear();
    _lastStepAt = null;
    _peakRaisedAt = null;
    _peakRaised = false;

    if (!canUsePhysicalAccelerometer) {
      status = StepEngineStatus.unavailable;
      statusMessage = '이 기기에서는 가속도 센서를 사용할 수 없어 테스트 모드로 실행합니다.';
      _safeNotify();
      return;
    }

    if (webPermission != null && await webPermission != 'granted') {
      if (!_disposed) {
        _markUnavailable('동작 센서 권한이 필요해요. Safari에서 권한을 허용한 뒤 다시 시작해 주세요.');
      }
      return;
    }
    if (_disposed) return;
    status = StepEngineStatus.calibrating;
    statusMessage = '휴대폰을 편하게 들고 3~5초만 기다려주세요.';
    _calibrationStartedAt = DateTime.now();
    _safeNotify();

    try {
      _subscription =
          (kIsWeb
                  ? bridge.browserMotionEvents()
                  : accelerometerEventStream(
                      samplingPeriod: SensorInterval.gameInterval,
                    ))
              .listen(
                _onAccelerometer,
                onError: (Object error) {
                  _markUnavailable('가속도 센서 데이터를 읽지 못했습니다.');
                },
                cancelOnError: true,
              );

      _calibrationWatchdog = Timer.periodic(
        const Duration(milliseconds: 120),
        (_) => _checkCalibration(),
      );
    } catch (_) {
      _markUnavailable('이 환경에서는 가속도 센서를 시작할 수 없습니다.');
    }
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    currentMagnitude = magnitude;

    if (status == StepEngineStatus.calibrating) {
      _samples.add(magnitude);
      if (_samples.length > 1200) {
        _samples.removeRange(0, _samples.length - 1200);
      }
      return;
    }

    if (status == StepEngineStatus.running) {
      _processMotion(magnitude);
    }
  }

  void _checkCalibration() {
    if (status != StepEngineStatus.calibrating ||
        _calibrationStartedAt == null) {
      return;
    }

    final elapsed = DateTime.now().difference(_calibrationStartedAt!);
    calibrationProgress =
        (elapsed.inMilliseconds / maxCalibration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();

    if (elapsed >= minCalibration && _samples.length >= 30) {
      final recent = _samples.length > 100
          ? _samples.sublist(_samples.length - 100)
          : List<double>.from(_samples);
      final deviation = _standardDeviation(recent);

      if (deviation <= 0.45) {
        _finishCalibration();
        return;
      }
    }

    if (elapsed >= maxCalibration) {
      if (_samples.length < 20) {
        _markUnavailable('센서 신호가 들어오지 않았습니다. PC에서는 테스트 모드를 사용해 주세요.');
        return;
      }

      final deviation = _standardDeviation(_samples);
      if (deviation <= 0.90) {
        _finishCalibration();
      } else {
        _subscription?.cancel();
        _subscription = null;
        _calibrationWatchdog?.cancel();
        _calibrationWatchdog = null;
        status = StepEngineStatus.calibrationFailed;
        statusMessage = '보정 중 움직임이 너무 컸어요. 휴대폰을 잠시 안정적으로 유지한 뒤 다시 시도해 주세요.';
        calibrationProgress = 1;
        _safeNotify();
      }
    } else {
      _safeNotify();
    }
  }

  void _finishCalibration() {
    gravityBaseline = _median(_samples);
    status = StepEngineStatus.running;
    statusMessage = '측정 중 · 흔들림 피크 1회마다 1걸음으로 인식합니다.';
    calibrationProgress = 1;
    _calibrationWatchdog?.cancel();
    _calibrationWatchdog = null;
    _safeNotify();
  }

  void _processMotion(double magnitude) {
    final now = DateTime.now();
    final movement = (magnitude - gravityBaseline).abs();
    currentMovement = movement;

    if (!_peakRaised && movement >= highThreshold) {
      _peakRaised = true;
      _peakRaisedAt = now;
      _safeNotify();
      return;
    }

    if (_peakRaised) {
      final peakAge = _peakRaisedAt == null
          ? Duration.zero
          : now.difference(_peakRaisedAt!);

      if (peakAge > maxPeakDuration) {
        _peakRaised = false;
        _peakRaisedAt = null;
        _safeNotify();
        return;
      }

      if (movement <= lowThreshold) {
        final cooldownPassed =
            _lastStepAt == null || now.difference(_lastStepAt!) >= stepCooldown;

        if (cooldownPassed) {
          steps += 1;
          _lastStepAt = now;
        }

        _peakRaised = false;
        _peakRaisedAt = null;
        _safeNotify();
      }
    }
  }

  /// Windows/macOS/Linux 데스크톱에서 UI 개발용.
  /// 실제 모바일 리워드 판정에는 사용하지 않는다.
  void simulateShake() {
    steps += 1;
    statusMessage = '테스트 흔들림 +1';
    _safeNotify();
  }

  void setSensitivity(String value) {
    switch (value) {
      case 'high':
        highThreshold = 1.8;
        lowThreshold = 0.7;
        break;
      case 'low':
        highThreshold = 2.8;
        lowThreshold = 1.1;
        break;
      default:
        highThreshold = 2.2;
        lowThreshold = 0.9;
        break;
    }
    _safeNotify();
  }

  Future<void> retryCalibration() => start();

  Future<void> stop({bool resetStatusOnly = false}) async {
    _calibrationWatchdog?.cancel();
    _calibrationWatchdog = null;
    await _subscription?.cancel();
    _subscription = null;
    _peakRaised = false;
    _peakRaisedAt = null;

    if (!resetStatusOnly) {
      status = StepEngineStatus.idle;
      statusMessage = 'FLOW가 종료되었습니다.';
      _safeNotify();
    }
  }

  void _markUnavailable(String message) {
    _calibrationWatchdog?.cancel();
    _calibrationWatchdog = null;
    _subscription?.cancel();
    _subscription = null;
    status = StepEngineStatus.unavailable;
    statusMessage = message;
    _safeNotify();
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 9.9;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
  }

  double _standardDeviation(List<double> values) {
    if (values.length < 2) return double.infinity;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values
            .map((v) => math.pow(v - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _calibrationWatchdog?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
