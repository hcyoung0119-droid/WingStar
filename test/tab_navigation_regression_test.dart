import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/main.dart';
import 'package:wingstar/screens/my_screen.dart';
import 'package:wingstar/screens/ranking_screen.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/services/social_store.dart';

void main() {
  for (final startAtRanking in [true, false]) {
    testWidgets(
      'Ranking entry (direct: $startAtRanking) with web loading updates keeps navigation responsive',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var busy = false;
        final social = SocialStore(
          readSnapshot: () => jsonEncode({
            'configured': true,
            'authenticated': true,
            'busy': busy,
            'me': {
              'id': 'WS-AAAAAAAAAA',
              'nickname': '개발자',
              'publicRanking': false,
            },
            'friends': [],
            'incoming': [],
            'outgoing': [],
            'ranking': [],
          }),
          performAction: (_, _) async {
            busy = true;
            await Future<void>.value();
            busy = false;
            return '{"ok":true}';
          },
        );
        final store = AppStore(social: social)..onboarded = true;
        if (startAtRanking) {
          store.openRankings();
        } else {
          store.setTab(4);
        }
        await tester.pumpWidget(WingStarApp(store: store));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        if (!startAtRanking) {
          final enterRanking = find.text('친구 · 랭킹으로 이동');
          await tester.ensureVisible(enterRanking);
          await tester.tap(enterRanking);
          await tester.pump();
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
        final recordSections = find.byType(SegmentedButton<bool>);
        await tester.tap(
          find.descendant(of: recordSections, matching: find.text('기록')),
        );
        await tester.pump();
        expect(store.recordsRanking, isFalse);
        expect(find.byType(RankingPanel), findsNothing);
        await tester.tap(
          find.descendant(of: recordSections, matching: find.text('랭킹')),
        );
        await tester.pump();
        await tester.pump();
        expect(store.recordsRanking, isTrue);
        expect(find.byType(RankingPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
        final bottom = find.byType(MindBottomBar);
        await tester.tap(
          find.descendant(of: bottom, matching: find.text('마이')),
        );
        await tester.pump();
        expect(store.tab, 4);
        expect(tester.widget<MindBottomBar>(bottom).index, 4);
        expect(find.byType(MyScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Real app can switch from focused ranking search to My and other tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const WingStarApp());
      await tester.pump(const Duration(seconds: 2));
      final store = tester.widget<RootShell>(find.byType(RootShell)).store;
      store.onboarded = true;
      store.openRankings();
      await tester.pump();
      await tester.pump();
      store.social.data = {
        'configured': true,
        'authenticated': true,
        'scope': 'friends',
        'me': {
          'id': 'WS-AAAAAAAAAA',
          'nickname': '개발자',
          'publicRanking': false,
        },
        'friends': [],
        'incoming': [],
        'outgoing': [],
        'ranking': [],
      };
      store.social.notifyListeners();
      await tester.pump();
      final search = find.descendant(
        of: find.byType(RankingPanel),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(search);
      await tester.tap(search);
      await tester.enterText(search, '개발자');
      await tester.pump();
      final bottom = find.byType(MindBottomBar);
      await tester.tap(find.descendant(of: bottom, matching: find.text('마이')));
      await tester.pump();
      expect(store.tab, 4);
      expect(find.byType(MyScreen), findsOneWidget);
      expect(tester.widget<MindBottomBar>(bottom).index, 4);
      expect(tester.takeException(), isNull);
      for (final entry in [
        (0, '홈'),
        (1, '마인드'),
        (2, '기록'),
        (3, '샵'),
        (4, '마이'),
      ]) {
        await tester.tap(
          find.descendant(of: bottom, matching: find.text(entry.$2)),
        );
        await tester.pump();
        expect(store.tab, entry.$1);
        expect(tester.widget<MindBottomBar>(bottom).index, entry.$1);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
