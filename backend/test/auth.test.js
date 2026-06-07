const test = require('node:test');
const assert = require('node:assert');
const { freshTestEnv } = require('./helpers/setup');

freshTestEnv();
const { createApp } = require('../src/app');

const app = createApp();

async function listen() {
  return new Promise((resolve) => {
    const server = app.listen(0, () => resolve(server));
  });
}

async function withServer(fn) {
  const server = await listen();
  const { port } = server.address();
  try {
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    server.close();
  }
}

test('register creates a user and returns a token', async () => {
  await withServer(async (base) => {
    const res = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test User', email: 'test1@admai.uz', password: 'password123' }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.ok(body.token);
    assert.strictEqual(body.user.email, 'test1@admai.uz');
    assert.strictEqual(body.user.role, 'user');
    assert.strictEqual(body.user.plan, 'free');
  });
});

test('register rejects duplicate email', async () => {
  await withServer(async (base) => {
    const payload = { name: 'Dup User', email: 'dup@admai.uz', password: 'password123' };
    const first = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    assert.strictEqual(first.status, 201);

    const second = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    assert.strictEqual(second.status, 409);
  });
});

test('register rejects invalid payloads', async () => {
  await withServer(async (base) => {
    const res = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'A', email: 'not-an-email', password: '123' }),
    });
    assert.strictEqual(res.status, 400);
  });
});

test('login succeeds with correct credentials and fails with wrong password', async () => {
  await withServer(async (base) => {
    await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Login User', email: 'login@admai.uz', password: 'correct-password' }),
    });

    const ok = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'login@admai.uz', password: 'correct-password' }),
    });
    assert.strictEqual(ok.status, 200);
    const okBody = await ok.json();
    assert.ok(okBody.token);

    const bad = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'login@admai.uz', password: 'wrong-password' }),
    });
    assert.strictEqual(bad.status, 401);
  });
});

test('GET /me requires a valid bearer token', async () => {
  await withServer(async (base) => {
    const noToken = await fetch(`${base}/api/auth/me`);
    assert.strictEqual(noToken.status, 401);

    const register = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Me User', email: 'me@admai.uz', password: 'password123' }),
    });
    const { token } = await register.json();

    const withToken = await fetch(`${base}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    assert.strictEqual(withToken.status, 200);
    const body = await withToken.json();
    assert.strictEqual(body.user.email, 'me@admai.uz');

    const badToken = await fetch(`${base}/api/auth/me`, {
      headers: { Authorization: 'Bearer not-a-real-token' },
    });
    assert.strictEqual(badToken.status, 401);
  });
});
