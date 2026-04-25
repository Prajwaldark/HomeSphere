import 'dart:convert';
import 'dart:math';

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

  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';

  final http.Client _client;

  // ── OSM tag queries per category ─────────────────────────────────────────
  static const Map<String, List<String>> _categoryQueries = {
    'Electrician': [
      '["shop"="electrician"]',
      '["craft"="electrician"]',
      '["trade"="electrical"]',
    ],
    'Plumber': [
      '["craft"="plumber"]',
      '["trade"="plumber"]',
      '["shop"="plumber"]',
    ],
    'Mechanic': [
      '["shop"="car_repair"]',
      '["shop"="motorcycle_repair"]',
      '["amenity"="car_wash"]',
      '["shop"="car"]',
    ],
    'AC Technician': [
      '["shop"="hvac"]',
      '["trade"="hvac"]',
      '["shop"="air_conditioning"]',
      '["craft"="hvac"]',
    ],
  };

  /// Build an Overpass QL query for the given location / category / radius.
  String _buildQuery({
    required double latitude,
    required double longitude,
    required String category,
    required double radiusMeters,
  }) {
    final tagFilters = <String>[];

    if (category == 'All') {
      for (final filters in _categoryQueries.values) {
        tagFilters.addAll(filters);
      }
    } else {
      tagFilters.addAll(
        _categoryQueries[category] ?? ['["shop"="${category.toLowerCase()}"]'],
      );
    }

    // Build union of nwr (node/way/relation) queries
    final buffer = StringBuffer();
    buffer.writeln('[out:json][timeout:25];');
    buffer.writeln('(');
    for (final filter in tagFilters) {
      buffer.writeln(
          '  nwr$filter(around:${radiusMeters.round()},$latitude,$longitude);');
    }
    buffer.writeln(');');
    buffer.writeln('out center tags;');

    return buffer.toString();
  }

  /// Fetch nearby service providers from the Overpass API.
  Future<NearbyServicesResult> fetchNearbyProviders({
    required double latitude,
    required double longitude,
    required String category,
    double radiusKm = 15,
  }) async {
    final radiusMeters = radiusKm * 1000;
    final query = _buildQuery(
      latitude: latitude,
      longitude: longitude,
      category: category,
      radiusMeters: radiusMeters,
    );

    final response = await _client.post(
      Uri.parse(_overpassUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: 'data=${Uri.encodeComponent(query)}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Overpass API request failed (status ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? [];

    final providers = <ServiceProvider>[];
    final seen = <String>{};

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name']?.toString() ?? '';
      if (name.isEmpty) continue;

      // Deduplicate by name
      if (seen.contains(name.toLowerCase())) continue;
      seen.add(name.toLowerCase());

      // Get coordinates (nodes have lat/lon, ways/relations have center)
      final double? lat = (el['lat'] as num?)?.toDouble() ??
          (el['center']?['lat'] as num?)?.toDouble();
      final double? lon = (el['lon'] as num?)?.toDouble() ??
          (el['center']?['lon'] as num?)?.toDouble();

      final distance = (lat != null && lon != null)
          ? _haversineKm(latitude, longitude, lat, lon)
          : null;

      // Extract phone
      final phone = tags['phone']?.toString() ??
          tags['contact:phone']?.toString() ??
          tags['contact:mobile']?.toString() ??
          '';

      // Build address
      final addr = _buildAddress(tags);

      // Determine category from tags
      final inferredCategory = _inferCategory(tags, category);

      providers.add(
        ServiceProvider(
          name: name,
          category: inferredCategory,
          rating: 0,
          phone: phone,
          location: addr.isNotEmpty ? addr : 'Location on map',
          distanceKm: distance != null
              ? double.parse(distance.toStringAsFixed(1))
              : null,
          source: 'overpass',
        ),
      );
    }

    // Sort by distance
    providers.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      return da.compareTo(db);
    });

    // Limit to top 15
    final result = providers.take(15).toList();

    return NearbyServicesResult(
      providers: result,
      message: result.isNotEmpty
          ? 'Found ${result.length} nearby providers within ${radiusKm.round()} km.'
          : 'No providers found within ${radiusKm.round()} km. Try increasing the radius or changing the category.',
    );
  }

  /// Build a human-readable address from OSM addr:* tags.
  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street']?.toString();
    final housenumber = tags['addr:housenumber']?.toString();
    final city = tags['addr:city']?.toString();
    final suburb = tags['addr:suburb']?.toString();
    final postcode = tags['addr:postcode']?.toString();

    if (housenumber != null && street != null) {
      parts.add('$housenumber $street');
    } else if (street != null) {
      parts.add(street);
    }
    if (suburb != null) parts.add(suburb);
    if (city != null) parts.add(city);
    if (postcode != null) parts.add(postcode);

    return parts.join(', ');
  }

  /// Infer the app category from OSM tags.
  String _inferCategory(Map<String, dynamic> tags, String requestedCategory) {
    if (requestedCategory != 'All' &&
        _categoryQueries.containsKey(requestedCategory)) {
      return requestedCategory;
    }

    final shop = tags['shop']?.toString().toLowerCase() ?? '';
    final craft = tags['craft']?.toString().toLowerCase() ?? '';
    final trade = tags['trade']?.toString().toLowerCase() ?? '';
    final amenity = tags['amenity']?.toString().toLowerCase() ?? '';

    if (shop == 'electrician' ||
        craft == 'electrician' ||
        trade == 'electrical') {
      return 'Electrician';
    }
    if (craft == 'plumber' || trade == 'plumber' || shop == 'plumber') {
      return 'Plumber';
    }
    if (shop == 'car_repair' ||
        shop == 'motorcycle_repair' ||
        amenity == 'car_wash') {
      return 'Mechanic';
    }
    if (shop == 'hvac' ||
        trade == 'hvac' ||
        shop == 'air_conditioning' ||
        craft == 'hvac') {
      return 'AC Technician';
    }
    return 'Other';
  }

  /// Haversine distance in km between two lat/lng points.
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
