const WAZE_URL = 'https://api.openwebninja.com/waze/alerts-and-jams';

async function fetchWazeTraffic({ bottomLeft, topRight, apiKey = process.env.WAZE_API_KEY }) {
  if (!apiKey) throw new Error('WAZE_API_KEY is not configured');

  const url = new URL(WAZE_URL);
  url.searchParams.set('bottom_left', bottomLeft);
  url.searchParams.set('top_right', topRight);

  const response = await fetch(url, {
    headers: { 'X-API-Key': apiKey },
  });

  if (!response.ok) {
    throw new Error(`Waze request failed with status ${response.status}`);
  }

  return response.json();
}

module.exports = { fetchWazeTraffic };
