const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

const PLAN_PRICES = { free: 0, pro: 29900, ultra: 59900, vip: 149900 };

// Verifies an in-app purchase receipt (Google Play) and activates the plan.
// In production this should call the Google Play Developer API to validate
// the purchase token before granting entitlements.
const purchaseSchema = z.object({
  plan: z.enum(['pro', 'ultra', 'vip']),
  provider: z.enum(['google_play', 'manual']).default('google_play'),
  purchaseToken: z.string().optional(),
  productId: z.string().optional(),
});

router.post('/purchase', (req, res) => {
  const parsed = purchaseSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Xarid ma\'lumotlari noto\'g\'ri' });

  const { plan, provider, purchaseToken } = parsed.data;

  // TODO: integrate Google Play Developer API purchases.subscriptions.get
  // to verify purchaseToken authenticity before granting access.

  const id = uuidv4();
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

  db.prepare(`
    INSERT INTO subscriptions (id, user_id, plan, status, provider, provider_ref, expires_at, amount)
    VALUES (?, ?, ?, 'active', ?, ?, ?, ?)
  `).run(id, req.user.id, plan, provider, purchaseToken || null, expiresAt, PLAN_PRICES[plan]);

  db.prepare(`
    UPDATE users SET plan = ?, plan_expires_at = ?, updated_at = datetime('now') WHERE id = ?
  `).run(plan, expiresAt, req.user.id);

  return res.status(201).json({ subscriptionId: id, plan, expiresAt });
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
