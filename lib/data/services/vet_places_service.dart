import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/vet_place.dart';

class VetPlacesService {
  final http.Client _client;

  VetPlacesService([http.Client? client]) : _client = client ?? http.Client();

  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
  ];

  // Caché en memoria (10 min)
  static final Map<String, _CacheEntry> _cache = {};
  static const LatLng kPastoCenter = LatLng(1.2136, -77.2811);

  /// Obtiene veterinarias en Pasto, Nariño.
  Future<List<VetPlace>> fetchPasto() async {
    const cacheKey = 'pasto_vets_v1';
    final cached = _cache[cacheKey];

    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    // BBOX aproximado de Pasto
    const south = 1.1700;
    const west = -77.3300;
    const north = 1.2700;
    const east = -77.2200;

    final query =
        '''
      [out:json][timeout:25];
      (
        node["amenity"="veterinary"]($south,$west,$north,$east);
        way["amenity"="veterinary"]($south,$west,$north,$east);
        relation["amenity"="veterinary"]($south,$west,$north,$east);
      );
      out center tags;
    ''';

    final data = await _callOverpass(query);
    if (data == null) {
      // Si falla, devolvemos caché expirado si existe
      return cached?.data ?? [];
    }

    final elements = (data['elements'] as List?) ?? [];
    final vets = elements.map<VetPlace>(_parseElement).toList();

    // Ordenar por cercanía al centro de Pasto
    _sortByDistance(vets);

    _cache[cacheKey] = _CacheEntry(data: vets);
    return vets;
  }

  VetPlace _parseElement(dynamic element) {
    final tags = (element['tags'] as Map?) ?? {};
    final name = (tags['name'] ?? 'Veterinaria').toString();
    final openingHours = tags['opening_hours']?.toString();

    late double lat, lon;

    if (element['type'] == 'node') {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    } else {
      final center = element['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num).toDouble();
      lon = (center['lon'] as num).toDouble();
    }

    return VetPlace(
      id: '${element['type']}-${element['id']}',
      name: name,
      lat: lat,
      lon: lon,
      openingHours: openingHours,
    );
  }

  void _sortByDistance(List<VetPlace> vets) {
    const distance = Distance();
    vets.sort((a, b) {
      final distA = distance(LatLng(a.lat, a.lon), kPastoCenter);
      final distB = distance(LatLng(b.lat, b.lon), kPastoCenter);
      return distA.compareTo(distB);
    });
  }

  Future<Map<String, dynamic>?> _callOverpass(String query) async {
    final random = Random();
    final startIndex = random.nextInt(_endpoints.length);

    for (int i = 0; i < _endpoints.length; i++) {
      final url = _endpoints[(startIndex + i) % _endpoints.length];

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final response = await _client
              .post(
                Uri.parse(url),
                headers: {
                  'Content-Type':
                      'application/x-www-form-urlencoded; charset=UTF-8',
                  'Accept-Encoding': 'gzip',
                  'User-Agent': 'pets-student-app/1.0',
                },
                body: {'data': query},
              )
              .timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) {
            return json.decode(utf8.decode(response.bodyBytes))
                as Map<String, dynamic>;
          }

          // Rate limit o error del servidor
          if (response.statusCode == 429 || response.statusCode >= 500) {
            await _backoff(attempt);
            continue;
          }

          break; // Otro error, probar siguiente endpoint
        } catch (e) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return null;
  }

  Future<void> _backoff(int attempt) async {
    final baseMs = (1 << attempt) * 400; // 400, 800, 1600
    final jitterMs = Random().nextInt(250);
    await Future.delayed(Duration(milliseconds: baseMs + jitterMs));
  }

  void dispose() {
    _client.close();
  }
}

class _CacheEntry {
  final DateTime timestamp;
  final List<VetPlace> data;

  _CacheEntry({required this.data}) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 10);
}
