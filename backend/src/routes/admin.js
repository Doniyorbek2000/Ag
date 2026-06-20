const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired, adminRequired } = require('../middleware/auth');
const { publicUser } = require('./auth');

const router = express.Router();
router.use(authRequired, adminRequired);

// ---------- Dashboard / Analytics ----------
router.get('/stats', (req, res) => {
  const totalUsers = db.prepare('SELECT COUNT(*) AS c FROM users').get().c;
  const activeUsers = db.prepare('SELECT COUNT(*) AS c FROM users WHERE is_active = 1').get().c;

  const planCounts = db.prepare(`
    SELECT plan, COUNT(*) AS count FROM users GROUP BY plan
  `).all();

  const revenue = db.prepare(`
    SELECT COALESCE(SUM(amount), 0) AS total FROM subscriptions WHERE status = 'active'
  `).get().total;

  const newUsersLast7Days = db.prepare(`
    SELECT date(created_at) AS day, COUNT(*) AS count
    FROM users
    WHERE created_at >= datetime('now', '-7 days')
    GROUP BY day
    ORDER BY day ASC
  `).all();

  const usageLast7Days = db.prepare(`
    SELECT date(created_at) AS day, COUNT(*) AS count
    FROM usage_logs
    WHERE created_at >= datetime('now', '-7 days')
    GROUP BY day
    ORDER BY day ASC
  `).all();

  const openTickets = db.prepare(`SELECT COUNT(*) AS c FROM support_tickets WHERE status = 'open'`).get().c;

  return res.json({
    totalUsers,
    activeUsers,
    planCounts,
    revenue,
    newUsersLast7Days,
    usageLast7Days,
    openTickets,
  });
});

// ---------- User management ----------
const listQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().optional(),
  plan: z.string().optional(),
  role: z.string().optional(),
});

router.get('/users', (req, res) => {
  const parsed = listQuerySchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Noto\'g\'ri so\'rov parametrlari' });
  const { page, pageSize, search, plan, role } = parsed.data;

  const conditions = [];
  const params = {};
  if (search) {
    conditions.push('(name LIKE @search OR email LIKE @search)');
    params.search = `%${search}%`;
  }
  if (plan) {
    conditions.push('plan = @plan');
    params.plan = plan;
  }
  if (role) {
    conditions.push('role = @role');
    params.role = role;
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const total = db.prepare(`SELECT COUNT(*) AS c FROM users ${where}`).get(params).c;
  const rows = db.prepare(`
    SELECT * FROM users ${where}
    ORDER BY created_at DESC
    LIMIT @limit OFFSET @offset
  `).all({ ...params, limit: pageSize, offset: (page - 1) * pageSize });

  return res.json({
    users: rows.map(publicUser),
    pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
  });
});

router.get('/users/:id', (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });

  const subscriptions = db.prepare(`
    SELECT * FROM subscriptions WHERE user_id = ? ORDER BY created_at DESC
  `).all(user.id);

  const usage = db.prepare(`
    SELECT * FROM usage_logs WHERE user_id = ? ORDER BY created_at DESC LIMIT 50
  `).all(user.id);

  return res.json({ user: publicUser(user), subscriptions, usage });
});

const updateUserSchema = z.object({
  name: z.string().min(2).max(80).optional(),
  plan: z.enum(['free', 'pro', 'ultra', 'vip']).optional(),
  role: z.enum(['user', 'admin']).optional(),
  isActive: z.boolean().optional(),
});

