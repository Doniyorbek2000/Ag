const crypto = require('crypto');

// Payme (Paycom, https://developer.help.paycom.uz) Merchant API integration
// helpers -- a JSON-RPC 2.0 webhook authenticated with HTTP Basic auth
// (`Paycom:<merchant key>`).
//
// Activating real payments needs a merchant account that **only the
// business owner can create**: register at business.paycom.uz, create a
// cash register for the app, and copy the MERCHANT_ID and KEY it issues,
// then point Payme's webhook settings at
// `<your-domain>/api/payments/payme/webhook`.
//
// Without PAYME_KEY configured, [isConfigured] is false and the
// checkout/webhook routes respond with a clear "not configured" error
// instead of silently accepting unverifiable payments.

const ERROR = {
  INVALID_AUTH: -32504,
  ORDER_NOT_FOUND: -31050,
  TRANSACTION_NOT_FOUND: -31003,
  CANNOT_CANCEL: -31007,
  COULD_NOT_PERFORM: -31008,
  INTERNAL: -31099,
};

const STATE = {
  CREATED: 1,
  COMPLETED: 2,
  CANCELLED_AFTER_CREATE: -1,
  CANCELLED_AFTER_COMPLETE: -2,
};

function isConfigured() {
  return Boolean(process.env.PAYME_MERCHANT_ID && process.env.PAYME_KEY);
}

/// Builds the hosted-checkout URL: a base64-encoded `m=...;ac.order_id=...;a=...`
/// string identifying the merchant, our internal order id (passed back to us
/// as `account.order_id` in every webhook call) and the amount in tiyin.
function buildCheckoutUrl({ orderId, amountTiyin, returnUrl }) {
  let params = `m=${process.env.PAYME_MERCHANT_ID};ac.order_id=${orderId};a=${amountTiyin}`;
  if (returnUrl) params += `;c=${returnUrl}`;
  const encoded = Buffer.from(params, 'utf8').toString('base64');
  return `https://checkout.paycom.uz/${encoded}`;
}

/// Verifies the `Authorization: Basic base64(Paycom:<key>)` header Payme
/// sends with every JSON-RPC call.
function verifyAuth(authHeader) {
  const key = process.env.PAYME_KEY;
  if (!key || !authHeader || !authHeader.startsWith('Basic ')) return false;

  const decoded = Buffer.from(authHeader.slice('Basic '.length), 'base64').toString('utf8');
  const separatorIndex = decoded.indexOf(':');
  if (separatorIndex === -1) return false;

  const login = decoded.slice(0, separatorIndex);
  const password = decoded.slice(separatorIndex + 1);
  if (login !== 'Paycom') return false;

  const expected = Buffer.from(key);
  const actual = Buffer.from(password);
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
}

function rpcError(id, code, message) {
  return { jsonrpc: '2.0', id, error: { code, message: { ru: message, uz: message, en: message } } };
}

function rpcResult(id, result) {
  return { jsonrpc: '2.0', id, result };
}

module.exports = { ERROR, STATE, isConfigured, buildCheckoutUrl, verifyAuth, rpcError, rpcResult };
