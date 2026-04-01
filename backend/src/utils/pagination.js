function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function getPagination(query = {}, options = {}) {
  const { defaultLimit = 20, maxLimit = 100 } = options;
  const page = clamp(parseInt(query.page, 10) || 1, 1, 1000000);
  const limit = clamp(parseInt(query.limit, 10) || defaultLimit, 1, maxLimit);
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}

function isPaginated(query = {}) {
  return query.page != null || query.limit != null;
}

function buildPageResponse({ rows, count, page, limit }) {
  return {
    data: rows,
    meta: {
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit) || 1,
    },
  };
}

module.exports = {
  getPagination,
  isPaginated,
  buildPageResponse,
};
