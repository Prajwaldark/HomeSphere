import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class NearbyServicesResult {
  const NearbyServicesResult({
    required this.providers,
    required this.message,
  });

  final List<ServiceProvider> providers;
  final String message;
}

class NearbyServiceDiscovery {
  NearbyServiceDiscovery({http.Client? client})
      : _client = client ?? http.Client();

  static const String _defaultApiUrl =
      'https://home-sphere-indol.vercel.app/api/nearby-services';
  static const String _configuredApiUrl = String.fromEnvironment(
    'NEARBY_SERVICES_API_URL',
    defaultValue: _defaultApiUrl,
  );

  final http.Client _client;

  String get _apiUrl => _configuredApiUrl;

  Future<NearbyServicesResult> fetchNearbyProviders({
    required double latitude,
    required double longitude,
    required String category,
    double radiusKm = 15,
  }) async {
    final response = await _client.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'radiusKm': radiusKm,
      }),
    );

    final decoded = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error']?.toString() ??
            'Nearby services request failed with status code ${response.statusCode}.',
      );
    }

    final rawProviders = decoded['providers'];
    final providers = <ServiceProvider>[];
    if (rawProviders is List) {
      for (final item in rawProviders) {
        if (item is Map<String, dynamic>) {
          providers.add(
            ServiceProvider.fromMap(item, item['placeId']?.toString() ?? ''),
          );
        }
      }
    }

    return NearbyServicesResult(
      providers: providers,
      message: decoded['message']?.toString() ??
          'Found ${providers.length} nearby providers.',
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
}
