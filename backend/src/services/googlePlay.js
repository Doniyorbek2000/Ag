const fs = require('fs');
const jwt = require('jsonwebtoken');

// Server-side verification of Google Play subscription purchases via the
// Google Play Developer API (androidpublisher v3). Requires a service-account
// JSON key with "View financial data" access, granted in Play Console ->
// Setup -> API access, and the path to that key file in
// GOOGLE_PLAY_SERVICE_ACCOUNT_KEY. Without it, isConfigured() returns false
// and the caller decides whether to fall back to trusting the client receipt.

const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

let cachedAccount;
let cachedToken = null;
let cachedTokenExpiry = 0;

function loadServiceAccount() {
  if (cachedAccount !== undefined) return cachedAccount;

  const keyPath = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_KEY;
  if (!keyPath) {
    cachedAccount = null;
    return cachedAccount;
  }

  try {
    const raw = fs.readFileSync(keyPath, 'utf8');
    cachedAccount = JSON.parse(raw);
  } catch (err) {
    cachedAccount = null;
  }
  return cachedAccount;
}

async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedTokenExpiry > now + 60) return cachedToken;

  const account = loadServiceAccount();
  if (!account) return null;

  const assertion = jwt.sign(
    {
      iss: account.client_email,
      scope: SCOPE,
      aud: TOKEN_URL,
      iat: now,
      exp: now + 3600,
    },
    account.private_key,
    { algorithm: 'RS256' }
  );

  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!response.ok) return null;

  const data = await response.json();
  cachedToken = data.access_token;
  cachedTokenExpiry = now + (data.expires_in || 3600);
  return cachedToken;
}

// paymentState: 0 = pending, 1 = received, 2 = free trial, 3 = pending deferred
function isPaymentStateActive(paymentState) {
  return paymentState === 1 || paymentState === 2;
}

/**
 * Verifies a subscription purchase token against the Play Developer API.
 * Returns:
 *   - { valid, expiryTimeMillis, raw } when verification ran
 *   - null when no service account is configured (caller must decide fallback)
 */
async function verifySubscriptionPurchase({ packageName, productId, purchaseToken }) {
  const token = await getAccessToken();
  if (!token) return null;

  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/purchases/subscriptions/` +
    `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!response.ok) {
    return { valid: false, status: response.status, expiryTimeMillis: null, raw: null };
  }

  const data = await response.json();
  return {
    valid: isPaymentStateActive(data.paymentState),
    expiryTimeMillis: data.expiryTimeMillis ? Number(data.expiryTimeMillis) : null,
    raw: data,
  };
}

module.exports = {
  verifySubscriptionPurchase,
  isConfigured: () => !!loadServiceAccount(),
};
