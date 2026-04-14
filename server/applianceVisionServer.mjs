import { createServer } from 'node:http';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

import { detectAppliance, parseJson } from './applianceVisionCore.mjs';

loadEnvFile(join(process.cwd(), 'server', '.env'));

const PORT = Number(process.env.PORT || '8787');
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_BASE_URL =
  process.env.GEMINI_BASE_URL ||
  'https://generativelanguage.googleapis.com/v1beta';
const GEMINI_VISION_MODEL =
  process.env.GEMINI_VISION_MODEL || 'gemini-2.5-flash-lite';

const server = createServer(async (req, res) => {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    json(res, 200, {
      ok: true,
      configured: GEMINI_API_KEY.length > 0,
      model: GEMINI_VISION_MODEL,
    });
    return;
  }

  if (req.method === 'POST' && req.url === '/api/appliance-detect') {
    if (!GEMINI_API_KEY) {
      json(res, 500, {
        error:
          'Gemini is not configured on the backend. Add GEMINI_API_KEY to server/.env.',
      });
      return;
    }

    try {
      const body = await readJsonBody(req);
      const imageBase64 =
        typeof body.imageBase64 === 'string' ? body.imageBase64 : '';
      const mimeType =
        typeof body.mimeType === 'string' ? body.mimeType : 'image/jpeg';

      if (!imageBase64) {
        json(res, 400, { error: 'imageBase64 is required.' });
        return;
      }

      const detection = await detectAppliance({
        imageBase64,
        mimeType,
        geminiApiKey: GEMINI_API_KEY,
        geminiBaseUrl: GEMINI_BASE_URL,
        geminiVisionModel: GEMINI_VISION_MODEL,
      });

      json(res, 200, detection);
    } catch (error) {
      json(res, 500, {
        error: error instanceof Error ? error.message : 'Unexpected backend error.',
      });
    }
    return;
  }

  json(res, 404, { error: 'Not found.' });
});

server.listen(PORT, () => {
  console.log(`Appliance vision backend listening on http://localhost:${PORT}`);
});

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';

    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 12 * 1024 * 1024) {
        reject(new Error('Request body is too large.'));
        req.destroy();
      }
    });

    req.on('end', () => {
      const parsed = parseJson(raw);
      if (!parsed) {
        reject(new Error('Request body must be valid JSON.'));
        return;
      }
      resolve(parsed);
    });

    req.on('error', reject);
  });
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function json(res, statusCode, body) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
  });
  res.end(JSON.stringify(body));
}

function loadEnvFile(path) {
  if (!existsSync(path)) {
    return;
  }

  const content = readFileSync(path, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }

    const separator = trimmed.indexOf('=');
    if (separator === -1) {
      continue;
    }

    const key = trimmed.slice(0, separator).trim();
    const value = trimmed
      .slice(separator + 1)
      .trim()
      .replace(/^['"]|['"]$/g, '');
    if (key && !process.env[key]) {
      process.env[key] = value;
    }
  }
}
