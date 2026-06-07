const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const db = require('../db');
const { authRequired } = require('../middleware/auth');
const click = require('../services/click');
const payme = require('../services/payme');

const router = express.Router();

// Same plan pricing the in-app-purchase flow uses (../routes/subscriptions),
// expressed in UZS -- Click takes whole-sum amounts, Payme takes tiyin
// (1 UZS = 100 tiyin).
const PLAN_PRICES = { pro: 29900, ultra: 59900, vip: 149900 };
const SUBSCRIPTION_DAYS = 30;

const checkoutSchema = z.object({
  plan: z.enum(['pro', 'ultra', 'vip']),
  returnUrl: z.string().url().optional(),
});

function activateSubscription({ userId, plan, provider, providerRef, amount }) {
  const expiresAt = new Date(Date.now() + SUBSCRIPTION_DAYS * 24 * 60 * 60 * 1000).toISOString();
  const id = uuidv4();

  db.prepare(`
    INSERT INTO subscriptions (id, user_id, plan, status, provider, provider_ref, expires_at, amount)
    VALUES (?, ?, ?, 'active', ?, ?, ?, ?)
  `).run(id, userId, plan, provider, providerRef || null, expiresAt, amount);

  db.prepare(`
    UPDATE users SET plan = ?, plan_expires_at = ?, updated_at = datetime('now') WHERE id = ?
  `).run(plan, expiresAt, userId);

  return { id, expiresAt };
}

// ---------------------------------------------------------------------------
// Click
// ---------------------------------------------------------------------------

// Creates a pending local payment record and returns the hosted-checkout URL
// the app opens (via url_launcher) so the user can pay with their card.
router.post('/click/create', authRequired, (req, res) => {
  if (!click.isConfigured()) {
    return res.status(503).json({ error: 'Click to\'lov tizimi sozlanmagan' });
  }

  const parsed = checkoutSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'So\'rov ma\'lumotlari noto\'g\'ri' });

  const { plan, returnUrl } = parsed.data;
  const amount = PLAN_PRICES[plan];
  const orderId = uuidv4();

  db.prepare(`
    INSERT INTO payments (id, user_id, plan, provider, status, amount)
    VALUES (?, ?, ?, 'click', 'pending', ?)
  `).run(orderId, req.user.id, plan, amount);

  const checkoutUrl = click.buildCheckoutUrl({ orderId, amount, returnUrl });
  return res.status(201).json({ orderId, checkoutUrl });
});

// Click calls this twice per payment: action=0 ("Prepare", reserve the order)
// and action=1 ("Complete", confirm the money has moved). Responses must
// follow Click's exact JSON shape -- see https://docs.click.uz/click-api-merchant-bitimi/.
router.post('/click/webhook', express.urlencoded({ extended: false }), (req, res) => {
  const body = req.body;

  if (!click.isConfigured()) {
    return res.json({ error: click.ERROR.BAD_REQUEST, error_note: 'Sozlanmagan' });
  }
  if (!click.verifySignature(body)) {
    return res.json({ error: click.ERROR.SIGN_FAILED, error_note: 'SIGN CHECK FAILED!' });
  }

  const orderId = body.merchant_trans_id;
  const payment = db.prepare(`SELECT * FROM payments WHERE id = ? AND provider = 'click'`).get(orderId);
  if (!payment) {
    return res.json({ error: click.ERROR.TRANSACTION_NOT_FOUND, error_note: 'Buyurtma topilmadi' });
  }
  if (Number(body.amount) !== payment.amount) {
    return res.json({ error: click.ERROR.AMOUNT_MISMATCH, error_note: 'Summa mos kelmadi' });
  }

  const action = Number(body.action);

  if (action === click.ACTION.PREPARE) {
    if (payment.status === 'completed') {
      return res.json({ error: click.ERROR.ALREADY_PAID, error_note: 'Allaqachon to\'langan' });
    }
    db.prepare(`UPDATE payments SET status = 'prepared', provider_tx_id = ?, updated_at = datetime('now') WHERE id = ?`)
      .run(String(body.click_trans_id), orderId);

    return res.json({
      click_trans_id: body.click_trans_id,
      merchant_trans_id: orderId,
      merchant_prepare_id: orderId,
      error: click.ERROR.SUCCESS,
      error_note: 'Success',
    });
  }

  if (action === click.ACTION.COMPLETE) {
    if (payment.status === 'completed') {
      return res.json({ error: click.ERROR.ALREADY_PAID, error_note: 'Allaqachon to\'langan' });
    }
    if (Number(body.error) < 0) {
      db.prepare(`UPDATE payments SET status = 'cancelled', updated_at = datetime('now') WHERE id = ?`).run(orderId);
      return res.json({
        click_trans_id: body.click_trans_id,
        merchant_trans_id: orderId,
        merchant_confirm_id: orderId,
        error: click.ERROR.SUCCESS,
        error_note: 'Cancelled',
      });
    }

    db.prepare(`UPDATE payments SET status = 'completed', updated_at = datetime('now') WHERE id = ?`).run(orderId);
    activateSubscription({
      userId: payment.user_id,
      plan: payment.plan,
      provider: 'click',
      providerRef: String(body.click_trans_id),
      amount: payment.amount,
    });

    return res.json({
      click_trans_id: body.click_trans_id,
      merchant_trans_id: orderId,
      merchant_confirm_id: orderId,
      error: click.ERROR.SUCCESS,
      error_note: 'Success',
    });
  }

  return res.json({ error: click.ERROR.ACTION_NOT_FOUND, error_note: 'Action not found' });
});

