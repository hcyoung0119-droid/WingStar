import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wingstar/screens/ai_coach_screen.dart';
import 'package:wingstar/screens/premium_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/detail_charts.dart';
import 'package:wingstar/widgets/mind_calendar.dart';

class MindScreen extends StatefulWidget {
  const MindScreen({super.key, required this.store, this.onOpenBreathing});
  final AppStore store;
  final VoidCallback? onOpenBreathing;

  @override
  State<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends State<MindScreen> {
  Emotion? selected;
  final bodyCtrl = TextEditingController();
  final journalCtrl = TextEditingController();
  final journalTitleCtrl = TextEditingController();
  final tags = <String>{};

  static const options = [
    (Emotion.great, '😄', '최고예요'),
    (Emotion.good, '🙂', '좋아요'),
    (Emotion.okay, '😐', '그저 그래요'),
    (Emotion.hard, '😞', '힘들어요'),
    (Emotion.exhausted, '😢', '너무 지쳐요'),
  ];

  static const tagPool = ['손님응대', '야근', '동료', '휴식', '번아웃', '감사', '산책'];
  static const smileTips = [
    '입꼬리를 부드럽게 올려보세요',
    '눈가에 힘을 살짝 주며 웃어보세요',
    '10초간 미소를 유지해보세요',
  ];

  @override
  void dispose() {
    bodyCtrl.dispose();
    journalCtrl.dispose();
    journalTitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final mode = store.mindSection.index;
    return SkyBackground(
      dark: store.darkMode,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              '마인드',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Text(
              '감정 · 일기 · 미소 — 마음서비스의 돌봄과 WingStar 미션이 한곳에.',
              style: TextStyle(color: WSColors.muted),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in [
                    (0, '감정'),
                    (1, '일기'),
                    (2, '미소'),
                    (3, '캘린더'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.$2),
                        selected: mode == entry.$1,
                        onSelected: (_) => setState(
                          () => store.openMind(MindSection.values[entry.$1]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (mode == 0) ..._emotion(store),
            if (mode == 1) ..._journal(store),
            if (mode == 2) ..._smile(store),
            if (mode == 3) MindCalendar(store: store),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => store.isPremium
                        ? AiCoachScreen(store: store)
                        : PremiumScreen(store: store),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        store.isPremium
                            ? Icons.auto_awesome
                            : Icons.lock_outline,
                        size: 18,
                        color: WSColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        store.isPremium
                            ? 'AI 감정·행동 분석 (Premium)'
                            : 'AI 맞춤 분석 · 유료 잠금',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: WSColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    store.todayMind == null
                        ? '감정 일기를 남기면 AI가 패턴을 분석합니다. 상세 분석·습관 추천은 Premium입니다.'
                        : store.isPremium
                        ? store.wingiMessage
                        : '기본 응원은 Free · 행동패턴·맞춤 습관은 Premium에서.',
                    style: const TextStyle(color: WSColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            if (widget.onOpenBreathing != null) ...[
              const SizedBox(height: 10),
              GlassCard(
                onTap: widget.onOpenBreathing,
                child: const Row(
                  children: [
                    Text('🌬️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1분 심호흡',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '스트레스 완화 · 미션 연동',
                            style: TextStyle(
                              color: WSColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이번 주 마음 지수',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${store.mindCalmScore}점',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: WSColors.mind,
                    ),
                  ),
                  Text(
                    '감정 ${store.mindEntries.length} · 일기 ${store.journals.length} · 미소 ${store.smileCount} · 호흡 ${store.breathingSessions}',
                    style: const TextStyle(color: WSColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '주간 감정 흐름',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: WeeklyMoodMiniChart(store: store),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _emotion(AppStore store) {
    return [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '지금 기분이 어떠세요?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final o in options)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => selected = o.$1),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected == o.$1
                              ? WSColors.primarySoft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(o.$2, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              o.$3,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected == o.$1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected == o.$1
                                    ? WSColors.primaryDark
                                    : WSColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '오늘의 한 줄 (선택)',
                  filled: true,
                  fillColor: WSColors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final t in tagPool)
                    FilterChip(
                      label: Text(t),
                      selected: tags.contains(t),
                      onSelected: (v) =>
                          setState(() => v ? tags.add(t) : tags.remove(t)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: WSColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  store.saveMind(selected!, bodyCtrl.text, tags.toList());
                  bodyCtrl.clear();
                  setState(() {
                    selected = null;
                    tags.clear();
                  });
                },
                child: const Text('감정 기록 저장'),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _journal(AppStore store) {
    return [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마음 일기',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: journalTitleCtrl,
              decoration: InputDecoration(
                hintText: '제목 (선택)',
                filled: true,
                fillColor: WSColors.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: journalCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '오늘의 이야기를 적어보세요...',
                filled: true,
                fillColor: WSColors.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: () {
                store.saveJournal(journalTitleCtrl.text, journalCtrl.text);
                journalCtrl.clear();
                journalTitleCtrl.clear();
              },
              child: const Text('일기 저장'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      for (final j in store.journals.take(6))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        j.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      DateFormat('MM/dd').format(j.date),
                      style: const TextStyle(
                        color: WSColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  j.content,
                  style: const TextStyle(color: WSColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _smile(AppStore store) {
    return [
      GlassCard(
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF0B3),
              ),
              child: const Text('😊', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 14),
            const Text(
              '웃는 연습을 해볼까요?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              '작은 미소가 하루의 기분을 바꿔줘요',
              style: TextStyle(color: WSColors.muted),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < smileTips.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFFFE08A),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(smileTips[i])),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE8B84A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: store.completeSmile,
              child: const Text('미소 연습 완료'),
            ),
          ],
        ),
      ),
    ];
  }
}
