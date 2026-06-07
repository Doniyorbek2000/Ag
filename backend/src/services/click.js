const crypto = require('crypto');

// Click.uz (https://docs.click.uz) Merchant API v2 integration helpers.
//
// Activating real payments needs a merchant account that **only the
// business owner can create**: sign up at merchant.click.uz, request a
// "Shop API" service and copy the SERVICE_ID, MERCHANT_ID and SECRET_KEY
// it issues, then point Click's webhook settings at
// `<your-domain>/api/payments/click/webhook`.
//
// Without CLICK_SECRET_KEY configured, [isConfigured] is false and the
// checkout/webhook routes respond with a clear "not configured" error
// instead of silently accepting unverifiable payments.

const ERROR = {
  SUCCESS: 0,
  SIGN_FAILED: -1,
  AMOUNT_MISMATCH: -2,
  ACTION_NOT_FOUND: -3,
  ALREADY_PAID: -4,
  USER_NOT_FOUND: -5,
  TRANSACTION_NOT_FOUND: -6,
  FAILED_TO_UPDATE: -7,
  BAD_REQUEST: -8,
  TRANSACTION_CANCELLED: -9,
};

const ACTION = { PREPARE: 0, COMPLETE: 1 };

function isConfigured() {
  return Boolean(process.env.CLICK_SERVICE_ID && process.env.CLICK_MERCHANT_ID && process.env.CLICK_SECRET_KEY);
}

/// Builds the hosted-checkout URL the app opens (via url_launcher) to let
/// the user pay -- Click then redirects back to [returnUrl] and separately
/// calls the merchant webhook to confirm the payment server-side.
function buildCheckoutUrl({ orderId, amount, returnUrl }) {
  const params = new URLSearchParams({
    service_id: process.env.CLICK_SERVICE_ID,
    merchant_id: process.env.CLICK_MERCHANT_ID,
    amount: String(amount),
    transaction_param: orderId,
  });
  if (returnUrl) params.set('return_url', returnUrl);
  return `https://my.click.uz/services/pay?${params.toString()}`;
}

/// Recomputes Click's MD5 sign_string and compares it against the one the
/// webhook request supplied -- this is the only thing standing between
/// "anyone who knows our endpoint" and "Click, having verified the payment".
function verifySignature(body) {
  const secret = process.env.CLICK_SECRET_KEY;
  if (!secret) return false;

  const action = Number(body.action);
  const parts = [body.click_trans_id, body.service_id, secret, body.merchant_trans_id];
  if (action === ACTION.COMPLETE) parts.push(body.merchant_prepare_id);
  parts.push(body.amount, body.action, body.sign_time);

  const expected = crypto.createHash('md5').update(parts.join('')).digest('hex');
  return expected === body.sign_string;
}

module.exports = { ERROR, ACTION, isConfigured, buildCheckoutUrl, verifySignature };