// ---------------------------------------------------------------------------
// Payme
// ---------------------------------------------------------------------------

router.post('/payme/create', authRequired, (req, res) => {
  if (!payme.isConfigured()) {
    return res.status(503).json({ error: 'Payme to\'lov tizimi sozlanmagan' });
  }

  const parsed = checkoutSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'So\'rov ma\'lumotlari noto\'g\'ri' });

  const { plan, returnUrl } = parsed.data;
  const amount = PLAN_PRICES[plan];
  const orderId = uuidv4();

  db.prepare(`
    INSERT INTO payments (id, user_id, plan, provider, status, amount)
    VALUES (?, ?, ?, 'payme', 'pending', ?)
  `).run(orderId, req.user.id, plan, amount);

  const checkoutUrl = payme.buildCheckoutUrl({ orderId, amountTiyin: Math.round(amount * 100), returnUrl });
  return res.status(201).json({ orderId, checkoutUrl });
});

// Payme's single JSON-RPC 2.0 endpoint -- one of six methods per call.
// See https://developer.help.paycom.uz/metody-merchant-api/ for the exact
// request/response/error contract each method must follow.
router.post('/payme/webhook', (req, res) => {
  const { id, method, params } = req.body || {};

  if (!payme.isConfigured()) {
    return res.json(payme.rpcError(id, payme.ERROR.INTERNAL, 'To\'lov tizimi sozlanmagan'));
  }
  if (!payme.verifyAuth(req.headers.authorization)) {
    return res.json(payme.rpcError(id, payme.ERROR.INVALID_AUTH, 'Avtorizatsiya xato'));
  }

  switch (method) {
    case 'CheckPerformTransaction':
      return res.json(handleCheckPerformTransaction(id, params));
    case 'CreateTransaction':
      return res.json(handleCreateTransaction(id, params));
    case 'PerformTransaction':
      return res.json(handlePerformTransaction(id, params));
    case 'CancelTransaction':
      return res.json(handleCancelTransaction(id, params));
    case 'CheckTransaction':
      return res.json(handleCheckTransaction(id, params));
    case 'GetStatement':
      return res.json(handleGetStatement(id, params));
    default:
      return res.json(payme.rpcError(id, payme.ERROR.INTERNAL, 'Noma\'lum metod'));
  }
});

function findOrder(params) {
  const orderId = params?.account?.order_id;
  if (!orderId) return null;
  return db.prepare(`SELECT * FROM payments WHERE id = ? AND provider = 'payme'`).get(orderId);
}

function handleCheckPerformTransaction(id, params) {
  const order = findOrder(params);
  if (!order) return payme.rpcError(id, payme.ERROR.ORDER_NOT_FOUND, 'Buyurtma topilmadi');
  if (Number(params.amount) !== Math.round(order.amount * 100)) {
    return payme.rpcError(id, payme.ERROR.ORDER_NOT_FOUND, 'Summa mos kelmadi');
  }
  return payme.rpcResult(id, { allow: true });
}

function handleCreateTransaction(id, params) {
  const order = findOrder(params);
  if (!order) return payme.rpcError(id, payme.ERROR.ORDER_NOT_FOUND, 'Buyurtma topilmadi');
  if (Number(params.amount) !== Math.round(order.amount * 100)) {
    return payme.rpcError(id, payme.ERROR.ORDER_NOT_FOUND, 'Summa mos kelmadi');
  }

  const existing = db.prepare(`SELECT * FROM payments WHERE provider_tx_id = ? AND provider = 'payme'`).get(params.id);
  if (existing && existing.id !== order.id) {
    return payme.rpcError(id, payme.ERROR.COULD_NOT_PERFORM, 'Tranzaksiya boshqa buyurtmaga tegishli');
  }

  if (order.status === 'completed') {
    return payme.rpcError(id, payme.ERROR.COULD_NOT_PERFORM, 'Buyurtma allaqachon yakunlangan');
  }

  if (order.status === 'pending') {
    db.prepare(`
      UPDATE payments SET status = 'created', provider_tx_id = ?, updated_at = datetime('now') WHERE id = ?
    `).run(params.id, order.id);
  }

  const created = db.prepare(`SELECT * FROM payments WHERE id = ?`).get(order.id);
  return payme.rpcResult(id, {
    create_time: Date.parse(created.created_at) || Date.now(),
    transaction: created.provider_tx_id,
    state: payme.STATE.CREATED,
  });
}

