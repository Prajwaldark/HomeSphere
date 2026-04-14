export const CATEGORY_OPTIONS = [
  'Fan',
  'Refrigerator',
  'TV',
  'Washing Machine',
  'Air Conditioner',
  'Microwave',
  'Water Purifier',
  'Geyser',
  'Vacuum Cleaner',
  'Dishwasher',
  'Air Purifier',
  'Other',
];

export async function detectAppliance({
  imageBase64,
  mimeType,
  geminiApiKey,
  geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  geminiVisionModel = 'gemini-2.5-flash-lite',
  fetchImpl = fetch,
}) {
  if (!geminiApiKey) {
    throw new Error('GEMINI_API_KEY is missing on the backend.');
  }

  const prompt = [
    'Analyze this appliance photo and identify the most likely appliance.',
    '',
    'Return JSON only with these string fields:',
    '- appliance_name',
    '- brand',
    '- category',
    '- model',
    '',
    'Rules:',
    `- Allowed category values: ${CATEGORY_OPTIONS.join(', ')}.`,
    '- Choose exactly one allowed category. If uncertain, use Other.',
    '- appliance_name should be a short user-friendly label for the existing appliance form.',
    '- brand should be empty if not visible or not recognizable.',
    '- model should be empty if not visible or not readable.',
    '- Do not invent serial numbers or technical specs.',
  ].join('\n');

  const response = await fetchImpl(
    `${geminiBaseUrl}/models/${geminiVisionModel}:generateContent?key=${encodeURIComponent(
      geminiApiKey,
    )}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [
            {
              text: 'You identify home appliances from photos and return concise structured JSON.',
            },
          ],
        },
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
        },
      }),
    },
  );

  const responseText = await response.text();
  const responseBody = parseJson(responseText);

  if (!response.ok) {
    throw new Error(
      responseBody?.error?.message ||
          `Gemini request failed with status ${response.status}.`,
    );
  }

  const content = extractGeminiText(responseBody);
  const parsed = parseJson(extractJson(content));

  const category = normalizeCategory(String(parsed?.category || ''));
  const brand = cleanValue(parsed?.brand);
  const model = cleanValue(parsed?.model);
  const name = buildName({
    suggestedName: cleanValue(parsed?.appliance_name),
    brand,
    category,
    model,
  });

  return {
    name,
    brand,
    category,
    model,
  };
}

export function parseJson(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}

export function extractGeminiText(body) {
  const parts = body?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) {
    throw new Error('Gemini response did not include any candidates.');
  }

  const text = parts
    .map((part) => (typeof part?.text === 'string' ? part.text : ''))
    .join('')
    .trim();

  if (!text) {
    throw new Error('Gemini response did not include any text content.');
  }

  return text;
}

export function extractJson(content) {
  const start = content.indexOf('{');
  const end = content.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) {
    throw new Error('Gemini response was not valid JSON.');
  }
  return content.slice(start, end + 1);
}

export function normalizeCategory(value) {
  const normalized = value.trim().toLowerCase();
  if (!normalized) {
    return 'Other';
  }

  for (const option of CATEGORY_OPTIONS) {
    if (option.toLowerCase() === normalized) {
      return option;
    }
  }

  for (const option of CATEGORY_OPTIONS) {
    if (normalized.includes(option.toLowerCase())) {
      return option;
    }
  }

  return 'Other';
}

export function cleanValue(value) {
  const cleaned = String(value || '').trim();
  if (!cleaned) {
    return '';
  }

  const lower = cleaned.toLowerCase();
  if (lower === 'unknown' || lower === 'n/a' || lower === 'null') {
    return '';
  }

  return cleaned;
}

export function buildName({ suggestedName, brand, category, model }) {
  if (suggestedName) {
    return suggestedName;
  }

  return [brand, category !== 'Other' ? category : '', model]
      .filter(Boolean)
      .join(' ')
      .trim();
}
