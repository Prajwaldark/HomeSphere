const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY || '';
const GOOGLE_PLACES_BASE_URL =
  process.env.GOOGLE_PLACES_BASE_URL ||
  'https://maps.googleapis.com/maps/api/place';

const CATEGORY_QUERIES = {
  'Electrician': ['electrician'],
  'Plumber': ['plumber'],
  'Mechanic': ['car repair', 'auto repair', 'mechanic'],
  'AC Technician': ['hvac contractor', 'air conditioning repair', 'ac repair'],
};

export default async function handler(req, res) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed.' });
    return;
  }

  if (!GOOGLE_PLACES_API_KEY) {
    res.status(500).json({
      error:
        'Google Places is not configured on the backend. Add GOOGLE_PLACES_API_KEY in the deployment environment.',
    });
    return;
  }

  try {
    const body = normalizeBody(req.body);
    const latitude = Number(body.latitude);
    const longitude = Number(body.longitude);
    const category = normalizeCategory(body.category);
    const radiusKm = clampRadius(Number(body.radiusKm));

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      res.status(400).json({ error: 'latitude and longitude are required.' });
      return;
    }

    const providers = await searchNearbyProviders({
      latitude,
      longitude,
      category,
      radiusKm,
    });

    res.status(200).json({
      message:
        providers.length > 0
          ? `Found ${providers.length} nearby providers within ${radiusKm} km.`
          : `No providers found within ${radiusKm} km.`,
      providers,
    });
  } catch (error) {
    res.status(500).json({
      error: error instanceof Error ? error.message : 'Unexpected backend error.',
    });
  }
}

async function searchNearbyProviders({
  latitude,
  longitude,
  category,
  radiusKm,
}) {
  const queries = category === 'All' ? Object.values(CATEGORY_QUERIES).flat() : CATEGORY_QUERIES[category] || [category];
  const radiusMeters = Math.round(radiusKm * 1000);

  const searches = await Promise.all(
    queries.map((query) =>
      nearbySearch({
        latitude,
        longitude,
        radiusMeters,
        keyword: query,
      }),
    ),
  );

  const uniquePlaces = new Map();
  for (const searchResults of searches) {
    for (const place of searchResults) {
      if (!place.place_id || uniquePlaces.has(place.place_id)) continue;
      uniquePlaces.set(place.place_id, place);
    }
  }

  const detailed = await Promise.allSettled(
    Array.from(uniquePlaces.values())
      .slice(0, 18)
      .map((place) => fetchPlaceDetails(place, latitude, longitude)),
  );

  return detailed
    .filter((item) => item.status === 'fulfilled' && item.value.phone)
    .map((item) => item.value)
    .sort((a, b) => (a.distanceKm ?? 1e9) - (b.distanceKm ?? 1e9))
    .slice(0, 12);
}

async function nearbySearch({ latitude, longitude, radiusMeters, keyword }) {
  const url = new URL(`${GOOGLE_PLACES_BASE_URL}/nearbysearch/json`);
  url.searchParams.set('location', `${latitude},${longitude}`);
  url.searchParams.set('radius', String(radiusMeters));
  url.searchParams.set('keyword', keyword);
  url.searchParams.set('key', GOOGLE_PLACES_API_KEY);
  url.searchParams.set('language', 'en');

  const response = await fetch(url);
  const body = await response.json();

  if (!response.ok || body.status === 'REQUEST_DENIED') {
    throw new Error(
      body.error_message ||
        `Places nearby search failed for "${keyword}" with status ${body.status || response.status}.`,
    );
  }

  if (body.status === 'ZERO_RESULTS') {
    return [];
  }

  return Array.isArray(body.results) ? body.results : [];
}

async function fetchPlaceDetails(place, originLat, originLng) {
  const url = new URL(`${GOOGLE_PLACES_BASE_URL}/details/json`);
  url.searchParams.set('place_id', place.place_id);
  url.searchParams.set(
    'fields',
    'name,formatted_address,formatted_phone_number,rating,geometry,types,website',
  );
  url.searchParams.set('key', GOOGLE_PLACES_API_KEY);
  url.searchParams.set('language', 'en');

  const response = await fetch(url);
  const body = await response.json();

  if (!response.ok || body.status === 'REQUEST_DENIED') {
    throw new Error(
      body.error_message ||
        `Places details failed for "${place.place_id}" with status ${body.status || response.status}.`,
    );
  }

  const details = body.result || {};
  const location = details.geometry?.location || place.geometry?.location;
  const distanceKm = location
    ? haversineKm(originLat, originLng, location.lat, location.lng)
    : null;

  return {
    placeId: place.place_id,
    name: details.name || place.name || 'Unknown provider',
    category: inferCategory(details.types || place.types || []),
    rating: Number(details.rating || place.rating || 0),
    phone: details.formatted_phone_number || '',
    location: details.formatted_address || place.vicinity || '',
    distanceKm: distanceKm != null ? Number(distanceKm.toFixed(1)) : null,
    source: 'google_places',
  };
}

function inferCategory(types) {
  const normalized = new Set((types || []).map((type) => String(type).toLowerCase()));
  if (normalized.has('electrician')) return 'Electrician';
  if (normalized.has('plumber')) return 'Plumber';
  if (normalized.has('car_repair') || normalized.has('auto_repair')) return 'Mechanic';
  if (normalized.has('hvac_contractor')) return 'AC Technician';
  return 'Other';
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (value) => (value * Math.PI) / 180;
  const r = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function normalizeBody(body) {
  if (body && typeof body === 'object') return body;
  if (typeof body === 'string') {
    try {
      return JSON.parse(body);
    } catch (_) {
      return {};
    }
  }
  return {};
}

function normalizeCategory(value) {
  const category = String(value || 'All').trim();
  return Object.prototype.hasOwnProperty.call(CATEGORY_QUERIES, category) || category === 'All'
    ? category
    : 'All';
}

function clampRadius(value) {
  if (!Number.isFinite(value) || value <= 0) return 15;
  return Math.min(Math.max(value, 5), 20);
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}
