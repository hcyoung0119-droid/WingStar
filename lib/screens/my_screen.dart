import 'package:flutter/foundation.dart';
import '../widgets/app_sharing_card.dart';
import 'package:flutter/material.dart';
import 'package:wingstar/screens/ai_coach_screen.dart';
import 'package:wingstar/screens/esg_screen.dart';
import 'package:wingstar/screens/premium_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key, required this.store});
  final AppStore store;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SkyBackground(
      dark: store.darkMode,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              '마이',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: WSColors.primary,
                    child: Text(
                      store.name.isEmpty ? 'W' : store.name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${store.job} · ${store.cabinLabel} · ${store.membershipLabel}',
                          style: const TextStyle(color: WSColors.muted),
                        ),
                        Text(
                          '윙코인 ${store.wsc}',
                          style: const TextStyle(
                            color: WSColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () => _push(context, PremiumScreen(store: store)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Premium / Membership+',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        store.membershipLabel,
                        style: const TextStyle(
                          color: WSColors.coin,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'AI 행동패턴 · 맞춤 습관 · 세밀한 자기개발 구독',
                    style: TextStyle(color: WSColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () => _push(context, AiCoachScreen(store: store)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 코칭 (유료)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '행동패턴 분석과 맞춤 습관 추천으로 이동',
                    style: TextStyle(color: WSColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () => _push(context, EsgScreen(store: store)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESG 임팩트',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '종합 ${store.esgScore}점 · E ${store.envScore} · S ${store.socialScore} · G ${store.govScore}',
                    style: const TextStyle(color: WSColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '다크 모드',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('야간 근무자를 위한 야간 라운지'),
                value: store.darkMode,
                onChanged: (_) => store.toggleDarkMode(),
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 승무원 윙이',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(store.wingiMessage, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '보상 시스템',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text('걷기와 마음 돌봄, 환경 실천을 꾸준히 기록해 보세요.'),
                  const SizedBox(height: 6),
                  const Text(
                    '현재 코인은 체험용이며 상품 교환은 준비 중입니다.',
                    style: TextStyle(color: WSColors.muted),
                  ),
                ],
              ),
            ),
            if (kIsWeb) ...[const SizedBox(height: 20), const AppSharingCard()],
          ],
        ),
      ),
    );
  }
}
