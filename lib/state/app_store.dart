import 'dart:convert';
import '../services/platform_bridge.dart' as bridge;
import 'dart:math';
import 'dart:async';
import '../services/step_engine.dart';
import '../services/location_engine.dart';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum CabinClass { economy, premiumEconomy, business, first }

enum Emotion { great, good, okay, hard, exhausted }

/// Free · Premium · Membership(더 깊은 자기개발)
enum MembershipTier { free, premium, membership }

enum EsgPillar { environment, social, governance }

/// ChatGPT 공유 스펙 기반 보상 상수.
/// 200걸음 = Wing Coin 1 · 잔여 걸음 이월 · 서버 확정 · 현금 환전 없음(쿠폰 소비).
class RewardRules {
  static const stepsPerCoin = 200;
  static const dailyHardCapSteps = 30000;
  static const coinWorthKrw = 1;
  static const minQualityToCredit = 0.55;
}

class Mission {
  Mission({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    required this.rewardWsc,
    this.progress = 0,
    this.claimed = false,
    this.esgPillar,
  });

  final String id;
  final String title;
  final String emoji;
  final int target;
  final int rewardWsc;
  int progress;
  bool claimed;
  final EsgPillar? esgPillar;

  bool get ready => progress >= target && !claimed;

  Mission copyWith({int? progress, bool? claimed}) => Mission(
    id: id,
    title: title,
    emoji: emoji,
    target: target,
    rewardWsc: rewardWsc,
    progress: progress ?? this.progress,
    claimed: claimed ?? this.claimed,
    esgPillar: esgPillar,
  );
}

class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.job,
    required this.steps,
    required this.cabin,
  });

  final String id;
  final String name;
  final String job;
  final int steps;
  final CabinClass cabin;
}

class LedgerItem {
  const LedgerItem({
    required this.title,
    required this.amount,
    required this.at,
    this.note,
  });

  final String title;
  final int amount;
  final String at;
  final String? note;
}

class MindEntry {
  const MindEntry({
    required this.date,
    required this.emotion,
    required this.body,
    this.tags = const [],
  });

  final DateTime date;
  final Emotion emotion;
  final String body;
  final List<String> tags;
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  final String id;
  final String title;
  final String content;
  final DateTime date;
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.emoji,
    required this.category,
    required this.title,
    required this.price,
    this.esg = false,
  });

  final String id;
  final String emoji;
  final String category;
  final String title;
  final int price;
  final bool esg;
}

class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.emoji,
    required this.at,
  });

  final String id;
  final String title;
  final String emoji;
  final String at;
}

class HabitRecommendation {
  const HabitRecommendation({
    required this.id,
    required this.title,
    required this.reason,
    required this.esgPillar,
    required this.durationMin,
    this.accepted = false,
  });

  final String id;
  final String title;
  final String reason;
  final EsgPillar esgPillar;
  final int durationMin;
  final bool accepted;

  HabitRecommendation copyWith({bool? accepted}) => HabitRecommendation(
    id: id,
    title: title,
    reason: reason,
    esgPillar: esgPillar,
    durationMin: durationMin,
    accepted: accepted ?? this.accepted,
  );
}

class BehaviorInsight {
  const BehaviorInsight({
    required this.title,
    required this.detail,
    required this.score,
  });

  final String title;
  final String detail;
  final int score;
}

class MembershipPlan {
  const MembershipPlan({
    required this.tier,
    required this.title,
    required this.priceLabel,
    required this.period,
    required this.perks,
  });

  final MembershipTier tier;
  final String title;
  final String priceLabel;
  final String period;
  final List<String> perks;
}

class AppStore extends ChangeNotifier {
  AppStore({StepEngine? stepEngine, LocationEngine? locationEngine})
    : stepEngine = stepEngine ?? StepEngine(),
      locationEngine = locationEngine ?? LocationEngine() {
    this.stepEngine.addListener(_onSteps);
    this.locationEngine.addListener(_onLocation);
    if (kIsWeb) _restoreDeviceState();
  }

  final StepEngine stepEngine;
  final LocationEngine locationEngine;
  Timer? _walkTimer;
  Timer? _saveTimer;
  final Stopwatch _walkClock = Stopwatch();
  bool _disposed = false;
  int _accountedSteps = 0;
  int testSteps = 0;
  bool recordLocation = false;
  String sensitivity = 'normal';
  double _previousDistanceMeters = 0;
  Duration get walkElapsed => _walkClock.elapsed;
  bool get isTestSession =>
      !stepEngine.canUsePhysicalAccelerometer ||
      stepEngine.status == StepEngineStatus.unavailable;

