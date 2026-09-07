import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/state/app_store.dart';

void main() {
  test('A subscription click cannot grant paid access or reward XP', () {
    final store = AppStore();
    final xp = store.xp;
    store.subscribe(MembershipTier.membership);
    expect(store.membership, MembershipTier.free);
    expect(store.isPremium, false);
    expect(store.xp, xp);
    store.dispose();
  });
  test('Unconnected shop does not charge coins or issue fictitious coupons', () {
    final store = AppStore()..wsc = 10000;
    final ledgerCount = store.ledger.length;
    store.buyItem(AppStore.shopCatalog.first);
    expect(store.wsc, 10000);
    expect(store.coupons, isEmpty);
    expect(store.ledger.length, ledgerCount);
    store.dispose();
  });
}
