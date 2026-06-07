/**
 * Minimal structured access/abuse logger -- no external dependency needed.
 * Emits one JSON line per request to stdout (ready for log aggregation by
 * Docker/any process supervisor) including status, latency, and the
 * client IP, and flags slow or error responses for quick scanning.
 */
function requestLogger(req, res, next) {
  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
    const entry = {
      ts: new Date().toISOString(),
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      durationMs: Math.round(durationMs),
      ip: req.ip,
      userId: req.user?.id || null,
    };

    if (res.statusCode >= 500) entry.level = 'error';
    else if (res.statusCode >= 400) entry.level = 'warn';
    else entry.level = 'info';

    // eslint-disable-next-line no-console
    console.log(JSON.stringify(entry));
  });

  next();
}

/**
 * Wraps express-rate-limit's handler to additionally log when a client is
 * throttled -- repeated hits from the same IP are the clearest abuse signal
 * available without a dedicated monitoring stack.
 */
function logRateLimitHit(message) {
  return (req, res /*, next, options */) => {
    // eslint-disable-next-line no-console
    console.warn(JSON.stringify({
      ts: new Date().toISOString(),
      level: 'warn',
      event: 'rate_limit_exceeded',
      method: req.method,
      path: req.originalUrl,
      ip: req.ip,
      userId: req.user?.id || null,
    }));
    res.status(429).json({ error: message });
  };
}

module.exports = { requestLogger, logRateLimitHit };
