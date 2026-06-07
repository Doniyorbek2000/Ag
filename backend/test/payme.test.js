const test = require('node:test');
const assert = require('node:assert');

const payme = require('../src/services/payme');

function withEnv(vars, fn) {
  const previous = {};
  for (const key of Object.keys(vars)) {
    previous[key] = process.env[key];
    process.env[key] = vars[key];
  }
  try {
    return fn();
  } finally {
    for (const key of Object.keys(vars)) {
      if (previous[key] === undefined) delete process.env[key];
      else process.env[key] = previous[key];
    }
  }
}

function basicAuth(login, password) {
  return `Basic ${Buffer.from(`${login}:${password}`).toString('base64')}`;
}

test('isConfigured is false unless merchant id and key are both set', () => {
  withEnv({ PAYME_MERCHANT_ID: '', PAYME_KEY: '' }, () => {
    assert.strictEqual(payme.isConfigured(), false);
  });
  withEnv({ PAYME_MERCHANT_ID: 'm1', PAYME_KEY: 'secretkey' }, () => {
    assert.strictEqual(payme.isConfigured(), true);
  });
});

test('buildCheckoutUrl base64-encodes merchant id, order id and amount', () => {
  withEnv({ PAYME_MERCHANT_ID: 'merchant-1', PAYME_KEY: 'secretkey' }, () => {
    const url = payme.buildCheckoutUrl({ orderId: 'order-1', amountTiyin: 2990000, returnUrl: 'https://app/back' });
    assert.match(url, /^https:\/\/checkout\.paycom\.uz\//);

    const encoded = url.split('/').pop();
    const decoded = Buffer.from(encoded, 'base64').toString('utf8');
    assert.strictEqual(decoded, 'm=merchant-1;ac.order_id=order-1;a=2990000;c=https://app/back');
  });
});

test('verifyAuth accepts the configured Paycom:<key> Basic credentials and rejects everything else', () => {
  withEnv({ PAYME_KEY: 'supersecret' }, () => {
    assert.strictEqual(payme.verifyAuth(basicAuth('Paycom', 'supersecret')), true);
    assert.strictEqual(payme.verifyAuth(basicAuth('Paycom', 'wrongkey')), false);
    assert.strictEqual(payme.verifyAuth(basicAuth('SomeoneElse', 'supersecret')), false);
    assert.strictEqual(payme.verifyAuth('Bearer sometoken'), false);
    assert.strictEqual(payme.verifyAuth(undefined), false);
  });
});

test('verifyAuth returns false when no key is configured', () => {
  withEnv({ PAYME_KEY: '' }, () => {
    assert.strictEqual(payme.verifyAuth(basicAuth('Paycom', '')), false);
  });
});

test('rpcError and rpcResult build well-formed JSON-RPC 2.0 envelopes', () => {
  const err = payme.rpcError(7, payme.ERROR.ORDER_NOT_FOUND, 'Order not found');
  assert.deepStrictEqual(err, {
    jsonrpc: '2.0',
    id: 7,
    error: { code: payme.ERROR.ORDER_NOT_FOUND, message: { ru: 'Order not found', uz: 'Order not found', en: 'Order not found' } },
  });

  const ok = payme.rpcResult(7, { allow: true });
  assert.deepStrictEqual(ok, { jsonrpc: '2.0', id: 7, result: { allow: true } });
});
