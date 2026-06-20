const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

const actionSchema = z.object({
  type: z.string().min(1).max(50),
  payload: z.record(z.unknown()).default({}),
  status: z.enum(['success', 'failure']).default('success'),
  result: z.record(z.unknown()).optional(),
});

router.post('/', (req, res) => {
  const parsed = actionSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Noto\'g\'ri ma\'lumot' });

  const id = uuidv4();
  db.prepare(`
    INSERT INTO tool_actions (id, user_id, type, payload, status, result)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(
    id,
    req.user.id,
    parsed.data.type,
    JSON.stringify(parsed.data.payload),
    parsed.data.status,
    parsed.data.result ? JSON.stringify(parsed.data.result) : null,
  );

  return res.status(201).json({ id });
});

router.get('/', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);
  const offset = parseInt(req.query.offset) || 0;

  const rows = db.prepare(`
    SELECT * FROM tool_actions WHERE user_id = ?
    ORDER BY created_at DESC LIMIT ? OFFSET ?
  `).all(req.user.id, limit, offset);

  return res.json({ actions: rows });
});

module.exports = router;
