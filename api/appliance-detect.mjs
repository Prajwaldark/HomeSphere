import { detectAppliance, parseJson } from '../server/applianceVisionCore.mjs';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_BASE_URL =
  process.env.GEMINI_BASE_URL ||
  'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_VISION_MODEL =
  process.env.GEMINI_VISION_MODEL || 'gemini-2.5-flash';

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

  if (!GEMINI_API_KEY) {
    res.status(500).json({
      error:
        'Gemini is not configured on the backend. Add GEMINI_API_KEY in the deployment environment.',
    });
    return;
  }

  try {
    const body = normalizeBody(req.body);
    const imageBase64 =
      typeof body.imageBase64 === 'string' ? body.imageBase64 : '';
    const mimeType =
      typeof body.mimeType === 'string' ? body.mimeType : 'image/jpeg';

    if (!imageBase64) {
      res.status(400).json({ error: 'imageBase64 is required.' });
      return;
    }

    const detection = await detectAppliance({
      imageBase64,
      mimeType,
      geminiApiKey: GEMINI_API_KEY,
      geminiBaseUrl: GEMINI_BASE_URL,
      geminiVisionModel: GEMINI_VISION_MODEL,
    });

    res.status(200).json(detection);
  } catch (error) {
    res.status(500).json({
      error: error instanceof Error ? error.message : 'Unexpected backend error.',
    });
  }
}

function normalizeBody(body) {
  if (body && typeof body === 'object') {
    return body;
  }

  if (typeof body === 'string') {
    return parseJson(body) || {};
  }

  return {};
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}
