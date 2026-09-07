import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/screens/records_screen.dart';
import 'package:wingstar/screens/ranking_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

void main() {
  testWidgets(
    'Duplicate nickname candidates show distinct IDs and the correct relationship actions',
    (tester) async {
      final store = AppStore();
      store.openRankings();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: RankingPanel(store: store)),
        ),
      );
      await tester.pump();
      store.social.data = {
        'configured': true,
        'authenticated': true,
        'scope': 'friends',
        'me': {'id': 'WS-AAAAAAAAAA', 'nickname': '나', 'publicRanking': false},
        'search': {
          'query': '산책',
          'hasMore': false,
          'results': [
            {
              'user': {'id': 'WS-BBBBBBBBBB', 'nickname': '산책 친구'},
              'relationship': 'none',
            },
            {
              'user': {'id': 'WS-CCCCCCCCCC', 'nickname': '산책 친구'},
              'relationship': 'friend',
            },
            {
              'user': {'id': 'WS-DDDDDDDDDD', 'nickname': '산책 친구'},
              'relationship': 'incoming',
            },
          ],
        },
      };
      store.social.notifyListeners();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('닉네임으로 친구 찾기'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.textCapitalization, TextCapitalization.none);
      expect(input.textInputAction, TextInputAction.search);
      await tester.ensureVisible(find.text('WS-DDDDDDDDDD'));
      expect(find.text('산책 친구'), findsNWidgets(3));
      expect(find.text('WS-BBBBBBBBBB'), findsOneWidget);
      expect(find.text('WS-CCCCCCCCCC'), findsOneWidget);
      expect(find.text('친구 요청'), findsOneWidget);
      expect(find.text('친구'), findsOneWidget);
      expect(find.text('수락'), findsOneWidget);
      expect(tester.takeException(), isNull);
      store.social.data['search'] = {
        'user': {'id': 'WS-BBBBBBBBBB', 'nickname': '이전 검색 결과'},
        'relationship': 'none',
      };
      store.social.notifyListeners();
      await tester.pump();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      expect(find.text('이전 검색 결과'), findsOneWidget);
      expect(tester.takeException(), isNull);
      store.social.data['search'] = {'results': null};
      store.social.notifyListeners();
      await tester.pump();
      expect(find.text('검색 결과가 없어요. 다른 닉네임으로 찾아보세요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'Records keeps its original view and opens honest unconfigured ranking',
    (tester) async {
      final store = AppStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AnimatedBuilder(
              animation: store,
              builder: (_, _) => RecordsScreen(store: store),
            ),
          ),
        ),
      );
      expect(find.byType(RankingPanel), findsNothing);
      await tester.tap(find.text('랭킹'));
      await tester.pump();
      expect(find.byType(RankingPanel), findsOneWidget);
      expect(find.text('구글 로그인 연결 준비 중'), findsOneWidget);
      final login = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '구글 로그인 연결 준비 중'),
      );
      expect(login.onPressed, isNull);
      expect(find.text('닉네임으로 친구 찾기'), findsNothing);
      await tester.tap(find.text('기록'));
      await tester.pump();
      expect(find.byType(RankingPanel), findsNothing);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
