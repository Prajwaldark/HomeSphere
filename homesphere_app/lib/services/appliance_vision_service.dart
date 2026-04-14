import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DetectedApplianceDetails {
  const DetectedApplianceDetails({
    required this.name,
    required this.brand,
    required this.category,
    required this.model,
    this.message,
  });

  const DetectedApplianceDetails.empty({this.message})
      : name = '',
        brand = '',
        category = 'Other',
        model = '';

  final String name;
  final String brand;
  final String category;
  final String model;
  final String? message;
}

class ApplianceVisionService {
  ApplianceVisionService({http.Client? client})
      : _client = client ?? http.Client();

  static const String _defaultApiUrl =
      'https://home-sphere-indol.vercel.app/api/appliance-detect';
  static const String _configuredApiUrl = String.fromEnvironment(
    'APPLIANCE_VISION_API_URL',
    defaultValue: _defaultApiUrl,
  );

  final http.Client _client;

  bool get isConfigured => _configuredApiUrl.isNotEmpty;

  String get _apiUrl => _configuredApiUrl;

  Future<DetectedApplianceDetails> analyzeImage(XFile image) async {
    if (!isConfigured) {
      throw Exception(
        'The appliance analysis backend URL is not configured. '
        'Deploy the backend and run Flutter with '
        '--dart-define=APPLIANCE_VISION_API_URL=https://your-domain/api/appliance-detect',
      );
    }

    final bytes = await image.readAsBytes();
    final mimeType = _inferMimeType(image.path, bytes);

    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mimeType': mimeType,
          'imageBase64': base64Encode(bytes),
        }),
      );
    } catch (error) {
      throw Exception(
        'Could not reach the appliance analysis backend at $_apiUrl. '
        'Check that the deployed API is online and reachable.\n\n$error',
      );
    }

    final body = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['error']?.toString() ??
            'Backend request failed with status code ${response.statusCode}.',
      );
    }

    return DetectedApplianceDetails(
      name: body['name']?.toString() ?? '',
      brand: body['brand']?.toString() ?? '',
      category: body['category']?.toString() ?? 'Other',
      model: body['model']?.toString() ?? '',
      message: body['message']?.toString(),
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {'error': body};
  }

  String _inferMimeType(String path, Uint8List bytes) {
    final lowercasePath = path.toLowerCase();
    if (lowercasePath.endsWith('.png')) return 'image/png';
    if (lowercasePath.endsWith('.webp')) return 'image/webp';
    if (lowercasePath.endsWith('.heic')) return 'image/heic';
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }
}
