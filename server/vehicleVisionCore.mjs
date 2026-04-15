export async function detectVehicle({
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

  const prompt = `You are an assistant that analyzes photographs of vehicles (cars, bikes, scooters, etc.) to help users fill a vehicle registration form.
You will receive a compressed, lower-resolution photo of a vehicle taken with a mobile camera.

Your task is to:
1. Identify the vehicle type (e.g., Car, Motorcycle, Scooter).
2. Read any visible brand name, model name, and registration number (license plate).
3. Describe key visible features if present.

Respond **only** in the following strict JSON-like text format (no extra text, no markdown):

Vehicle type: <one line>
Brand: <brand if visible, else "not clearly visible">
Model: <model if visible, else "not clearly visible">
Registration number: <registration number if visible, else "not clearly visible">
Other visible labels: 
  - <label line 1>
  - <label line 2>
  - ...
Notes: <1–2 short sentences if anything is ambiguous or unclear>

Do not change the structure or add any extra explanation.`;

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
              text: 'You identify vehicles from photos and return concise structured text.',
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
          responseMimeType: 'text/plain',
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
  const parsed = parseVehicleText(content);

  const brand = cleanValue(parsed.brand);
  const model = cleanValue(parsed.model);
  const name = [brand, model].filter(Boolean).join(' ').trim() || parsed.vehicleType;

  return {
    name,
    brand,
    model,
    regNumber: parsed.regNumber,
    otherLabels: parsed.otherLabels,
    notes: parsed.notes,
    message: [
      parsed.otherLabels.length ? `Labels: ${parsed.otherLabels.join(', ')}` : '',
      parsed.notes ? `Notes: ${parsed.notes}` : ''
    ].filter(Boolean).join('\n') || undefined,
  };
}

export function parseVehicleText(text) {
  const result = {
    vehicleType: '',
    brand: '',
    model: '',
    regNumber: '',
    otherLabels: [],
    notes: ''
  };

  const lines = text.split('\n');
  let currentKey = null;

  for (let line of lines) {
    let trimmed = line.trim();
    if (trimmed.startsWith('Vehicle type:')) {
      result.vehicleType = trimmed.substring('Vehicle type:'.length).trim();
      currentKey = null;
    } else if (trimmed.startsWith('Brand:')) {
      result.brand = trimmed.substring('Brand:'.length).trim();
      currentKey = null;
    } else if (trimmed.startsWith('Model:')) {
      result.model = trimmed.substring('Model:'.length).trim();
      currentKey = null;
    } else if (trimmed.startsWith('Registration number:')) {
      result.regNumber = trimmed.substring('Registration number:'.length).trim();
      currentKey = null;
    } else if (trimmed.startsWith('Other visible labels:')) {
      currentKey = 'otherLabels';
      const inlineVal = trimmed.substring('Other visible labels:'.length).trim();
      if (inlineVal) result.otherLabels.push(inlineVal.replace(/^- /, '').trim());
    } else if (trimmed.startsWith('Notes:')) {
      result.notes = trimmed.substring('Notes:'.length).trim();
      currentKey = 'notes';
    } else if (currentKey === 'otherLabels' && trimmed.startsWith('-')) {
      result.otherLabels.push(trimmed.substring(1).trim());
    } else if (currentKey === 'notes' && trimmed.length > 0) {
      result.notes += ' ' + trimmed;
    }
  }

  const clean = (val) => val.toLowerCase().includes('not clearly visible') ? '' : val;
  result.brand = clean(result.brand);
  result.model = clean(result.model);
  result.regNumber = clean(result.regNumber);

  return result;
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
