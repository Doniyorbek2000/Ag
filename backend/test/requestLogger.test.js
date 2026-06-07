const test = require('node:test');
const assert = require('node:assert');

const { requestLogger, logRateLimitHit } = require('../src/middleware/requestLogger');

function fakeReq(overrides = {}) {
  return { method: 'GET', originalUrl: '/api/test', ip: '127.0.0.1', user: null, ...overrides };
}

function fakeRes() {
  const res = {
    statusCode: 200,
    _json: null,
    _finishCb: null,
    on(event, cb) { if (event === 'finish') this._finishCb = cb; },
    status(code) { this.statusCode = code; return this; },
    json(body) { this._json = body; return this; },
  };
  return res;
}

test('requestLogger captures the response status and emits a structured log line on finish', () => {
  const logs = [];
  const originalLog = console.log;
  console.log = (line) => logs.push(line);

  try {
    const req = fakeReq({ user: { id: 'u1' } });
    const res = fakeRes();
    requestLogger(req, res, () => {});

    res.statusCode = 201;
    res._finishCb();

    assert.strictEqual(logs.length, 1);
    const entry = JSON.parse(logs[0]);
    assert.strictEqual(entry.method, 'GET');
    assert.strictEqual(entry.path, '/api/test');
    assert.strictEqual(entry.status, 201);
    assert.strictEqual(entry.userId, 'u1');
    assert.strictEqual(entry.level, 'info');
    assert.ok(typeof entry.durationMs === 'number');
  } finally {
    console.log = originalLog;
  }
});

test('requestLogger marks 4xx as warn and 5xx as error', () => {
  const logs = [];
  const originalLog = console.log;
  console.log = (line) => logs.push(JSON.parse(line));

  try {
    for (const status of [404, 500]) {
      const req = fakeReq();
      const res = fakeRes();
      requestLogger(req, res, () => {});
      res.statusCode = status;
      res._finishCb();
    }

    assert.strictEqual(logs[0].level, 'warn');
    assert.strictEqual(logs[1].level, 'error');
  } finally {
    console.log = originalLog;
  }
});

test('logRateLimitHit responds with 429 and logs an abuse-signal entry with IP and userId', () => {
  const warnings = [];
  const originalWarn = console.warn;
  console.warn = (line) => warnings.push(JSON.parse(line));

  try {
    const handler = logRateLimitHit('Juda ko\'p urinish.');
    const req = fakeReq({ method: 'POST', originalUrl: '/api/auth/login', user: { id: 'abuser' } });
    const res = fakeRes();

    handler(req, res);

    assert.strictEqual(res.statusCode, 429);
    assert.deepStrictEqual(res._json, { error: 'Juda ko\'p urinish.' });

    assert.strictEqual(warnings.length, 1);
    assert.strictEqual(warnings[0].event, 'rate_limit_exceeded');
    assert.strictEqual(warnings[0].ip, '127.0.0.1');
    assert.strictEqual(warnings[0].userId, 'abuser');
    assert.strictEqual(warnings[0].path, '/api/auth/login');
  } finally {
    console.warn = originalWarn;
  }
});
