import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wingstar/screens/boarding_screen.dart';
import 'package:wingstar/screens/home_screen.dart';
import 'package:wingstar/screens/mind_screen.dart';
import 'package:wingstar/screens/my_screen.dart';
import 'package:wingstar/screens/records_screen.dart';
import 'package:wingstar/screens/shop_screen.dart';
import 'package:wingstar/screens/splash_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/app_viewport.dart';
import 'package:wingstar/widgets/breathing_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 모바일 네이티브에서만 세로 고정 (웹/데스크톱은 OS·브라우저가 담당)
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    } catch (_) {
      // Windows 등에서 미지원일 수 있음
    }
  }
  runApp(const WingStarApp());
}

class WingStarApp extends StatefulWidget {
  const WingStarApp({super.key});

  @override
  State<WingStarApp> createState() => _WingStarAppState();
}

class _WingStarAppState extends State<WingStarApp> {
  final store = AppStore();
  bool splashDone = false;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => splashDone = true);
    });
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    store.dispose();
    super.dispose();
  }

  void _onStore() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WingStar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) =>
          AppViewport(child: child ?? const SizedBox.shrink()),
      home: splashDone ? RootShell(store: store) : const SplashScreen(),
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.store});
  final AppStore store;

  void _openBreathing(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BreathingSheet(onDone: store.completeBreathing),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!store.onboarded) {
      return Scaffold(
        body: Stack(
          children: [
            BoardingScreen(store: store),
            if (store.toast != null) _Toast(text: store.toast!),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: WSColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: store.tab,
            children: [
              HomeScreen(
                store: store,
                onOpenBreathing: () => _openBreathing(context),
                onOpenMind: () => store.setTab(1),
              ),
              MindScreen(
                store: store,
                onOpenBreathing: () => _openBreathing(context),
              ),
              RecordsScreen(store: store),
              ShopScreen(store: store),
              MyScreen(store: store),
            ],
          ),
          if (store.toast != null) _Toast(text: store.toast!),
        ],
      ),
      bottomNavigationBar: MindBottomBar(
        index: store.tab,
        onChanged: store.setTab,
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 96,
      child: Material(
        color: WSColors.navy,
        borderRadius: BorderRadius.circular(999),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
