import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/main.dart';
import 'package:wingstar/screens/activity_screens.dart';
import 'package:wingstar/screens/esg_screen.dart';
import 'package:wingstar/screens/green_walk_screen.dart';
import 'package:wingstar/state/app_store.dart' as model;
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/mind_calendar.dart';

void main() {
  testWidgets(
    'Calendar uses local month, weekday offsets and full dates for records',
    (tester) async {
      final store = model.AppStore();
      store.journals.clear();
      store.mindEntries.addAll([
        model.MindEntry(
          date: DateTime(2026, 1, 31),
          emotion: model.Emotion.good,
          body: '이번 달 기록',
        ),
        model.MindEntry(
          date: DateTime(2025, 12, 31),
          emotion: model.Emotion.hard,
          body: '다른 달 기록',
        ),
      ]);
      var now = DateTime(2026, 1, 31, 23, 59);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MindCalendar(store: store, now: () => now),
            ),
          ),
        ),
      );
      expect(find.text('2026년 1월'), findsOneWidget);
      expect(find.byKey(const ValueKey('mind-day-2026-1-31')), findsOneWidget);
      expect(find.textContaining('이번 달 기록'), findsOneWidget);
      expect(find.textContaining('다른 달 기록'), findsNothing);
      final grid = tester.widget<GridView>(
        find.byKey(const Key('mind-month-grid')),
      );
      expect(
        (grid.childrenDelegate as SliverChildBuilderDelegate).childCount,
        35,
      );
      // January starts on Thursday: four Sunday-first blank slots.
      expect(find.byKey(const ValueKey('mind-day-2026-1-0')), findsNothing);
      now = DateTime(2026, 2, 1);
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('2026년 2월'), findsOneWidget);
      expect(find.text('2월 1일 기록'), findsOneWidget);
      expect(find.byKey(const ValueKey('mind-day-2026-2-28')), findsOneWidget);
      expect(find.byKey(const ValueKey('mind-day-2026-2-29')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'Leap February has 29 days, month navigation exposes March 31, and today resets',
    (tester) async {
      final store = model.AppStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MindCalendar(
                store: store,
                now: () => DateTime(2028, 2, 29),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('mind-day-2028-2-29')), findsOneWidget);
      expect(find.byKey(const ValueKey('mind-day-2028-2-30')), findsNothing);
      await tester.tap(find.byTooltip('다음 달'));
      await tester.pump();
      expect(find.byKey(const ValueKey('mind-day-2028-3-31')), findsOneWidget);
      await tester.tap(find.text('오늘'));
      await tester.pump();
      expect(find.text('2월 29일 기록'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'Home opens each activity without starting it and mind shortcuts select their page',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = model.AppStore()..onboarded = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AnimatedBuilder(
            animation: store,
            builder: (_, _) => RootShell(store: store),
          ),
        ),
      );
      for (final destination in <(String, Type)>[
        ('home-walking', WalkingScreen),
        ('home-meditation', MeditationScreen),
        ('home-plogging', GreenWalkScreen),
        ('home-esg', EsgScreen),
      ]) {
        await tester.ensureVisible(find.byKey(Key(destination.$1)));
        await tester.tap(find.byKey(Key(destination.$1)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(destination.$2), findsOneWidget);
        expect(store.walking, false);
        expect(store.breathingSessions, 0);
        expect(store.ploggingSessions, 0);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      for (final section in <(String, model.MindSection, String)>[
        ('미소', model.MindSection.smile, '웃는 연습을 해볼까요?'),
        ('일기', model.MindSection.journal, '마음 일기'),
        ('감정', model.MindSection.emotion, '지금 기분이 어떠세요?'),
        ('캘린더', model.MindSection.calendar, '휴대폰 날짜 기준'),
      ]) {
        store.setTab(0);
        await tester.pump();
        await tester.ensureVisible(find.text(section.$1).first);
        await tester.tap(find.text(section.$1).first);
        await tester.pump();
        expect(store.tab, 1);
        expect(store.mindSection, section.$2);
        expect(find.text(section.$3), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  test(
    'Coin value is one won and plogging contributes without starting a walk',
    () {
      final store = model.AppStore()..wsc = 123;
      final eco = store.ecoActions;
      store.recordPlogging(3);
      expect(store.wscKrwValue, 123);
      expect(store.ploggingSessions, 1);
      expect(store.litterCollected, 3);
      expect(store.ecoActions, eco + 1);
      expect(store.walking, false);
      store.dispose();
    },
  );
}
