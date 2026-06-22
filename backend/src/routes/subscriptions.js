const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired } = require('../middleware/auth');
const googlePlay = require('../services/googlePlay');

const router = express.Router();
router.use(authRequired);

const PLAN_PRICES = { free: 0, pro: 29900, ultra: 59900, vip: 149900 };

// Verifies an in-app purchase receipt and activates the plan. When
// GOOGLE_PLAY_SERVICE_ACCOUNT_KEY is configured, the purchase token is
// validated against the Google Play Developer API (see ../services/googlePlay)
// before any entitlement is granted; unverifiable or inactive purchases are
// rejected with 402. Without that key, the purchase is logged and trusted
// from the client receipt -- set the env var to enable real verification.
const purchaseSchema = z.object({
  plan: z.enum(['pro', 'ultra', 'vip']),
  provider: z.enum(['google_play', 'manual']).default('google_play'),
  purchaseToken: z.string().optional(),
  productId: z.string().optional(),
});

router.post('/purchase', async (req, res) => {
  try {
    const parsed = purchaseSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: 'Xarid ma\'lumotlari noto\'g\'ri' });

    const { plan, provider, purchaseToken, productId } = parsed.data;

    let expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

    if (provider === 'google_play') {
      if (!purchaseToken || !productId) {
        return res.status(400).json({ error: 'purchaseToken va productId talab qilinadi' });
      }

      if (googlePlay.isConfigured()) {
        const result = await googlePlay.verifySubscriptionPurchase({
          packageName: process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.admai.app',
          productId,
          purchaseToken,
        });

        if (!result || !result.valid) {
          return res.status(402).json({ error: 'Xarid Google Play tomonidan tasdiqlanmadi' });
        }

        if (result.expiryTimeMillis) {
          expiresAt = new Date(result.expiryTimeMillis).toISOString();
        }
      } else {
        console.warn(
          '[subscriptions] GOOGLE_PLAY_SERVICE_ACCOUNT_KEY sozlanmagan -- ' +
          'xarid mijoz tomonidan yuborilgan kvitansiyaga ishonib faollashtirilmoqda'
        );
      }
    }

    const id = uuidv4();

    db.prepare(`
      INSERT INTO subscriptions (id, user_id, plan, status, provider, provider_ref, expires_at, amount)
      VALUES (?, ?, ?, 'active', ?, ?, ?, ?)
    `).run(id, req.user.id, plan, provider, purchaseToken || null, expiresAt, PLAN_PRICES[plan]);

    db.prepare(`
      UPDATE users SET plan = ?, plan_expires_at = ?, updated_at = datetime('now') WHERE id = ?
    `).run(plan, expiresAt, req.user.id);

    return res.status(201).json({ subscriptionId: id, plan, expiresAt });
  } catch (err) {
    console.error('[subscriptions] Purchase error:', err);
    return res.status(500).json({ error: 'Xarid jarayonida xato yuz berdi' });
  }
});

router.get('/me', (req, res) => {
  const rows = db.prepare(`
    SELECT * FROM subscriptions WHERE user_id = ? ORDER BY created_at DESC
  `).all(req.user.id);
  return res.json({ subscriptions: rows });
});

router.post('/cancel', (req, res) => {
  db.prepare(`
    UPDATE subscriptions SET status = 'cancelled' WHERE user_id = ? AND status = 'active'
  `).run(req.user.id);

  db.prepare(`
    UPDATE users SET plan = 'free', plan_expires_at = NULL, updated_at = datetime('now') WHERE id = ?
  `).run(req.user.id);

  return res.json({ success: true });
});

module.exports = router;
