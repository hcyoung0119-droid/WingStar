import test from 'node:test';
import assert from 'node:assert/strict';
import { TossBilling, PLANS } from '../server/payments/toss.mjs';

const orderId = 'wingstar_order_123';
const payment = (overrides = {}) => ({ status: 'DONE', type: 'BILLING', card: {},
  mId: 'test_merchant', paymentKey: 'provider_payment_key', orderId, currency: 'KRW',
  totalAmount: 4900, approvedAt: '2026-09-07T12:00:00+09:00', ...overrides });
const input = { planId: 'premium', billingKey: 'billing_key', customerKey: 'customer_123', orderId };
function provider(fetchImpl) {
  return new TossBilling({ secretKey: 'test_sk_fixture', merchantId: 'test_merchant', mode: 'test', fetchImpl });
}

test('missing merchant setup and mixed test/live keys never contact the PG', async () => {
  let calls = 0;
  const fetchImpl = async () => { calls++; };
  await assert.rejects(new TossBilling({ fetchImpl }).charge(input), /NOT_CONFIGURED/);
  await assert.rejects(new TossBilling({ secretKey: 'test_sk_fixture', merchantId: 'merchant', mode: 'live', fetchImpl }).charge(input), /NOT_CONFIGURED/);
  assert.equal(calls, 0);
});

test('price is server-owned and retries reuse the order idempotency key', async () => {
  const requests = [];
  const api = provider(async (url, options) => {
    requests.push({ url, ...options }); return Response.json(payment());
  });
  await api.charge({ ...input, amount: 1 });
  await api.charge({ ...input, amount: 0 });
  assert.equal(JSON.parse(requests[0].body).amount, 4900);
  assert.equal(requests[0].headers['Idempotency-Key'], requests[1].headers['Idempotency-Key']);
  assert.equal(PLANS.membership.amount, 9900);
  await assert.rejects(api.charge({ ...input, planId: '__proto__' }), /INVALID_PLAN/);
});

test('mismatched, unpaid and wrong-merchant approvals cannot grant membership', async () => {
  for (const mismatch of [{ totalAmount: 1 }, { currency: 'USD' }, { status: 'READY' },
    { status: 'CANCELED' }, { orderId: 'another_order' }, { mId: 'another_merchant' },
    { type: 'NORMAL' }, { approvedAt: null }, { paymentKey: '' }]) {
    const api = provider(async () => Response.json(payment(mismatch)));
    await assert.rejects(api.charge(input), /VERIFICATION_FAILED/);
  }
});

test('provider decline and network uncertainty are distinguished without sensitive error bodies', async () => {
  const denied = provider(async () => Response.json({ message: 'private card details' }, { status: 400 }));
  await assert.rejects(denied.charge(input), /^PaymentError: PAYMENT_REJECTED$/);
  const timedOut = provider(async () => { throw new Error('private token'); });
  await assert.rejects(timedOut.charge(input), /^PaymentError: PAYMENT_OUTCOME_UNKNOWN$/);
});

test('billing key must belong to the authenticated server customer', async () => {
  const api = provider(async () => Response.json({ billingKey: 'private_key', customerKey: 'different_customer' }));
  await assert.rejects(api.issueBillingKey({ authKey: 'auth_123', customerKey: input.customerKey, idempotencyKey: 'issue_order_123' }), /VERIFICATION_FAILED/);
});

test('refund succeeds only on verified complete cancellation', async () => {
  const api = provider(async () => Response.json(payment({ status: 'CANCELED' })));
  assert.equal((await api.cancelPayment({ paymentKey: 'provider_payment_key', reason: '구매자 요청', cancellationId: 'refund_123' })).status, 'CANCELED');
  const wrong = provider(async () => Response.json(payment({ status: 'PARTIAL_CANCELED' })));
  await assert.rejects(wrong.cancelPayment({ paymentKey: 'provider_payment_key', reason: '구매자 요청', cancellationId: 'refund_123' }), /VERIFICATION_FAILED/);
});
