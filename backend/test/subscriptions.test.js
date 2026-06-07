const test = require('node:test');
const assert = require('node:assert');
const { freshTestEnv } = require('./helpers/setup');

freshTestEnv();
const { createApp } = require('../src/app');

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
    body: JSON.stringify({ name: 'Sub User', email, password: 'password123' }),
  });
  const body = await res.json();
  return body.token;
}

test('manual purchases activate a plan without Google Play verification', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'manual@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const res = await fetch(`${base}/api/subscriptions/purchase`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ plan: 'pro', provider: 'manual' }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.strictEqual(body.plan, 'pro');
    assert.ok(body.expiresAt);

    const me = await fetch(`${base}/api/auth/me`, { headers });
    const meBody = await me.json();
    assert.strictEqual(meBody.user.plan, 'pro');
  });
});

test('google_play purchases require purchaseToken and productId', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'gplay@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const res = await fetch(`${base}/api/subscriptions/purchase`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ plan: 'ultra', provider: 'google_play' }),
    });
    assert.strictEqual(res.status, 400);
  });
});

test('without GOOGLE_PLAY_SERVICE_ACCOUNT_KEY, google_play purchases with a token are trusted', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'gplay2@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const res = await fetch(`${base}/api/subscriptions/purchase`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        plan: 'vip',
        provider: 'google_play',
        purchaseToken: 'fake-token-for-test',
        productId: 'adm_ai_vip_monthly',
      }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.strictEqual(body.plan, 'vip');
  });
});

test('subscription history and cancellation work', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'cancel@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    await fetch(`${base}/api/subscriptions/purchase`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ plan: 'pro', provider: 'manual' }),
    });

    const history = await fetch(`${base}/api/subscriptions/me`, { headers });
    const historyBody = await history.json();
    assert.strictEqual(historyBody.subscriptions.length, 1);
    assert.strictEqual(historyBody.subscriptions[0].status, 'active');

    const cancel = await fetch(`${base}/api/subscriptions/cancel`, { method: 'POST', headers });
    assert.strictEqual(cancel.status, 200);

    const me = await fetch(`${base}/api/auth/me`, { headers });
    const meBody = await me.json();
    assert.strictEqual(meBody.user.plan, 'free');
  });
});
