import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/screens/records_screen.dart';
import 'package:wingstar/screens/ranking_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

void main() {
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
      expect(find.text('아이디로 친구 찾기'), findsNothing);
      await tester.tap(find.text('기록'));
      await tester.pump();
      expect(find.byType(RankingPanel), findsNothing);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
