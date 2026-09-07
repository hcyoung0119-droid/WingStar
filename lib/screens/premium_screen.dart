import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버십'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SkyBackground(
        dark: store.darkMode,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 플랜 · ${store.membershipLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '유료 멤버십은 출시 준비 중입니다. '
                    '상점·미션·걷기는 Free에서도 그대로 이용할 수 있습니다.',
                    style: TextStyle(color: WSColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final plan in AppStore.membershipPlans) ...[
              _PlanCard(
                plan: plan,
                active: store.membership == plan.tier,
                onSubscribe: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('${plan.title} · 월 ${plan.priceLabel}'),
                    content: const Text(
                      '매월 이용하는 구독 상품입니다. 현재 판매 준비 중이라 '
                      '결제와 자동 갱신이 시작되지 않습니다.\n\n'
                      '출시 후 결제 전에 첫 결제일, 갱신일, 해지·환불 조건을 안내해 드립니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            const Text(
              '예정된 멤버십 혜택입니다. 유료 구독은 아직 판매하지 않습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: WSColors.muted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.active,
    required this.onSubscribe,
  });

  final MembershipPlan plan;
  final bool active;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final highlight = plan.tier == MembershipTier.membership;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: highlight
            ? const LinearGradient(
                colors: [Color(0xFF6EC6FF), Color(0xFFAEE1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : WSColors.card,
        border: Border.all(
          color: active
              ? WSColors.coin
              : (highlight ? Colors.transparent : WSColors.border),
          width: active ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: WSColors.primary.withValues(alpha: highlight ? 0.22 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: highlight ? Colors.white : WSColors.text,
                  ),
                ),
              ),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WSColors.sunny,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '이용 중',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: plan.priceLabel,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: highlight ? Colors.white : WSColors.primaryDark,
                  ),
                ),
                TextSpan(
                  text: ' / ${plan.period}',
                  style: TextStyle(
                    color: highlight ? Colors.white70 : WSColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final p in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: highlight ? Colors.white : WSColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        color: highlight
                            ? Colors.white.withValues(alpha: 0.95)
                            : WSColors.text,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: highlight ? Colors.white : WSColors.primary,
                foregroundColor: highlight
                    ? WSColors.primaryDark
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: active ? null : onSubscribe,
              child: Text(active ? '현재 플랜' : '출시 준비 중 · 요금 안내'),
            ),
          ),
        ],
      ),
    );
  }
}
