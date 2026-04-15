import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DetectedVehicleDetails {
  const DetectedVehicleDetails({
    required this.name,
    required this.brand,
    required this.model,
    required this.regNumber,
    this.message,
  });

  const DetectedVehicleDetails.empty({this.message})
      : name = '',
        brand = '',
        model = '',
        regNumber = '';

  final String name;
  final String brand;
  final String model;
  final String regNumber;
  final String? message;
}

class VehicleVisionService {
  VehicleVisionService({http.Client? client})
      : _client = client ?? http.Client();

  static const String _defaultApiUrl =
      'https://home-sphere-indol.vercel.app/api/vehicle-detect';
  static const String _configuredApiUrl = String.fromEnvironment(
    'VEHICLE_VISION_API_URL',
    defaultValue: _defaultApiUrl,
  );

  final http.Client _client;

  bool get isConfigured => _configuredApiUrl.isNotEmpty;

  String get _apiUrl => _configuredApiUrl;

  Future<DetectedVehicleDetails> analyzeImage(XFile image) async {
    if (!isConfigured) {
      throw Exception(
        'The vehicle analysis backend URL is not configured. '
        'Deploy the backend and run Flutter with '
        '--dart-define=VEHICLE_VISION_API_URL=https://your-domain/api/vehicle-detect',
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
        'Could not reach the vehicle analysis backend at $_apiUrl. '
        'Check that the deployed API is online and reachable.\n\n$error',
      );
    }

    final body = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404) {
        throw Exception(
          'Vehicle detection endpoint was not found at $_apiUrl. '
          'Make sure api/vehicle-detect.mjs is deployed on the backend, '
          'then redeploy the app with the correct VEHICLE_VISION_API_URL.',
        );
      }

      throw Exception(
        body['error']?.toString() ??
            'Backend request failed with status code ${response.statusCode}.',
      );
    }

    return DetectedVehicleDetails(
      name: body['name']?.toString() ?? '',
      brand: body['brand']?.toString() ?? '',
      model: body['model']?.toString() ?? '',
      regNumber: body['regNumber']?.toString() ?? '',
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
