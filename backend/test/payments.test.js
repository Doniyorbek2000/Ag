const test = require('node:test');
const assert = require('node:assert');
const crypto = require('crypto');
const { freshTestEnv } = require('./helpers/setup');

freshTestEnv();
process.env.CLICK_SERVICE_ID = '111';
process.env.CLICK_MERCHANT_ID = '222';
process.env.CLICK_SECRET_KEY = 'click-secret';
process.env.PAYME_MERCHANT_ID = 'merchant-1';
process.env.PAYME_KEY = 'payme-secret';

const { createApp } = require('../src/app');
const db = require('../src/db');

const app = createApp();

async function withServer(fn) {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  try {
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    server.close();
  }
}

async function registerAndLogin(base, email) {
  const res = await fetch(`${base}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Pay User', email, password: 'password123' }),
  });
  const body = await res.json();
  return body.token;
}

function clickSign({ clickTransId, merchantTransId, merchantPrepareId, amount, action, signTime }) {
  const parts = [clickTransId, '111', 'click-secret', merchantTransId];
  if (merchantPrepareId) parts.push(merchantPrepareId);
  parts.push(amount, action, signTime);
  return crypto.createHash('md5').update(parts.join('')).digest('hex');
}

function paymeAuthHeader() {
  return `Basic ${Buffer.from('Paycom:payme-secret').toString('base64')}`;
}

async function rpc(base, method, params, id = 1) {
  const res = await fetch(`${base}/api/payments/payme/webhook`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: paymeAuthHeader() },
    body: JSON.stringify({ jsonrpc: '2.0', id, method, params }),
  });
  return { status: res.status, body: await res.json() };
}

test('Click: create -> Prepare -> Complete activates the subscription', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'click@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/payments/click/create`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ plan: 'pro' }),
    });
    assert.strictEqual(create.status, 201);
    const { orderId, checkoutUrl } = await create.json();
    assert.match(checkoutUrl, /my\.click\.uz/);

    const signTime = '2026-01-01 10:00:00';

    // Prepare (action=0)
    const prepareSign = clickSign({ clickTransId: '900', merchantTransId: orderId, amount: '29900', action: 0, signTime });
    const prepareRes = await fetch(`${base}/api/payments/click/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        click_trans_id: '900',
        service_id: '111',
        merchant_trans_id: orderId,
        amount: '29900',
        action: '0',
        sign_time: signTime,
        sign_string: prepareSign,
        error: '0',
      }),
    });
    const prepareBody = await prepareRes.json();
    assert.strictEqual(prepareBody.error, 0);
    assert.strictEqual(prepareBody.merchant_prepare_id, orderId);

    // Complete (action=1)
    const completeSign = clickSign({
      clickTransId: '900', merchantTransId: orderId, merchantPrepareId: orderId, amount: '29900', action: 1, signTime,
    });
    const completeRes = await fetch(`${base}/api/payments/click/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        click_trans_id: '900',
        service_id: '111',
        merchant_trans_id: orderId,
        merchant_prepare_id: orderId,
        amount: '29900',
        action: '1',
        sign_time: signTime,
        sign_string: completeSign,
        error: '0',
      }),
    });
    const completeBody = await completeRes.json();
    assert.strictEqual(completeBody.error, 0);

    const me = await fetch(`${base}/api/auth/me`, { headers });
    const meBody = await me.json();
    assert.strictEqual(meBody.user.plan, 'pro');

    const payment = db.prepare('SELECT * FROM payments WHERE id = ?').get(orderId);
    assert.strictEqual(payment.status, 'completed');
  });
});

test('Click: webhook rejects an incorrect signature', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'click-badsign@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/payments/click/create`, {
      method: 'POST', headers, body: JSON.stringify({ plan: 'pro' }),
    });
    const { orderId } = await create.json();

    const res = await fetch(`${base}/api/payments/click/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        click_trans_id: '901',
        service_id: '111',
        merchant_trans_id: orderId,
        amount: '29900',
        action: '0',
        sign_time: '2026-01-01 10:00:00',
        sign_string: 'not-the-real-signature',
        error: '0',
      }),
    });
    const body = await res.json();
    assert.strictEqual(body.error, -1);
  });
});

test('Payme: full JSON-RPC lifecycle activates the subscription, then can be cancelled', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'payme@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/payments/payme/create`, {
      method: 'POST', headers, body: JSON.stringify({ plan: 'ultra' }),
    });
    assert.strictEqual(create.status, 201);
    const { orderId, checkoutUrl } = await create.json();
    assert.match(checkoutUrl, /checkout\.paycom\.uz/);

    const amount = 59900 * 100; // tiyin
    const account = { order_id: orderId };
    const txId = 'payme-tx-1';

    const check = await rpc(base, 'CheckPerformTransaction', { amount, account });
    assert.deepStrictEqual(check.body.result, { allow: true });

    const created = await rpc(base, 'CreateTransaction', { id: txId, time: Date.now(), amount, account });
    assert.strictEqual(created.body.result.state, 1);
    assert.strictEqual(created.body.result.transaction, txId);

    const performed = await rpc(base, 'PerformTransaction', { id: txId });
    assert.strictEqual(performed.body.result.state, 2);

    const me = await fetch(`${base}/api/auth/me`, { headers });
    const meBody = await me.json();
    assert.strictEqual(meBody.user.plan, 'ultra');

    const checked = await rpc(base, 'CheckTransaction', { id: txId });
    assert.strictEqual(checked.body.result.state, 2);

    const cancelled = await rpc(base, 'CancelTransaction', { id: txId, reason: 1 });
    assert.strictEqual(cancelled.body.result.state, -2);
  });
});

test('Payme: webhook rejects requests without valid Basic auth', async () => {
  await withServer(async (base) => {
    const res = await fetch(`${base}/api/payments/payme/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Basic d3Jvbmc6Y3JlZHM=' },
      body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'CheckPerformTransaction', params: {} }),
    });
    const body = await res.json();
    assert.strictEqual(body.error.code, -32504);
  });
});

test('Payments: checkout creation requires authentication and a known plan', async () => {
  await withServer(async (base) => {
    const unauthed = await fetch(`${base}/api/payments/click/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ plan: 'pro' }),
    });
    assert.strictEqual(unauthed.status, 401);

    const token = await registerAndLogin(base, 'badplan@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
    const badPlan = await fetch(`${base}/api/payments/click/create`, {
      method: 'POST', headers, body: JSON.stringify({ plan: 'free' }),
    });
    assert.strictEqual(badPlan.status, 400);
  });
});
