const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

const messageSchema = z.object({
  source: z.enum(['mobile', 'voice', 'call', 'telegram', 'whatsapp']).default('mobile'),
  role: z.enum(['user', 'assistant', 'tool']),
  content: z.string().min(1).max(16000),
});

router.post('/', (req, res) => {
  const parsed = messageSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Noto\'g\'ri ma\'lumot' });

  const id = uuidv4();
  db.prepare(`
    INSERT INTO conversations (id, user_id, source, role, content)
    VALUES (?, ?, ?, ?, ?)
  `).run(id, req.user.id, parsed.data.source, parsed.data.role, parsed.data.content);

  return res.status(201).json({ id });
});

router.get('/', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);
  const offset = parseInt(req.query.offset) || 0;
  const source = req.query.source;

  let sql = `SELECT * FROM conversations WHERE user_id = ?`;
  const params = [req.user.id];

  if (source) {
    sql += ` AND source = ?`;
    params.push(source);
  }

  sql += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  const rows = db.prepare(sql).all(...params);
  return res.json({ conversations: rows });
});

module.exports = router;
