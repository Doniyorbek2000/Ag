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

async function loginAsAdmin(base) {
  const res = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: process.env.ADMIN_BOOTSTRAP_EMAIL,
      password: process.env.ADMIN_BOOTSTRAP_PASSWORD,
    }),
  });
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  return body.token;
}

async function registerUser(base, email) {
  const res = await fetch(`${base}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Regular User', email, password: 'password123' }),
  });
  return res.json();
}

test('the bootstrap admin account exists and can log in with the admin role', async () => {
  await withServer(async (base) => {
    const token = await loginAsAdmin(base);
    const me = await fetch(`${base}/api/auth/me`, { headers: { Authorization: `Bearer ${token}` } });
    const body = await me.json();
    assert.strictEqual(body.user.role, 'admin');
  });
});

test('admin routes reject regular users and unauthenticated requests', async () => {
  await withServer(async (base) => {
    const noAuth = await fetch(`${base}/api/admin/stats`);
    assert.strictEqual(noAuth.status, 401);

    const regular = await registerUser(base, 'plain@admai.uz');
    const forbidden = await fetch(`${base}/api/admin/stats`, {
      headers: { Authorization: `Bearer ${regular.token}` },
    });
    assert.strictEqual(forbidden.status, 403);
  });
});

test('GET /admin/stats returns aggregate counts including the new user', async () => {
  await withServer(async (base) => {
    await registerUser(base, 'stats1@admai.uz');
    await registerUser(base, 'stats2@admai.uz');

    const token = await loginAsAdmin(base);
    const res = await fetch(`${base}/api/admin/stats`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(body.totalUsers >= 3); // 2 registered + bootstrap admin
    assert.ok(Array.isArray(body.planCounts));
  });
});

test('GET /admin/users supports search and PATCH updates plan/role/active', async () => {
  await withServer(async (base) => {
    const created = await registerUser(base, 'editme@admai.uz');
    const token = await loginAsAdmin(base);
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const list = await fetch(`${base}/api/admin/users?search=editme`, { headers });
    assert.strictEqual(list.status, 200);
    const listBody = await list.json();
    assert.strictEqual(listBody.users.length, 1);
    assert.strictEqual(listBody.users[0].email, 'editme@admai.uz');

    const patch = await fetch(`${base}/api/admin/users/${created.user.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ plan: 'ultra', isActive: false }),
    });
    assert.strictEqual(patch.status, 200);
    const patched = await patch.json();
    assert.strictEqual(patched.user.plan, 'ultra');
    assert.strictEqual(patched.user.isActive, false);
  });
});

test('admin can create a broadcast and it is listed afterwards', async () => {
  await withServer(async (base) => {
    const token = await loginAsAdmin(base);
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const create = await fetch(`${base}/api/admin/broadcasts`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ title: 'Yangilik', body: 'Yangi funksiyalar qo\'shildi', targetPlan: 'all' }),
    });
    assert.strictEqual(create.status, 201);

    const list = await fetch(`${base}/api/admin/broadcasts`, { headers });
    const listBody = await list.json();
    assert.ok(listBody.broadcasts.some((b) => b.title === 'Yangilik'));
  });
});
