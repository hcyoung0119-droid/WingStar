import 'dart:async';
import 'package:flutter/foundation.dart';

enum MeditationStatus { idle, running, paused, completed, ended }

class WalkingMeditation extends ChangeNotifier {
  WalkingMeditation({Duration Function()? elapsedClock})
    : _elapsedClock = elapsedClock {
    _clock.start();
  }
  final Duration Function()? _elapsedClock;
  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  Duration _accumulated = Duration.zero;
  Duration _anchor = Duration.zero;
  Duration get _now => _elapsedClock?.call() ?? _clock.elapsed;
  int minutes = 10;
  bool greenWalk = false;
  MeditationStatus status = MeditationStatus.idle;
  String? pauseReason;
  DateTime? startedAt;
  String? id;
  int steps = 0;
  double distanceMeters = 0;
  int _stepAnchor = 0;
  double _distanceAnchor = 0;
  int _savedSteps = 0;
  double _savedDistance = 0;
  bool get active =>
      status == MeditationStatus.running || status == MeditationStatus.paused;
  int get goalSeconds => minutes * 60;
  Duration get elapsed {
    final value =
        _accumulated +
        (status == MeditationStatus.running ? _now - _anchor : Duration.zero);
    return Duration(
      milliseconds: value.inMilliseconds.clamp(0, goalSeconds * 1000),
    );
  }

  int get remainingSeconds =>
      (goalSeconds - elapsed.inSeconds).clamp(0, goalSeconds);
  double get progress => elapsed.inMilliseconds / (goalSeconds * 1000);
  int get phase => (progress * 4).floor().clamp(0, 3);
  List<String> get cues => greenWalk
      ? const [
          '내 발이 땅에 닿는 감각을 느껴보세요.',
          '주변의 소리와 풍경을 천천히 바라보세요.',
          '걸음을 잠시 멈추고, 이 길에 도움이 필요한 곳이 있는지 살펴보세요.',
          '나와 지구를 위해 내어준 시간을 느껴보세요.',
        ]
      : const [
          '편안한 속도로 걸으며 발바닥의 감각을 느껴보세요.',
          '숨을 억지로 바꾸지 말고, 들고 나는 호흡을 바라보세요.',
          '생각이 떠오르면 알아차리고, 다시 한 걸음으로 돌아오세요.',
          '지금의 몸과 마음을 느끼며 천천히 마무리해 보세요.',
        ];

  void start({
    required int courseMinutes,
    required bool campaign,
    required int totalSteps,
    required double totalMeters,
  }) {
    if (active) return;
    if (![5, 10, 20].contains(courseMinutes) ||
        campaign && courseMinutes != 20) {
      throw ArgumentError('Unsupported walking meditation course');
    }
    minutes = courseMinutes;
    greenWalk = campaign;
    _accumulated = Duration.zero;
    _anchor = _now;
    _savedSteps = 0;
    _savedDistance = 0;
    steps = 0;
    distanceMeters = 0;
    _stepAnchor = totalSteps;
    _distanceAnchor = totalMeters;
    startedAt = DateTime.now();
    id = 'walk-${startedAt!.microsecondsSinceEpoch}';
    status = MeditationStatus.running;
    pauseReason = null;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    notifyListeners();
  }

  void sample(int totalSteps, double totalMeters) {
    if (status != MeditationStatus.running) return;
    steps = _savedSteps + (totalSteps - _stepAnchor).clamp(0, 1000000);
    distanceMeters =
        _savedDistance + (totalMeters - _distanceAnchor).clamp(0, 1000000);
  }

  void tick() {
    if (status != MeditationStatus.running) return;
    if (elapsed.inSeconds >= goalSeconds) {
      _accumulated = Duration(seconds: goalSeconds);
      status = MeditationStatus.completed;
      _ticker?.cancel();
    }
    notifyListeners();
  }

  void pause({String? reason}) {
    if (status != MeditationStatus.running) return;
    _accumulated = elapsed;
    _savedSteps = steps;
    _savedDistance = distanceMeters;
    status = MeditationStatus.paused;
    pauseReason = reason;
    notifyListeners();
  }

  void resume({required int totalSteps, required double totalMeters}) {
    if (status != MeditationStatus.paused) return;
    _anchor = _now;
    _stepAnchor = totalSteps;
    _distanceAnchor = totalMeters;
    status = MeditationStatus.running;
    pauseReason = null;
    notifyListeners();
  }

  void end() {
    if (!active) return;
    _accumulated = elapsed;
    status = MeditationStatus.ended;
    _ticker?.cancel();
    notifyListeners();
  }

  Map<String, Object?> toRecord() => {
    'id': id,
    'startedAt': startedAt?.toIso8601String(),
    'minutes': minutes,
    'elapsedSeconds': elapsed.inSeconds,
    'steps': steps,
    'distanceMeters': distanceMeters,
    'greenWalk': greenWalk,
    'completed': status == MeditationStatus.completed,
  };

  @override
  void dispose() {
    _ticker?.cancel();
    _clock.stop();
    super.dispose();
  }
}
