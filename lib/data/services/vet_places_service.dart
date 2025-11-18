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

  static final Map<String, _CacheEntry> _cache = {};
  static const LatLng kPastoCenter = LatLng(1.2136, -77.2811);

  Future<List<VetPlace>> fetchPasto() async {
    const key = 'pasto_vets_v1';
    final cached = _cache[key];

    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

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
    if (data == null) return cached?.data ?? [];

    final elements = (data['elements'] as List?) ?? [];
    final vets = elements.map<VetPlace>(_parseElement).toList();

    _sortByDistance(vets);
    _cache[key] = _CacheEntry(data: vets);

    return vets;
  }

  VetPlace _parseElement(dynamic e) {
    final tags = (e['tags'] as Map?) ?? {};
    final name = (tags['name'] ?? 'Veterinaria').toString();
    final opening = tags['opening_hours']?.toString();

    double lat, lon;

    if (e['type'] == 'node') {
      lat = (e['lat'] as num).toDouble();
      lon = (e['lon'] as num).toDouble();
    } else {
      final center = e['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num).toDouble();
      lon = (center['lon'] as num).toDouble();
    }

    return VetPlace(
      id: '${e['type']}-${e['id']}',
      name: name,
      lat: lat,
      lon: lon,
      openingHours: opening,
    );
  }

  void _sortByDistance(List<VetPlace> list) {
    const d = Distance();
    list.sort((a, b) {
      final da = d(LatLng(a.lat, a.lon), kPastoCenter);
      final db = d(LatLng(b.lat, b.lon), kPastoCenter);
      return da.compareTo(db);
    });
  }

  Future<Map<String, dynamic>?> _callOverpass(String query) async {
    final r = Random();
    final start = r.nextInt(_endpoints.length);

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
                  'User-Agent': 'pets-student-app/1.0',
                },
                body: {'data': query},
              )
              .timeout(const Duration(seconds: 25));

          if (res.statusCode == 200) {
            return json.decode(utf8.decode(res.bodyBytes))
                as Map<String, dynamic>;
          }

          if (res.statusCode == 429 || res.statusCode >= 500) {
            await _backoff(attempt);
            continue;
          }

          break;
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return null;
  }

  Future<void> _backoff(int attempt) async {
    final base = (1 << attempt) * 400;
    final jitter = Random().nextInt(250);
    await Future.delayed(Duration(milliseconds: base + jitter));
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
