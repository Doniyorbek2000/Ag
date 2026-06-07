const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');

const router = express.Router();

const registerSchema = z.object({
  name: z.string().min(2).max(80),
  email: z.string().email(),
  password: z.string().min(6).max(128),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function signToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role, plan: user.plan },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
  );
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    plan: user.plan,
    planExpiresAt: user.plan_expires_at,
    dailyCallsUsed: user.daily_calls_used,
    isActive: !!user.is_active,
    createdAt: user.created_at,
  };
}

router.post('/register', (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Ma\'lumotlar noto\'g\'ri', details: parsed.error.flatten() });
  }
  const { name, email, password } = parsed.data;

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase());
  if (existing) return res.status(409).json({ error: 'Bu email allaqachon ro\'yxatdan o\'tgan' });

  const id = uuidv4();
  const hash = bcrypt.hashSync(password, 10);
  db.prepare(`
    INSERT INTO users (id, name, email, password_hash, role, plan)
    VALUES (?, ?, ?, ?, 'user', 'free')
  `).run(id, name, email.toLowerCase(), hash);

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
  const token = signToken(user);
  return res.status(201).json({ token, user: publicUser(user) });
});

router.post('/login', (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Email yoki parol noto\'g\'ri' });
  }
  const { email, password } = parsed.data;

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase());
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'Email yoki parol noto\'g\'ri' });
  }
  if (!user.is_active) {
    return res.status(403).json({ error: 'Hisobingiz bloklangan. Qo\'llab-quvvatlash xizmatiga murojaat qiling.' });
  }

  const token = signToken(user);
  return res.json({ token, user: publicUser(user) });
});

router.get('/me', require('../middleware/auth').authRequired, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'Foydalanuvchi topilmadi' });
  return res.json({ user: publicUser(user) });
});

module.exports = router;
module.exports.publicUser = publicUser;
