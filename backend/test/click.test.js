const test = require('node:test');
const assert = require('node:assert');
const crypto = require('crypto');

const click = require('../src/services/click');

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

test('isConfigured is false unless service id, merchant id and secret key are all set', () => {
  withEnv({ CLICK_SERVICE_ID: '', CLICK_MERCHANT_ID: '', CLICK_SECRET_KEY: '' }, () => {
    assert.strictEqual(click.isConfigured(), false);
  });
  withEnv({ CLICK_SERVICE_ID: '1', CLICK_MERCHANT_ID: '2', CLICK_SECRET_KEY: 'secret' }, () => {
    assert.strictEqual(click.isConfigured(), true);
  });
});

test('buildCheckoutUrl embeds the service/merchant ids, amount and order id', () => {
  withEnv({ CLICK_SERVICE_ID: '111', CLICK_MERCHANT_ID: '222', CLICK_SECRET_KEY: 'secret' }, () => {
    const url = click.buildCheckoutUrl({ orderId: 'order-1', amount: 29900, returnUrl: 'https://app/back' });
    assert.match(url, /^https:\/\/my\.click\.uz\/services\/pay\?/);
    assert.match(url, /service_id=111/);
    assert.match(url, /merchant_id=222/);
    assert.match(url, /amount=29900/);
    assert.match(url, /transaction_param=order-1/);
    assert.match(url, /return_url=https/);
  });
});

test('verifySignature accepts a correctly computed Prepare sign_string and rejects a tampered one', () => {
  withEnv({ CLICK_SERVICE_ID: '111', CLICK_MERCHANT_ID: '222', CLICK_SECRET_KEY: 'topsecret' }, () => {
    const body = {
      click_trans_id: '900',
      service_id: '111',
      merchant_trans_id: 'order-1',
      amount: '29900',
      action: 0,
      sign_time: '2026-01-01 10:00:00',
    };
    const expected = crypto
      .createHash('md5')
      .update(`${body.click_trans_id}${body.service_id}topsecret${body.merchant_trans_id}${body.amount}${body.action}${body.sign_time}`)
      .digest('hex');

    assert.strictEqual(click.verifySignature({ ...body, sign_string: expected }), true);
    assert.strictEqual(click.verifySignature({ ...body, sign_string: 'wrong' }), false);
  });
});

test('verifySignature includes merchant_prepare_id for the Complete action', () => {
  withEnv({ CLICK_SERVICE_ID: '111', CLICK_MERCHANT_ID: '222', CLICK_SECRET_KEY: 'topsecret' }, () => {
    const body = {
      click_trans_id: '900',
      service_id: '111',
      merchant_trans_id: 'order-1',
      merchant_prepare_id: 'order-1',
      amount: '29900',
      action: 1,
      sign_time: '2026-01-01 10:05:00',
    };
    const expected = crypto
      .createHash('md5')
      .update(`${body.click_trans_id}${body.service_id}topsecret${body.merchant_trans_id}${body.merchant_prepare_id}${body.amount}${body.action}${body.sign_time}`)
      .digest('hex');

    assert.strictEqual(click.verifySignature({ ...body, sign_string: expected }), true);

    // Without merchant_prepare_id in the hashed parts (e.g. wrong action), the
    // sign won't match -- guards against action-confusion attacks.
    assert.strictEqual(click.verifySignature({ ...body, action: 0, sign_string: expected }), false);
  });
});

test('verifySignature returns false when no secret key is configured', () => {
  withEnv({ CLICK_SECRET_KEY: '' }, () => {
    assert.strictEqual(click.verifySignature({ sign_string: 'anything' }), false);
  });
});
