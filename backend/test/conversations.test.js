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
    body: JSON.stringify({ name: 'Test User', email, password: 'password123' }),
  });
  const body = await res.json();
  return body.token;
}

test('POST /api/conversations creates a conversation entry', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'conv1@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/conversations`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ source: 'voice', role: 'user', content: 'Salom' }),
    });
    assert.strictEqual(create.status, 201);
    const created = await create.json();
    assert.ok(created.id);

    const list = await fetch(`${base}/api/conversations`, { headers });
    assert.strictEqual(list.status, 200);
    const listBody = await list.json();
    assert.strictEqual(listBody.conversations.length, 1);
    assert.strictEqual(listBody.conversations[0].content, 'Salom');
    assert.strictEqual(listBody.conversations[0].source, 'voice');
  });
});

test('GET /api/conversations filters by source', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'conv2@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    await fetch(`${base}/api/conversations`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ source: 'mobile', role: 'user', content: 'Mobile xabar' }),
    });

    await fetch(`${base}/api/conversations`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ source: 'voice', role: 'user', content: 'Ovozli xabar' }),
    });

    const filtered = await fetch(`${base}/api/conversations?source=voice`, { headers });
    assert.strictEqual(filtered.status, 200);
    const body = await filtered.json();
    assert.strictEqual(body.conversations.length, 1);
    assert.strictEqual(body.conversations[0].source, 'voice');
    assert.strictEqual(body.conversations[0].content, 'Ovozli xabar');
  });
});

test('POST /api/tool-actions logs an action', async () => {
  await withServer(async (base) => {
    const token = await registerAndLogin(base, 'tool1@admai.uz');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/tool-actions`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        type: 'MAKE_CALL',
        payload: { phone: '+998901234567' },
        status: 'success',
      }),
    });
    assert.strictEqual(create.status, 201);
    const created = await create.json();
    assert.ok(created.id);

    const list = await fetch(`${base}/api/tool-actions`, { headers });
    assert.strictEqual(list.status, 200);
    const listBody = await list.json();
    assert.strictEqual(listBody.actions.length, 1);
    assert.strictEqual(listBody.actions[0].type, 'MAKE_CALL');
  });
});

test('conversations and tool-actions require authentication', async () => {
  await withServer(async (base) => {
    const convRes = await fetch(`${base}/api/conversations`);
    assert.strictEqual(convRes.status, 401);

    const toolRes = await fetch(`${base}/api/tool-actions`);
    assert.strictEqual(toolRes.status, 401);
  });
});

test('conversations and tool-actions cascade on user deletion', async () => {
  await withServer(async (base) => {
    const reg = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Delete Me', email: 'cascade@admai.uz', password: 'password123' }),
    });
    const { token, user } = await reg.json();
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    await fetch(`${base}/api/conversations`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ source: 'voice', role: 'user', content: 'Cascade test' }),
    });

    await fetch(`${base}/api/tool-actions`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ type: 'MAKE_CALL', payload: { phone: '+998901234567' }, status: 'success' }),
    });

    const del = await fetch(`${base}/api/users/me`, { method: 'DELETE', headers });
    assert.strictEqual(del.status, 204);

    const convCount = db.prepare(`SELECT COUNT(*) AS c FROM conversations WHERE user_id = ?`).get(user.id).c;
    assert.strictEqual(convCount, 0);

    const actionCount = db.prepare(`SELECT COUNT(*) AS c FROM tool_actions WHERE user_id = ?`).get(user.id).c;
    assert.strictEqual(actionCount, 0);

    const userRow = db.prepare(`SELECT id FROM users WHERE id = ?`).get(user.id);
    assert.strictEqual(userRow, undefined);
  });
});
