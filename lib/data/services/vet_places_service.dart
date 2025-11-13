// lib/data/services/vet_places_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/vet_place.dart';

class VetPlacesService {
  final http.Client _client;
  VetPlacesService([http.Client? client]) : _client = client ?? http.Client();

  // Mirrors Overpass (sin .ru) + fallback
  static const _endpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
  ];

  // Caché en memoria (10 min)
  static final Map<String, ({DateTime at, List<VetPlace> data})> _cache = {};

  // Centro de Pasto
  static const LatLng kPastoCenter = LatLng(1.2136, -77.2811);

  /// Veterinarias dentro del BBOX de Pasto, Nariño
  Future<List<VetPlace>> fetchPasto() async {
    // bounding box aproximado: south, west, north, east
    const south = 1.1700, west = -77.3300, north = 1.2700, east = -77.2200;

    const cacheKey = 'pasto_vets_v1';
    final now = DateTime.now();
    final cached = _cache[cacheKey];
    if (cached != null &&
        now.difference(cached.at) < const Duration(minutes: 10)) {
      return cached.data;
    }

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
    if (data == null) return [];

    final elements = (data['elements'] as List?) ?? [];
    final result = elements.map<VetPlace>((e) {
      final tags = (e['tags'] as Map?) ?? {};
      final name = (tags['name'] ?? 'Veterinaria').toString();
      final oh = tags['opening_hours']?.toString();

      double lat, lon;
      if (e['type'] == 'node') {
        lat = (e['lat'] as num).toDouble();
        lon = (e['lon'] as num).toDouble();
      } else {
        lat = (e['center']['lat'] as num).toDouble();
        lon = (e['center']['lon'] as num).toDouble();
      }

      return VetPlace(
        id: '${e['type']}-${e['id']}',
        name: name,
        lat: lat,
        lon: lon,
        openingHours: oh,
      );
    }).toList();

    // Orden por cercanía al centro de Pasto
    final dist = const Distance();
    result.sort((a, b) {
      final da = dist(LatLng(a.lat, a.lon), kPastoCenter);
      final db = dist(LatLng(b.lat, b.lon), kPastoCenter);
      return da.compareTo(db);
    });

    _cache[cacheKey] = (at: now, data: result);
    return result;
  }

  // Llama Overpass con reintentos/backoff/timeout
  Future<Map<String, dynamic>?> _callOverpass(String query) async {
    final start = DateTime.now().millisecondsSinceEpoch % _endpoints.length;

    for (int i = 0; i < _endpoints.length; i++) {
      final url = _endpoints[(start + i) % _endpoints.length];

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final res = await _client
              .post(
                Uri.parse(url),
                headers: {
                  'Content-Type':
                      'application/x-www-form-urlencoded; charset=UTF-8',
                  'Accept-Encoding': 'gzip',
                  'User-Agent': 'pets-student-app/1.0 (OSM Overpass client)',
                },
                body: {'data': query},
              )
              .timeout(const Duration(seconds: 25)); // timeout duro

          if (res.statusCode == 200) {
            return json.decode(utf8.decode(res.bodyBytes))
                as Map<String, dynamic>;
          }

          // 429/5xx → backoff y reintento
          if (res.statusCode == 429 ||
              (res.statusCode >= 500 && res.statusCode < 600)) {
            final baseMs = (1 << attempt) * 400; // 400, 800, 1600
            final jitterMs = Random().nextInt(250);
            await Future.delayed(Duration(milliseconds: baseMs + jitterMs));
            continue;
          }

          break; // otros códigos → siguiente mirror
        } catch (_) {
          // error de red/timeout → intenta de nuevo/siguiente mirror
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return null;
  }
}
