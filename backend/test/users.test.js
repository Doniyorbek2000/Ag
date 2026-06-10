const test = require('node:test');
const assert = require('node:assert');
const { freshTestEnv } = require('./helpers/setup');

freshTestEnv();
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
    body: JSON.stringify({ name: 'Usage User', email, password: 'password123' }),
  });
  const body = await res.json();
  return body.token;
}

test('usage starts at zero and increments, respecting the free-plan limit', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'usage1@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const initial = await fetch(`${base}/api/users/me/usage`, { headers });
    assert.strictEqual(initial.status, 200);
    const initialBody = await initial.json();
    assert.strictEqual(initialBody.plan, 'free');
    assert.strictEqual(initialBody.used, 0);
    assert.strictEqual(initialBody.limit, 20);

    const inc = await fetch(`${base}/api/users/me/usage/increment`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ tokensIn: 10, tokensOut: 20 }),
    });
    assert.strictEqual(inc.status, 200);
    const incBody = await inc.json();
    assert.strictEqual(incBody.used, 1);

    const after = await fetch(`${base}/api/users/me/usage`, { headers });
    const afterBody = await after.json();
    assert.strictEqual(afterBody.used, 1);
    assert.strictEqual(afterBody.remaining, 19);
  });
});

test('PATCH /me updates the display name', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'rename@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const res = await fetch(`${base}/api/users/me`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ name: 'Yangi Ism' }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.user.name, 'Yangi Ism');

    const rejected = await fetch(`${base}/api/users/me`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ name: 'A' }),
    });
    assert.strictEqual(rejected.status, 400);
  });
});

test('support tickets can be created and listed for the current user', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'ticket@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/users/me/tickets`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ subject: 'Yordam kerak', message: 'Ilovada xatolik bor' }),
    });
    assert.strictEqual(create.status, 201);
    const created = await create.json();
    assert.ok(created.id);

    const list = await fetch(`${base}/api/users/me/tickets`, { headers });
    assert.strictEqual(list.status, 200);
    const listBody = await list.json();
    assert.strictEqual(listBody.tickets.length, 1);
    assert.strictEqual(listBody.tickets[0].subject, 'Yordam kerak');
  });
});

test('all /api/users routes require authentication', async () => {
  await withServer(async (base) => {
    const res = await fetch(`${base}/api/users/me/usage`);
    assert.strictEqual(res.status, 401);
  });
});

test('DELETE /me removes the account and cascades related data', async () => {
  await withServer(async (base) => {
    const reg = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Delete Me', email: 'delete-me@admai.uz', password: 'password123' }),
    });
    const { token, user } = await reg.json();
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    await fetch(`${base}/api/users/me/tickets`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ subject: 'Test', message: 'Test message' }),
    });

    const del = await fetch(`${base}/api/users/me`, { method: 'DELETE', headers });
    assert.strictEqual(del.status, 204);

    const me = await fetch(`${base}/api/auth/me`, { headers });
    assert.strictEqual(me.status, 404);

    const ticketCount = db.prepare(`SELECT COUNT(*) AS c FROM support_tickets WHERE user_id = ?`).get(user.id).c;
    assert.strictEqual(ticketCount, 0);

    const userRow = db.prepare(`SELECT id FROM users WHERE id = ?`).get(user.id);
    assert.strictEqual(userRow, undefined);
  });
});

test('DELETE /me requires authentication', async () => {
  await withServer(async (base) => {
    const res = await fetch(`${base}/api/users/me`, { method: 'DELETE' });
    assert.strictEqual(res.status, 401);
  });
});
