import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/main.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('NotoSansKR')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('Original boarding screen remains available', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WingStarApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('만나서 반가워요'), findsOneWidget);
    expect(find.text('계속하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Original home and all five tabs survive engine integration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore()..onboarded = true;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: boundary,
          child: RootShell(store: store),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('home-walking')), findsOneWidget);
    expect(find.byKey(const Key('home-meditation')), findsOneWidget);
    expect(find.byKey(const Key('home-plogging')), findsOneWidget);
    expect(find.byKey(const Key('home-esg')), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/upgraded-home.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    for (var tab = 1; tab < 5; tab++) {
      store.setTab(tab);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: RootShell(store: store),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