  @override
  void notifyListeners() {
    if (_disposed) return;
    if (kIsWeb && !(_saveTimer?.isActive ?? false)) {
      _saveTimer = Timer(const Duration(milliseconds: 500), _saveDeviceState);
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (kIsWeb) _saveDeviceState();
    _saveTimer?.cancel();
    _disposed = true;
    _walkTimer?.cancel();
    _walkClock.stop();
    stepEngine.removeListener(_onSteps);
    locationEngine.removeListener(_onLocation);
    stepEngine.dispose();
    locationEngine.dispose();
    super.dispose();
  }

  void _saveDeviceState() {
    bridge.saveDeviceState(
      jsonEncode({
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'onboarded': onboarded,
        'name': name,
        'job': job,
        'darkMode': darkMode,
        'steps': steps,
        'stepGoal': stepGoal,
        'distance': distanceKm * 1000,
        'wsc': wsc,
        'pendingSteps': pendingSteps,
        'rewardedStepsToday': rewardedStepsToday,
        'xp': xp,
        'streak': streak,
        'attended': _attendedToday,
        'sensitivity': sensitivity,
        'recordLocation': recordLocation,
        'stress': stress,
        'ecoActions': ecoActions,
        'socialActions': socialActions,
        'governanceChecks': governanceChecks,
        'carbonSavedKg': carbonSavedKg,
        'smileCount': smileCount,
        'breathingSessions': breathingSessions,
        'journalCount': journalCount,
        'mind': mindEntries
            .map(
              (e) => {
                'date': e.date.toIso8601String(),
                'emotion': e.emotion.name,
                'body': e.body,
                'tags': e.tags,
              },
            )
            .toList(),
        'journals': journals
            .map(
              (e) => {
                'id': e.id,
                'date': e.date.toIso8601String(),
                'title': e.title,
                'content': e.content,
              },
            )
            .toList(),
        'ledger': ledger
            .map(
              (e) => {
                'title': e.title,
                'amount': e.amount,
                'at': e.at,
                'note': e.note,
              },
            )
            .toList(),
        'coupons': coupons
            .map(
              (e) => {
                'id': e.id,
                'title': e.title,
                'emoji': e.emoji,
                'at': e.at,
              },
            )
            .toList(),
        'missions': missions
            .map(
              (m) => {'id': m.id, 'progress': m.progress, 'claimed': m.claimed},
            )
            .toList(),
      }),
    );
  }

  void _restoreDeviceState() {
    try {
      final raw = bridge.loadDeviceState();
      if (raw.isEmpty) return;
      final d = jsonDecode(raw) as Map<String, dynamic>;
      final sameDay =
          d['date'] == DateTime.now().toIso8601String().substring(0, 10);
      onboarded = d['onboarded'] == true;
      name = d['name'] as String? ?? '';
      job = d['job'] as String? ?? job;
      darkMode = d['darkMode'] == true;
      stepGoal = d['stepGoal'] as int? ?? stepGoal;
      if (stepGoal < 1) stepGoal = 8000;
      steps = sameDay ? (d['steps'] as int? ?? 0) : 0;
      _previousDistanceMeters = sameDay
          ? (d['distance'] as num? ?? 0).toDouble()
          : 0;
      wsc = d['wsc'] as int? ?? wsc;
      pendingSteps = d['pendingSteps'] as int? ?? 0;
      rewardedStepsToday = sameDay ? (d['rewardedStepsToday'] as int? ?? 0) : 0;
      xp = d['xp'] as int? ?? xp;
      streak = d['streak'] as int? ?? 0;
      _attendedToday = sameDay && d['attended'] == true;
      // Device storage cannot prove a paid subscription.
      membership = MembershipTier.free;
      sensitivity = d['sensitivity'] as String? ?? 'normal';
      stepEngine.setSensitivity(sensitivity);
      recordLocation = d['recordLocation'] == true;
      stress = d['stress'] as int? ?? stress;
      ecoActions = d['ecoActions'] as int? ?? ecoActions;
      socialActions = d['socialActions'] as int? ?? socialActions;
      governanceChecks = d['governanceChecks'] as int? ?? governanceChecks;
      carbonSavedKg = (d['carbonSavedKg'] as num? ?? carbonSavedKg).toDouble();
      smileCount = d['smileCount'] as int? ?? 0;
      breathingSessions = d['breathingSessions'] as int? ?? 0;
      journalCount = d['journalCount'] as int? ?? 0;
      final restoredMind = (d['mind'] as List? ?? [])
          .map(
            (e) => MindEntry(
              date: DateTime.parse(e['date']),
              emotion: Emotion.values.byName(e['emotion']),
              body: e['body'],
              tags: List<String>.from(e['tags']),
            ),
          )
          .toList();
      final restoredJournals = (d['journals'] as List? ?? [])
          .map(
            (e) => JournalEntry(
              id: e['id'],
              date: DateTime.parse(e['date']),
              title: e['title'],
              content: e['content'],
            ),
          )
          .toList();
      final restoredLedger = (d['ledger'] as List? ?? [])
          .map(
            (e) => LedgerItem(
              title: e['title'],
              amount: e['amount'],
              at: e['at'],
              note: e['note'],
            ),
          )
          .toList();
      mindEntries
        ..clear()
        ..addAll(restoredMind);
      journals
        ..clear()
        ..addAll(restoredJournals);
      ledger
        ..clear()
        ..addAll(restoredLedger);
      // Old demo coupons are not fulfilled products.
      coupons.clear();
      if (sameDay) {
        for (final saved in d['missions'] as List? ?? []) {
          missions = missions
              .map(
                (m) => m.id == saved['id']
                    ? m.copyWith(
                        progress: saved['progress'],
                        claimed: saved['claimed'],
                      )
                    : m,
              )
              .toList();
        }
      }
    } catch (_) {
      // A damaged or incompatible local record must not prevent opening the app.
    }
  }

  void _onLocation() => notifyListeners();

  void _onSteps() {
    if (walking && !isTestSession) {
      final delta = stepEngine.steps - _accountedSteps;
      _accountedSteps = stepEngine.steps;
      if (delta > 0) {
        steps += delta;
        _bumpMission('m1', steps);
        _bumpMission('m6', steps);
      }
    }
    notifyListeners();
  }

  void simulateShake() {
    if (!walking || !isTestSession || syncing) return;
    stepEngine.simulateShake();
    testSteps = stepEngine.steps;
    notifyListeners();
  }

  void setSensitivity(String value) {
    sensitivity = value;
    stepEngine.setSensitivity(value);
  }

  Future<void> retryCalibration() async {
    if (!walking || syncing) return;
    syncing = true;
    notifyListeners();
    _accountedSteps = 0;
    await stepEngine.retryCalibration();
    if (_disposed) return;
    syncing = false;
    notifyListeners();
  }

  bool onboarded = false;
  String name = '';
  String job = '항공승무원';
  bool darkMode = false;

  int tab = 0;
  int steps = 0;
  int stepGoal = 8000;

  /// 지갑 잔액 (Wing Coin). 클라이언트에서 직접 가산하지 않고 settle 경로만 사용.
  int wsc = 120;

  /// 다음 코인까지 남은 걸음 풀 (ChatGPT: 650 → 3코인 + 잔여 50).
  int pendingSteps = 0;

  /// 오늘 보상 산정에 이미 반영된 걸음(일일 캡용).
  int rewardedStepsToday = 0;

  int streak = 0;
  int xp = 420;
  bool walking = false;
  bool syncing = false;
  bool analyzingAi = false;

  /// Anti-cheat quality ∈ [0,1]. 서버 검증 시뮬에 사용.
  double qualityScore = 0.95;
  int stress = 42;
  double sleepHours = 6.5;
  String? toast;
  String lastSettleNote = '서버 대기';
  String wingiMessage = '오늘도 누군가를 위해 웃은 당신, 이제 자신을 위해 걸어볼 시간이에요. ☁️';

  /// 유료 멤버십 (데모: 로컬 플래그)
  MembershipTier membership = MembershipTier.free;

  /// ESG 누적 임팩트
  int ecoActions = 1;
  int socialActions = 2;
  int governanceChecks = 1;
  double carbonSavedKg = 0.8;
  int smileCount = 0;
  int breathingSessions = 0;
  int journalCount = 0;

  List<BehaviorInsight> behaviorInsights = [];
  List<HabitRecommendation> habitRecommendations = [];
  String? weeklyDeepReport;
  String? growthPlan;

  final List<MindEntry> mindEntries = [];
  final List<JournalEntry> journals = [
    JournalEntry(
      id: 'j0',
      title: '고요한 아침',
      content: '창문을 열고 아침 공기를 마셨다. 새소리가 유난히 맑게 들리는 하루였다.',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
  final List<Coupon> coupons = [];
  final List<LedgerItem> ledger = [
    const LedgerItem(title: '웰컴 보너스', amount: 50, at: '탑승 시'),
    const LedgerItem(
      title: '걸음 적립',
      amount: 70,
      at: '오늘 09:12',
      note: '서버 검증 · 200걸음=1코인',
    ),
  ];

  late List<Mission> missions = [
    Mission(
      id: 'm1',
      title: '5,000걸음 걷기',
      emoji: '👟',
      target: 5000,
      rewardWsc: 20,
      progress: 0,
    ),
    Mission(id: 'm2', title: '감정 기록하기', emoji: '💙', target: 1, rewardWsc: 10),
    Mission(
      id: 'm3',
      title: '물 마시기 알림 확인',
      emoji: '💧',
      target: 1,
      rewardWsc: 5,
    ),
    Mission(id: 'm4', title: '1분 심호흡', emoji: '🌬️', target: 1, rewardWsc: 15),
    Mission(
      id: 'm5',
      title: '친구 응원하기',
      emoji: '🤝',
      target: 1,
      rewardWsc: 5,
      esgPillar: EsgPillar.social,
    ),
    Mission(
      id: 'm6',
      title: '에코 워킹 3,000걸음',
      emoji: '🌱',
      target: 3000,
      rewardWsc: 15,
      progress: 0,
      esgPillar: EsgPillar.environment,
    ),
    Mission(
      id: 'm7',
      title: '미소 짓기 연습',
      emoji: '😊',
      target: 1,
      rewardWsc: 8,
      esgPillar: EsgPillar.social,
    ),
    Mission(
      id: 'm8',
      title: '원장·보상 정책 확인',
      emoji: '📋',
      target: 1,
      rewardWsc: 5,
      esgPillar: EsgPillar.governance,
    ),
  ];

  final friends = const [
    Friend(
      id: 'f1',
      name: '준호',
      job: '호텔리어',
      steps: 9120,
      cabin: CabinClass.business,
    ),
    Friend(
      id: 'f2',
      name: '민지',
      job: '간호사',
      steps: 6400,
      cabin: CabinClass.premiumEconomy,
    ),
    Friend(
      id: 'f3',
      name: '하린',
      job: '카페 직원',
      steps: 10240,
      cabin: CabinClass.first,
    ),
  ];

  static const shopCatalog = [
    ShopItem(
      id: 's1',
      emoji: '☕',
      category: '카페',
      title: '아메리카노 쿠폰',
      price: 300,
    ),
    ShopItem(
      id: 's2',
      emoji: '🥛',
      category: '카페',
      title: '카페라떼 쿠폰',
      price: 350,
    ),
    ShopItem(
      id: 's3',
      emoji: '🏪',
      category: '편의점',
      title: '편의점 1,000원권',
      price: 500,
    ),
    ShopItem(
      id: 's4',
      emoji: '🍰',
      category: '베이커리',
      title: '디저트 교환권',
      price: 450,
    ),
    ShopItem(
      id: 's5',
      emoji: '🎬',
      category: '영화관',
      title: '영화 할인권 3,000원',
      price: 900,
    ),
    ShopItem(
      id: 's6',
      emoji: '💆',
      category: '웰니스',
      title: '마사지샵 10% 할인',
      price: 700,
    ),
    ShopItem(
      id: 's7',
      emoji: '💐',
      category: '클래스',
      title: '플라워 클래스 체험권',
      price: 1200,
    ),
    ShopItem(
      id: 's8',
      emoji: '🍸',
      category: '라운지',
      title: '라운지 카페 음료 1잔',
      price: 600,
    ),
    ShopItem(
      id: 's9',
      emoji: '🌳',
      category: 'ESG · 환경',
      title: '나무 한 그루 기부권',
      price: 400,
      esg: true,
    ),
    ShopItem(
      id: 's10',
      emoji: '♻️',
      category: 'ESG · 환경',
      title: '리필스테이션 할인권',
      price: 250,
      esg: true,
    ),
    ShopItem(
      id: 's11',
      emoji: '🤝',
      category: 'ESG · 사회',
      title: '지역 봉사 응원 배지',
      price: 180,
      esg: true,
    ),
  ];

  static const jobs = [
    '항공승무원',
    '호텔리어',
    '간호사',
    '카페 직원',
    '콜센터 상담사',
    '백화점 직원',
    '은행 창구직원',
    '미용사',
    '바텐더',
    '리셉셔니스트',
    '웨딩플래너',
    '기타 서비스직',
  ];

  static const quotes = [
    ('오늘 하루도 충분히 잘 해냈어요. 스스로에게 다정해지세요.', '마음 × WingStar'),
    ('느리게 흐르는 하루도 앞으로 나아가는 하루입니다.', '마음 × WingStar'),
    ('작은 걸음이 모여 긴 비행이 됩니다.', 'WingStar'),
    ('숨을 크게 들이쉬어 보세요. 지금 이 순간, 당신은 안전합니다.', '마음 × WingStar'),
  ];

  static const membershipPlans = [
    MembershipPlan(
      tier: MembershipTier.premium,
      title: 'Premium',
      priceLabel: '₩4,900',
      period: '월',
      perks: [
        'AI 행동패턴 분석',
        '맞춤 습관 추천 3개/주',
        '주간 마음 리포트 상세',
        '광고 제거 · 스트릭 보호 1회',
        'ESG 임팩트 주간 요약',
      ],
    ),
    MembershipPlan(
      tier: MembershipTier.membership,
      title: 'Membership+',
      priceLabel: '₩9,900',
      period: '월',
      perks: [
        'Premium 전체 포함',
        '세밀한 자기개발 성장 플랜',
        '번아웃 위험도 · 코칭 대화',
        '맞춤 습관 무제한 · 미션 자동 연동',
        'ESG 임팩트 딥 리포트 · 기부 매칭',
      ],
    ),
  ];

  bool get isPremium =>
      membership == MembershipTier.premium ||
      membership == MembershipTier.membership;
  bool get isMembershipPlus => membership == MembershipTier.membership;

  String get membershipLabel => switch (membership) {
    MembershipTier.free => 'Free',
    MembershipTier.premium => 'Premium',
    MembershipTier.membership => 'Membership+',
  };

  CabinClass get cabin {
    if (isMembershipPlus || xp >= 2000) return CabinClass.first;
    if (isPremium || xp >= 1200) return CabinClass.business;
    if (xp >= 600) return CabinClass.premiumEconomy;
    return CabinClass.economy;
  }

  String get cabinLabel => switch (cabin) {
    CabinClass.economy => 'Economy',
    CabinClass.premiumEconomy => 'Premium Economy',
    CabinClass.business => 'Business',
    CabinClass.first => 'First Class',
  };

  double get stepProgress => (steps / stepGoal).clamp(0, 1);
  int get calories => (steps * 0.04).round();
  double get distanceKm =>
      (_previousDistanceMeters + locationEngine.distanceMeters) / 1000;
  int get heartRate => 68 + (walking ? 18 : 4);
  int get wscKrwValue => wsc * RewardRules.coinWorthKrw;
  int get stepsToNextCoin => RewardRules.stepsPerCoin - pendingSteps;
  double get pendingProgress => pendingSteps / RewardRules.stepsPerCoin;
  int get remainingDailyCap =>
      (RewardRules.dailyHardCapSteps - rewardedStepsToday).clamp(
        0,
        RewardRules.dailyHardCapSteps,
      );

  /// ESG 종합 점수 0–100
  int get esgScore {
    final e = (carbonSavedKg * 12 + ecoActions * 8).clamp(0, 40);
    final s =
        (socialActions * 10 + smileCount * 3 + (todayMind != null ? 5 : 0))
            .clamp(0, 35);
    final g = (governanceChecks * 12 + (qualityScore * 15)).clamp(0, 25);
    return (e + s + g).round().clamp(0, 100);
  }

  int get envScore =>
      (carbonSavedKg * 18 + ecoActions * 10).round().clamp(0, 100);
  int get socialScore =>
      (socialActions * 14 + smileCount * 5).round().clamp(0, 100);
  int get govScore =>
      (governanceChecks * 20 + qualityScore * 40).round().clamp(0, 100);

  int get mindCalmScore {
    if (mindEntries.isEmpty) return 62;
    final map = {
      Emotion.great: 5,
      Emotion.good: 4,
      Emotion.okay: 3,
      Emotion.hard: 2,
      Emotion.exhausted: 1,
    };
    final avg =
        mindEntries
            .take(7)
            .map((e) => map[e.emotion]!)
            .reduce((a, b) => a + b) /
        mindEntries.take(7).length;
    return ((avg / 5) * 100).round().clamp(40, 98);
  }

  (String, String) get todayQuote => quotes[DateTime.now().day % quotes.length];

  /// 주간 라벨 (월~일 기준, 오늘이 마지막)
  List<String> get weekLabels {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun
    return List.generate(7, (i) {
      final idx = (today - 7 + i) % 7;
      return days[idx < 0 ? idx + 7 : idx];
    });
  }

  /// 주간 걸음 (마지막 = 오늘)
  List<double> get weeklyStepsSeries {
    final base = [
      4200.0,
      6100.0,
      3800.0,
      7200.0,
      5100.0,
      6400.0,
      steps.toDouble(),
    ];
    return base;
  }

  /// 주간 감정 1–5 (기록 없으면 샘플)
  List<double> get weeklyMoodSeries {
    final map = {
      Emotion.great: 5.0,
      Emotion.good: 4.0,
      Emotion.okay: 3.0,
      Emotion.hard: 2.0,
      Emotion.exhausted: 1.0,
    };
    final sample = [3.0, 4.0, 2.5, 4.0, 5.0, 3.5, 4.0];
    if (mindEntries.isEmpty) return sample;
    final out = List<double>.from(sample);
    for (final e in mindEntries.take(7)) {
      final daysAgo = DateUtils.dateOnly(
        DateTime.now(),
      ).difference(DateUtils.dateOnly(e.date)).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        out[6 - daysAgo] = map[e.emotion]!;
      }
    }
    return out;
  }

  /// 주간 적립 코인
  List<double> get weeklyCoinSeries {
    final earnedToday = ledger
        .where((e) => e.amount > 0)
        .fold<int>(0, (a, e) => a + e.amount);
    return [12, 18, 8, 22, 15, 20, earnedToday.clamp(0, 40).toDouble()];
  }

  /// 주간 ESG 종합
  List<double> get weeklyEsgSeries {
    final today = esgScore.toDouble();
    return [52, 55, 58, 61, 64, 68, today];
  }

  /// 주간 스트레스 (낮을수록 좋음)
  List<double> get weeklyStressSeries => [
    48,
    52,
    45,
    40,
    44,
    38,
    stress.toDouble(),
  ];

  /// 월간 걸음 (최근 28일 샘플, 마지막=오늘)
  List<double> get monthlyStepsSeries {
    final rnd = [for (var i = 0; i < 27; i++) 2500.0 + ((i * 137) % 5500)];
    return [...rnd, steps.toDouble()];
  }

  List<String> get monthDayLabels {
    final now = DateTime.now();
    return List.generate(28, (i) {
      final d = now.subtract(Duration(days: 27 - i));
      return '${d.day}';
    });
  }

  int get weeklyStepsTotal =>
      weeklyStepsSeries.fold<double>(0, (a, b) => a + b).round();
  double get weeklyStepsAvg => weeklyStepsTotal / 7;
  int get weeklyCoinsEarned =>
      weeklyCoinSeries.fold<double>(0, (a, b) => a + b).round();
  double get weeklyMoodAvg =>
      weeklyMoodSeries.fold<double>(0, (a, b) => a + b) /
      weeklyMoodSeries.length;

  MindEntry? get todayMind {
    final key = DateUtils.dateOnly(DateTime.now());
    for (final e in mindEntries) {
      if (DateUtils.dateOnly(e.date) == key) return e;
    }
    return null;
  }

  void showToast(String msg) {
    toast = msg;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      toast = null;
      notifyListeners();
    });
  }