function handlePerformTransaction(id, params) {
  const payment = db.prepare(`SELECT * FROM payments WHERE provider_tx_id = ? AND provider = 'payme'`).get(params.id);
  if (!payment) return payme.rpcError(id, payme.ERROR.TRANSACTION_NOT_FOUND, 'Tranzaksiya topilmadi');

  if (payment.status === 'completed') {
    return payme.rpcResult(id, {
      transaction: payment.provider_tx_id,
      perform_time: Date.parse(payment.updated_at) || Date.now(),
      state: payme.STATE.COMPLETED,
    });
  }
  if (payment.status !== 'created') {
    return payme.rpcError(id, payme.ERROR.COULD_NOT_PERFORM, 'Tranzaksiyani yakunlab bo\'lmaydi');
  }

  db.prepare(`UPDATE payments SET status = 'completed', updated_at = datetime('now') WHERE id = ?`).run(payment.id);
  activateSubscription({
    userId: payment.user_id,
    plan: payment.plan,
    provider: 'payme',
    providerRef: payment.provider_tx_id,
    amount: payment.amount,
  });

  const completed = db.prepare(`SELECT * FROM payments WHERE id = ?`).get(payment.id);
  return payme.rpcResult(id, {
    transaction: completed.provider_tx_id,
    perform_time: Date.parse(completed.updated_at) || Date.now(),
    state: payme.STATE.COMPLETED,
  });
}

function handleCancelTransaction(id, params) {
  const payment = db.prepare(`SELECT * FROM payments WHERE provider_tx_id = ? AND provider = 'payme'`).get(params.id);
  if (!payment) return payme.rpcError(id, payme.ERROR.TRANSACTION_NOT_FOUND, 'Tranzaksiya topilmadi');

  const wasCompleted = payment.status === 'completed';
  db.prepare(`UPDATE payments SET status = 'cancelled', updated_at = datetime('now') WHERE id = ?`).run(payment.id);

  return payme.rpcResult(id, {
    transaction: payment.provider_tx_id,
    cancel_time: Date.now(),
    state: wasCompleted ? payme.STATE.CANCELLED_AFTER_COMPLETE : payme.STATE.CANCELLED_AFTER_CREATE,
  });
}

function handleCheckTransaction(id, params) {
  const payment = db.prepare(`SELECT * FROM payments WHERE provider_tx_id = ? AND provider = 'payme'`).get(params.id);
  if (!payment) return payme.rpcError(id, payme.ERROR.TRANSACTION_NOT_FOUND, 'Tranzaksiya topilmadi');

  const stateMap = {
    created: payme.STATE.CREATED,
    completed: payme.STATE.COMPLETED,
    cancelled: payme.STATE.CANCELLED_AFTER_CREATE,
  };

  return payme.rpcResult(id, {
    create_time: Date.parse(payment.created_at) || 0,
    perform_time: payment.status === 'completed' ? (Date.parse(payment.updated_at) || 0) : 0,
    cancel_time: payment.status === 'cancelled' ? (Date.parse(payment.updated_at) || 0) : 0,
    transaction: payment.provider_tx_id,
    state: stateMap[payment.status] ?? payme.STATE.CREATED,
    reason: null,
  });
}

function handleGetStatement(id, params) {
  const from = params?.from ? new Date(params.from).toISOString() : '0000-01-01';
  const to = params?.to ? new Date(params.to).toISOString() : '9999-12-31';

  const rows = db.prepare(`
    SELECT * FROM payments
    WHERE provider = 'payme' AND provider_tx_id IS NOT NULL AND created_at BETWEEN ? AND ?
    ORDER BY created_at ASC
  `).all(from, to);

  const stateMap = {
    created: payme.STATE.CREATED,
    completed: payme.STATE.COMPLETED,
    cancelled: payme.STATE.CANCELLED_AFTER_CREATE,
  };

  return payme.rpcResult(id, {
    transactions: rows.map((row) => ({
      id: row.provider_tx_id,
      time: Date.parse(row.created_at) || 0,
      amount: Math.round(row.amount * 100),
      account: { order_id: row.id },
      create_time: Date.parse(row.created_at) || 0,
      perform_time: row.status === 'completed' ? (Date.parse(row.updated_at) || 0) : 0,
      cancel_time: row.status === 'cancelled' ? (Date.parse(row.updated_at) || 0) : 0,
      transaction: row.provider_tx_id,
      state: stateMap[row.status] ?? payme.STATE.CREATED,
      reason: null,
    })),
  });
}

module.exports = router;