router.patch('/users/:id', (req, res) => {
  const parsed = updateUserSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Ma\'lumotlar noto\'g\'ri' });

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });

  const fields = parsed.data;
  const updates = [];
  const params = { id: user.id };

  if (fields.name !== undefined) { updates.push('name = @name'); params.name = fields.name; }
  if (fields.plan !== undefined) { updates.push('plan = @plan'); params.plan = fields.plan; }
  if (fields.role !== undefined) { updates.push('role = @role'); params.role = fields.role; }
  if (fields.isActive !== undefined) { updates.push('is_active = @isActive'); params.isActive = fields.isActive ? 1 : 0; }

  if (updates.length === 0) return res.status(400).json({ error: 'Yangilanadigan maydon ko\'rsatilmagan' });

  updates.push("updated_at = datetime('now')");
  db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = @id`).run(params);

  if (fields.plan !== undefined) {
    db.prepare(`
      INSERT INTO subscriptions (id, user_id, plan, status, provider, amount)
      VALUES (?, ?, ?, 'active', 'admin', 0)
    `).run(uuidv4(), user.id, fields.plan);
  }

  const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(user.id);
  return res.json({ user: publicUser(updated) });
});

router.delete('/users/:id', (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });
  if (user.role === 'admin') return res.status(400).json({ error: 'Administratorni o\'chirib bo\'lmaydi' });

  db.prepare('DELETE FROM users WHERE id = ?').run(user.id);
  return res.json({ success: true });
});

// ---------- Subscriptions ----------
router.get('/subscriptions', (req, res) => {
  const rows = db.prepare(`
    SELECT s.*, u.name AS user_name, u.email AS user_email
    FROM subscriptions s
    JOIN users u ON u.id = s.user_id
    ORDER BY s.created_at DESC
    LIMIT 200
  `).all();
  return res.json({ subscriptions: rows });
});

// ---------- Support tickets ----------
router.get('/tickets', (req, res) => {
  const status = req.query.status;
  const where = status ? 'WHERE t.status = ?' : '';
  const params = status ? [status] : [];
  const rows = db.prepare(`
    SELECT t.*, u.name AS user_name, u.email AS user_email
    FROM support_tickets t
    JOIN users u ON u.id = t.user_id
    ${where}
    ORDER BY t.created_at DESC
  `).all(...params);
  return res.json({ tickets: rows });
});

const ticketUpdateSchema = z.object({
  status: z.enum(['open', 'in_progress', 'resolved', 'closed']),
});

router.patch('/tickets/:id', (req, res) => {
  const parsed = ticketUpdateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Holat noto\'g\'ri' });

  const ticket = db.prepare('SELECT * FROM support_tickets WHERE id = ?').get(req.params.id);
  if (!ticket) return res.status(404).json({ error: 'Murojaat topilmadi' });

  db.prepare(`
    UPDATE support_tickets SET status = ?, updated_at = datetime('now') WHERE id = ?
  `).run(parsed.data.status, ticket.id);

  return res.json({ success: true });
});

// ---------- Broadcasts ----------
const broadcastSchema = z.object({
  title: z.string().min(2).max(120),
  body: z.string().min(2).max(2000),
  targetPlan: z.enum(['all', 'free', 'pro', 'ultra', 'vip']).default('all'),
});

router.get('/broadcasts', (req, res) => {
  const rows = db.prepare(`SELECT * FROM broadcasts ORDER BY created_at DESC LIMIT 100`).all();
  return res.json({ broadcasts: rows });
});

router.post('/broadcasts', (req, res) => {
  const parsed = broadcastSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Ma\'lumotlar noto\'g\'ri', details: parsed.error.flatten() });

  const { title, body, targetPlan } = parsed.data;
  const where = targetPlan === 'all' ? '' : 'WHERE plan = ?';
  const params = targetPlan === 'all' ? [] : [targetPlan];
  const recipientCount = db.prepare(`SELECT COUNT(*) AS c FROM users ${where}`).get(...params).c;

  const id = uuidv4();
  db.prepare(`
    INSERT INTO broadcasts (id, title, body, target_plan, sent_count, created_by)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(id, title, body, targetPlan, recipientCount, req.user.id);

  // NOTE: actual push delivery would be wired to FCM here.
  return res.status(201).json({ id, recipientCount });
});

// ---------- Conversations ----------
router.get('/conversations', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);
  const offset = parseInt(req.query.offset) || 0;
  const userId = req.query.user_id;
  const source = req.query.source;

  let sql = `SELECT c.*, u.name as user_name, u.email as user_email
    FROM conversations c JOIN users u ON c.user_id = u.id`;
  const conditions = [];
  const params = [];

  if (userId) { conditions.push(`c.user_id = ?`); params.push(userId); }
  if (source) { conditions.push(`c.source = ?`); params.push(source); }
  if (conditions.length) sql += ` WHERE ${conditions.join(' AND ')}`;

  sql += ` ORDER BY c.created_at DESC LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  const rows = db.prepare(sql).all(...params);
  const total = db.prepare(`SELECT COUNT(*) AS c FROM conversations`).get().c;
  return res.json({ conversations: rows, total });
});

// ---------- Tool actions ----------
router.get('/tool-actions', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);
  const offset = parseInt(req.query.offset) || 0;

  const rows = db.prepare(`
    SELECT t.*, u.name as user_name FROM tool_actions t
    JOIN users u ON t.user_id = u.id
    ORDER BY t.created_at DESC LIMIT ? OFFSET ?
  `).all(limit, offset);
  const total = db.prepare(`SELECT COUNT(*) AS c FROM tool_actions`).get().c;
  return res.json({ actions: rows, total });
});

module.exports = router;