  void completeBoarding(String n, String j) {
    name = n.trim().isEmpty ? '승객' : n.trim();
    job = j;
    onboarded = true;
    showToast('탑승 완료 · First Class Lounge에 오신 걸 환영해요');
    notifyListeners();
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void checkAttendance() {
    if (streak > 0 && _attendedToday) {
      showToast('오늘은 이미 출석했어요');
      return;
    }
    _attendedToday = true;
    streak += 1;
    _serverCredit(10, '출석 체크');
    xp += 15;
    showToast('출석 완료 +10 코인');
  }

  bool _attendedToday = false;

  /// Latest native engines drive the original walking UI.
  Future<void> syncOrWalk() async {
    if (syncing || _disposed) return;
    syncing = true;
    notifyListeners();
    try {
      if (walking) {
        walking = false;
        _walkClock.stop();
        _walkTimer?.cancel();
        await Future.wait([stepEngine.stop(), locationEngine.stop()]);
        if (!_disposed) {
          lastSettleNote = '걷기 기록 완료 · 보상 서버 미연결';
          showToast('걷기 기록을 마쳤어요');
        }
      } else {
        _previousDistanceMeters += locationEngine.distanceMeters;
        locationEngine.distanceMeters = 0;
        _accountedSteps = 0;
        testSteps = 0;
        walking = true;
        _walkClock.reset();
        _walkClock.start();
        await stepEngine.start();
        if (_disposed) return;
        if (recordLocation) await locationEngine.start();
        if (_disposed) return;
        _walkTimer = Timer.periodic(
          const Duration(seconds: 1),
          (_) => notifyListeners(),
        );
        lastSettleNote = isTestSession
            ? 'PC 테스트 · 보상 제외'
            : '센서 측정 중 · 보상 서버 미연결';
      }
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  void saveMind(Emotion emotion, String body, List<String> tags) {
    final today = DateUtils.dateOnly(DateTime.now());
    mindEntries.removeWhere((e) => DateUtils.dateOnly(e.date) == today);
    mindEntries.insert(
      0,
      MindEntry(date: DateTime.now(), emotion: emotion, body: body, tags: tags),
    );
    _bumpMission('m2', 1);
    stress = max(15, stress - 6);
    wingiMessage = isPremium
        ? '기록이 저장됐어요. Premium AI로 행동패턴을 더 깊게 볼 수 있어요.'
        : '감정 기록을 확인했어요. AI 맞춤 분석은 Premium에서 이용할 수 있어요.';
    showToast('감정 기록이 저장됐어요');
    notifyListeners();
  }

  void saveJournal(String title, String content) {
    if (content.trim().isEmpty) {
      showToast('내용을 적어주세요');
      return;
    }
    journals.insert(
      0,
      JournalEntry(
        id: 'j${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim().isEmpty ? '오늘의 마음' : title.trim(),
        content: content.trim(),
        date: DateTime.now(),
      ),
    );
    journalCount += 1;
    stress = max(12, stress - 4);
    showToast('마음 일기가 저장됐어요');
    notifyListeners();
  }

  void completeBreathing() {
    _bumpMission('m4', 1);
    breathingSessions += 1;
    stress = max(10, stress - 8);
    showToast('심호흡 완료 · 미션 진행!');
    notifyListeners();
  }

  void completeSmile() {
    smileCount += 1;
    socialActions += 1;
    _bumpMission('m7', 1);
    stress = max(12, stress - 5);
    wingiMessage = '미소가 기록됐어요. 작은 표정이 하루의 기분을 바꿔줘요 😊';
    showToast('미소 연습 완료 +ESG 사회 점수');
    notifyListeners();
  }

  void markGovernanceReviewed() {
    governanceChecks += 1;
    _bumpMission('m8', 1);
    showToast('보상 정책 확인 · Governance +');
    notifyListeners();
  }

  void claimMission(String id) {
    final m = missions.firstWhere((e) => e.id == id);
    if (!m.ready) return;
    m.claimed = true;
    _serverCredit(m.rewardWsc, '미션 · ${m.title}');
    xp += m.rewardWsc;
    if (m.esgPillar == EsgPillar.environment) ecoActions += 1;
    if (m.esgPillar == EsgPillar.social) socialActions += 1;
    if (m.esgPillar == EsgPillar.governance) governanceChecks += 1;
    showToast('미션 완료 +${m.rewardWsc} 코인');
    notifyListeners();
  }

  void cheerFriend(String friendName) {
    _bumpMission('m5', 1);
    socialActions += 1;
    showToast('$friendName에게 응원을 보냈어요');
    notifyListeners();
  }

  void buyItem(ShopItem item) {
    showToast('상점 교환 준비 중이에요. 코인은 차감되지 않습니다.');
  }

  void subscribe(MembershipTier tier) {
    // A provider callback or a button press is not proof of payment.
    showToast('유료 구독은 출시 준비 중이에요. 현재 결제되지 않습니다.');
  }

  /// 유료: AI 행동패턴 분석 + 맞춤 습관 추천
  Future<bool> runAiBehaviorAnalysis() async {
    if (!isPremium) {
      showToast('AI 행동패턴 분석은 Premium 이상에서 이용할 수 있어요');
      return false;
    }
    analyzingAi = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    behaviorInsights = [
      BehaviorInsight(
        title: '활동 리듬',
        detail: steps >= stepGoal * 0.5
            ? '오전에 걸음이 몰려 있어요. 저녁 짧은 산책으로 균형을 맞춰보세요.'
            : '걸음이 목표의 절반 미만이에요. 출퇴근 구간을 도보로 바꿔볼까요?',
        score: (stepProgress * 100).round(),
      ),
      BehaviorInsight(
        title: '감정·스트레스',
        detail: stress > 50
            ? '스트레스가 높아요. 심호흡·미소 미션을 우선 추천해요.'
            : '감정 기록이 안정권이에요. 지금 루틴을 유지하세요.',
        score: (100 - stress).clamp(20, 95),
      ),
      BehaviorInsight(
        title: 'ESG 실천',
        detail:
            '환경 $envScore · 사회 $socialScore · 거버넌스 $govScore. '
            '에코 워킹과 응원으로 임팩트를 키울 수 있어요.',
        score: esgScore,
      ),
    ];

    habitRecommendations = [
      HabitRecommendation(
        id: 'h1',
        title: '점심 후 10분 에코 워킹',
        reason: '걸음·탄소 저감을 동시에 올리는 패턴이에요.',
        esgPillar: EsgPillar.environment,
        durationMin: 10,
      ),
      HabitRecommendation(
        id: 'h2',
        title: '감정 한 줄 + 미소 10초',
        reason: '마인드 기록과 사회성 점수가 함께 올라가요.',
        esgPillar: EsgPillar.social,
        durationMin: 3,
      ),
      HabitRecommendation(
        id: 'h3',
        title: '취침 전 1분 심호흡',
        reason: '스트레스 $stress 구간에서 회복 루틴이 효과적이에요.',
        esgPillar: EsgPillar.social,
        durationMin: 1,
      ),
    ];

    weeklyDeepReport =
        '이번 주 마음 지수 $mindCalmScore점 · ESG $esgScore점. '
        '걸음 ${NumberFormat('#,###').format(steps)}, 일기 $journalCount회, 호흡 $breathingSessions회. '
        '추천: 에코 워킹과 감정 기록을 같은 날 묶어 Care Loop를 닫으세요.';

    if (isMembershipPlus) {
      growthPlan =
          '【Membership+ 성장 플랜】\n'
          '1주차: 출석·에코 워킹으로 루틴 고정\n'
          '2주차: 감정 태그 패턴 정리 + 미소 미션\n'
          '3주차: 맞춤 습관 3개를 미션에 고정\n'
          '4주차: ESG 기부·봉사 배지로 임팩트 확장\n'
          '번아웃 밴드: ${stress > 60 ? '주의' : '안정'} · 의료 진단이 아닌 라이프스타일 가이드입니다.';
    }

    analyzingAi = false;
    wingiMessage = '행동패턴 분석을 마쳤어요. 맞춤 습관을 확인해보세요.';
    showToast('AI 분석 완료');
    notifyListeners();
    return true;
  }

  void acceptHabit(String id) {
    if (!isPremium) {
      showToast('맞춤 습관은 Premium 기능이에요');
      return;
    }
    habitRecommendations = habitRecommendations
        .map((h) => h.id == id ? h.copyWith(accepted: true) : h)
        .toList();
    showToast('습관이 오늘의 포커스에 추가됐어요');
    notifyListeners();
  }

  void _bumpMission(String id, int progress) {
    missions = missions
        .map(
          (m) => m.id == id
              ? m.copyWith(progress: progress.clamp(0, m.target))
              : m,
        )
        .toList();
  }

  /// 코인 지급은 서버 경로만. UI에서 wsc++ 금지.
  void _serverCredit(int amount, String title, {String? note}) {
    wsc += amount;
    ledger.insert(
      0,
      LedgerItem(
        title: title,
        amount: amount,
        at: DateFormat('HH:mm').format(DateTime.now()),
        note: note,
      ),
    );
  }
}

class DateUtils {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
