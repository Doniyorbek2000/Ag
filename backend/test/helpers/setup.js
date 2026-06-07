const fs = require('fs');
const os = require('os');
const path = require('path');

// Each test file calls this BEFORE requiring ../../src/app or ../../src/db,
// so the singleton db module connects to a fresh, isolated SQLite file
// rather than the real data/admai.sqlite. node:test runs each test file in
// its own process, so env vars set here don't leak across files.
function freshTestEnv() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'admai-test-'));
  process.env.DATABASE_PATH = path.join(dir, 'test.sqlite');
  process.env.JWT_SECRET = 'test-only-secret-do-not-use-in-production';
  process.env.JWT_EXPIRES_IN = '1h';
  process.env.ADMIN_BOOTSTRAP_EMAIL = 'admin@admai.uz';
  process.env.ADMIN_BOOTSTRAP_PASSWORD = 'admin12345';
  return dir;
}

module.exports = { freshTestEnv };
