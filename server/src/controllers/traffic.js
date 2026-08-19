const WAZE_URL = 'https://api.openwebninja.com/waze/alerts-and-jams';
const CACHE_TTL_MS = 15 * 1000;
const trafficCache = new Map();

function normaliseCoordinate(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number.toFixed(4) : null;
}

function getBounds(req) {
  const bottomLeft = String(req.query.bottom_left || '').split(',');
  const topRight = String(req.query.top_right || '').split(',');

  if (bottomLeft.length !== 2 || topRight.length !== 2) return null;

  const values = [
    normaliseCoordinate(bottomLeft[0]),
    normaliseCoordinate(bottomLeft[1]),
    normaliseCoordinate(topRight[0]),
    normaliseCoordinate(topRight[1]),
  ];

  return values.every(Boolean) ? values : null;
}

async function getTraffic(req, res, next) {
  const bounds = getBounds(req);
  const apiKey = process.env.WAZE_API_KEY || process.env.OPENWEBNINJA_API_KEY;

  if (!bounds) {
    return res.status(400).json({
      error: 'bottom_left and top_right must be latitude,longitude pairs',
    });
  }

  if (!apiKey) {
    return res.status(503).json({ error: 'Traffic service is not configured' });
  }

  const [bottomLat, bottomLng, topLat, topLng] = bounds;
  const cacheKey = bounds.join('|');
  const cached = trafficCache.get(cacheKey);
  if (cached && cached.expiresAt > Date.now()) {
    return res.json(cached.data);
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    const url = new URL(WAZE_URL);
    url.searchParams.set('bottom_left', `${bottomLat},${bottomLng}`);
    url.searchParams.set('top_right', `${topLat},${topLng}`);

    const response = await fetch(url, {
      method: 'GET',
      signal: controller.signal,
      headers: { 'X-API-Key': apiKey },
    });
    clearTimeout(timeout);

    if (!response.ok) {
      return res.status(response.status).json({ error: 'Traffic service request failed' });
    }

    const data = await response.json();
    const responseData =
      data && typeof data === 'object' && data.data && typeof data.data === 'object'
        ? data.data
        : data && typeof data === 'object'
            ? data
            : { data };
    trafficCache.set(cacheKey, {
      data: responseData,
      expiresAt: Date.now() + CACHE_TTL_MS,
    });
    return res.json(responseData);
  } catch (error) {
    return next(error);
  }
}

module.exports = { getTraffic };
