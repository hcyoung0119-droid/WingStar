import 'package:flutter/foundation.dart';
import '../widgets/app_sharing_card.dart';
import '../widgets/profile_card.dart';
import 'profile_editor_screen.dart';
import 'ranking_screen.dart';
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
            ProfileCard(
              name: store.name,
              job: store.job,
              bio: store.profileBio,
              photo: store.profilePhoto,
              color: store.profileColor,
              badge: store.profileBadge,
              onEdit: () => _push(context, ProfileEditorScreen(store: store)),
              footer: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    '${store.cabinLabel} · ${store.membershipLabel}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '윙코인 ${store.wsc}',
                    style: const TextStyle(
                      color: Color(0xFFFFE3A3),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SocialIdentityCard(store: store),
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
            if (kIsWeb) ...[
              const SizedBox(height: 10),
              const GlassCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    '아이폰 권한 설정',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'GPS 기록·음악·음성 설정은 이 브라우저에 저장돼요. 이미 허용된 동작·위치 권한을 사용하며, 앱을 열 때 권한을 자동 요청하지 않아요.\n\n'
                        '위치 확인창이 계속 뜨면 Safari에서 WingStar 열기 → 페이지 메뉴 → 더 보기 → 이 웹사이트 설정 → 위치 → 허용으로 설정해 주세요.\n\n'
                        '동작 권한은 아이폰이 다시 확인하도록 초기화할 수 있어요. 이 경우 걷기 시작 때 한 번 허용해야 합니다. Safari·홈 화면 앱·카카오톡은 저장 공간과 권한이 다를 수 있으니 같은 방식으로 열어 주세요.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: WSColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const AppSharingCard(),
            ],
          ],
        ),
      ),
    );
  }
}
