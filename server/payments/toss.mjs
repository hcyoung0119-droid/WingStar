// Server-only provider adapter. Not imported by Flutter or shipped in dist.
// No public checkout endpoint is enabled until merchant and account setup exists.
export const PLANS = Object.freeze({
  premium: Object.freeze({ title: 'WingStar Premium', amount: 4900, currency: 'KRW', interval: 'month' }),
  membership: Object.freeze({ title: 'WingStar Membership+', amount: 9900, currency: 'KRW', interval: 'month' }),
});

export class PaymentError extends Error {
  constructor(code) { super(code); this.name = 'PaymentError'; this.code = code; }
}

function required(value, max = 300) {
  if (typeof value !== 'string' || !value.trim() || value.length > max) {
    throw new PaymentError('INVALID_PAYMENT_INPUT');
  }
  return value;
}

export class TossBilling {
  constructor({ secretKey, merchantId, mode = 'disabled', fetchImpl = fetch } = {}) {
    this.secretKey = secretKey;
    this.merchantId = merchantId;
    this.mode = mode;
    this.fetch = fetchImpl;
  }

  async request(path, { method = 'POST', body, idempotencyKey } = {}) {
    const prefix = this.mode === 'test' ? 'test_sk_' : this.mode === 'live' ? 'live_sk_' : null;
    if (!prefix || !this.secretKey?.startsWith(prefix) || !this.merchantId) {
      throw new PaymentError('PAYMENTS_NOT_CONFIGURED');
    }
    const headers = {
      Authorization: `Basic ${btoa(`${this.secretKey}:`)}`,
      'Content-Type': 'application/json',
    };
    if (idempotencyKey) headers['Idempotency-Key'] = required(idempotencyKey, 300);
    let response;
    try {
      response = await this.fetch(`https://api.tosspayments.com${path}`, {
        method, headers, body: body ? JSON.stringify(body) : undefined,
        signal: AbortSignal.timeout(15000), redirect: 'error',
      });
    } catch {
      // Outcome may be unknown. Reconcile with the same persisted order before retrying.
      throw new PaymentError('PAYMENT_OUTCOME_UNKNOWN');
    }
    if (response.status === 204 && method === 'DELETE') return null;
    let data;
    try { data = await response.json(); } catch { throw new PaymentError('PAYMENT_OUTCOME_UNKNOWN'); }
    if (!response.ok) {
      // Never expose raw provider bodies (which may contain customer/payment data).
      throw new PaymentError(response.status >= 500 ? 'PAYMENT_OUTCOME_UNKNOWN' : 'PAYMENT_REJECTED');
    }
    return data;
  }

  async issueBillingKey({ authKey, customerKey, idempotencyKey }) {
    required(idempotencyKey);
    const data = await this.request('/v1/billing/authorizations/issue', {
      body: { authKey: required(authKey), customerKey: required(customerKey) }, idempotencyKey,
    });
    if (data.customerKey !== customerKey || typeof data.billingKey !== 'string' || !data.billingKey) {
      throw new PaymentError('PAYMENT_VERIFICATION_FAILED');
    }
    // Caller must encrypt at rest; never return this object to a browser.
    return { billingKey: data.billingKey, customerKey };
  }

  async charge({ planId, billingKey, customerKey, orderId }) {
    if (!Object.hasOwn(PLANS, planId)) throw new PaymentError('INVALID_PLAN');
    const plan = PLANS[planId];
    if (!/^[A-Za-z0-9_-]{6,64}$/.test(orderId ?? '')) throw new PaymentError('INVALID_ORDER');
    const data = await this.request(`/v1/billing/${encodeURIComponent(required(billingKey))}`, {
      body: { customerKey: required(customerKey), orderId, orderName: plan.title, amount: plan.amount },
      idempotencyKey: `charge-${orderId}`,
    });
    return this.verifyPayment(data, { planId, orderId });
  }

  verifyPayment(data, { planId, orderId }) {
    const plan = Object.hasOwn(PLANS, planId) ? PLANS[planId] : null;
    if (!plan || data.status !== 'DONE' || data.type !== 'BILLING' || !data.card ||
        data.orderId !== orderId || data.totalAmount !== plan.amount ||
        data.currency !== plan.currency || data.mId !== this.merchantId ||
        typeof data.paymentKey !== 'string' || !data.paymentKey ||
        !Number.isFinite(Date.parse(data.approvedAt))) {
      throw new PaymentError('PAYMENT_VERIFICATION_FAILED');
    }
    return { paymentKey: data.paymentKey, orderId, planId, amount: plan.amount, approvedAt: data.approvedAt };
  }

  async getPayment(paymentKey) {
    return this.request(`/v1/payments/${encodeURIComponent(required(paymentKey, 200))}`, { method: 'GET' });
  }

  async cancelPayment({ paymentKey, reason, cancellationId }) {
    required(cancellationId);
    const data = await this.request(`/v1/payments/${encodeURIComponent(required(paymentKey, 200))}/cancel`, {
      body: { cancelReason: required(reason, 200) }, idempotencyKey: `cancel-${cancellationId}`,
    });
    if (data.paymentKey !== paymentKey || data.mId !== this.merchantId || data.status !== 'CANCELED') {
      throw new PaymentError('PAYMENT_VERIFICATION_FAILED');
    }
    return { paymentKey, status: data.status };
  }

  async deleteBillingKey(billingKey) {
    return this.request(`/v1/billing/${encodeURIComponent(required(billingKey))}`, { method: 'DELETE' });
  }
}
