import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/screens/green_walk_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return SkyBackground(
      dark: store.darkMode,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const GreenRewardPreview(),
            const SizedBox(height: 20),
            Text(
              '리워드 샵',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              '교환 준비 중 · 아직 실제 상품이 발급되지 않아요.',
              style: TextStyle(color: WSColors.muted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFE8B84A),
                    Color(0xFFF0C85C),
                    Color(0xFFE0A830),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8B84A).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 WINGSTAR COIN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    NumberFormat('#,###').format(store.wsc),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '체험용 코인 · 상품 교환 및 현금 환전 준비 중',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => store.setTab(2),
                    child: Text(
                      '적립 내역 보기 →',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ESG 그린포인트 샵',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height:
                  184 +
                  (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                        0,
                        28,
                      ) *
                      6,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final item in AppStore.shopCatalog.where((e) => e.esg))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 210,
                        child: GlassCard(
                          onTap: () => store.buyItem(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 30),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '교환 준비 중',
                                style: TextStyle(
                                  color: Color(0xFF2F9E44),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '리워드 쿠폰',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppStore.shopCatalog.where((e) => !e.esg).length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, i) {
                final item = AppStore.shopCatalog
                    .where((e) => !e.esg)
                    .elementAt(i);
                return GlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  onTap: () => store.buyItem(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: WSColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        NumberFormat('#,###').format(item.price),
                        style: const TextStyle(
                          color: Color(0xFFD4A017),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              '상품과 포인트 교환은 준비 중이며, 아직 쿠폰이 발급되지 않아요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: WSColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
