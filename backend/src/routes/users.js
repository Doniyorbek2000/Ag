const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired } = require('../middleware/auth');
const { publicUser } = require('./auth');

const router = express.Router();
router.use(authRequired);

const PLAN_LIMITS = { free: 20, pro: 200, ultra: -1, vip: -1 };

router.get('/me/usage', (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });

  const limit = PLAN_LIMITS[user.plan] ?? 20;
  const today = new Date().toISOString().slice(0, 10);
  const lastReset = (user.daily_calls_reset_at || '').slice(0, 10);

  let used = user.daily_calls_used;
  if (lastReset !== today) used = 0;

  return res.json({
    plan: user.plan,
    limit,
    used,
    remaining: limit === -1 ? -1 : Math.max(0, limit - used),
  });
});

router.post('/me/usage/increment', (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });

  const today = new Date().toISOString().slice(0, 10);
  const lastReset = (user.daily_calls_reset_at || '').slice(0, 10);
  const used = lastReset === today ? user.daily_calls_used + 1 : 1;

  db.prepare(`
    UPDATE users SET daily_calls_used = ?, daily_calls_reset_at = datetime('now'), updated_at = datetime('now')
    WHERE id = ?
  `).run(used, user.id);

  db.prepare(`
    INSERT INTO usage_logs (id, user_id, action, tokens_in, tokens_out)
    VALUES (?, ?, 'ai_chat', ?, ?)
  `).run(uuidv4(), user.id, req.body?.tokensIn || 0, req.body?.tokensOut || 0);

  return res.json({ used });
});

router.patch('/me', (req, res) => {
  const schema = z.object({ name: z.string().min(2).max(80) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Ism noto\'g\'ri' });

  db.prepare(`UPDATE users SET name = ?, updated_at = datetime('now') WHERE id = ?`)
    .run(parsed.data.name, req.user.id);

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  return res.json({ user: publicUser(user) });
});

const ticketSchema = z.object({
  subject: z.string().min(2).max(150),
  message: z.string().min(2).max(4000),
});

router.post('/me/tickets', (req, res) => {
  const parsed = ticketSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Ma\'lumotlar noto\'g\'ri' });

  const id = uuidv4();
  db.prepare(`
    INSERT INTO support_tickets (id, user_id, subject, message)
    VALUES (?, ?, ?, ?)
  `).run(id, req.user.id, parsed.data.subject, parsed.data.message);

  return res.status(201).json({ id });
});

router.get('/me/tickets', (req, res) => {
  const rows = db.prepare(`
    SELECT * FROM support_tickets WHERE user_id = ? ORDER BY created_at DESC
  `).all(req.user.id);
  return res.json({ tickets: rows });
});

// Permanently deletes the caller's account and all data tied to it
// (subscriptions, payments, usage logs, support tickets cascade via FK).
// Required for Google Play's in-app account deletion policy.
router.delete('/me', (req, res) => {
  db.prepare(`UPDATE broadcasts SET created_by = NULL WHERE created_by = ?`).run(req.user.id);
  const result = db.prepare(`DELETE FROM users WHERE id = ?`).run(req.user.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });
  return res.status(204).send();
});

module.exports = router;
