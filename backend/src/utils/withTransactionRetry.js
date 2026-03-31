const DEFAULT_MAX_RETRIES = 3;
const DEFAULT_BASE_DELAY_MS = 50;

function isRetryableTransactionError(err) {
  const code = err && err.original && err.original.code;
  return code === 'ER_LOCK_DEADLOCK' || code === 'ER_LOCK_WAIT_TIMEOUT';
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function withTransactionRetry(sequelize, work, options = {}) {
  const maxRetries = options.maxRetries || DEFAULT_MAX_RETRIES;
  const baseDelayMs = options.baseDelayMs || DEFAULT_BASE_DELAY_MS;

  for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
    try {
      return await sequelize.transaction(async (transaction) => work(transaction));
    } catch (err) {
      if (!isRetryableTransactionError(err) || attempt === maxRetries) {
        throw err;
      }
      const backoff = baseDelayMs * attempt;
      await delay(backoff);
    }
  }

  return null;
}

module.exports = { withTransactionRetry, isRetryableTransactionError };
