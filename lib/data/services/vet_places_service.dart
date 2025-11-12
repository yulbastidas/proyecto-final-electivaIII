import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/vet_place.dart';

class VetPlacesService {
  final http.Client _client;
  VetPlacesService([http.Client? client]) : _client = client ?? http.Client();

  // Mirrors de Overpass
  static const _endpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  // Caché en memoria para no golpear Overpass si el usuario mueve poco el radio
  static final Map<String, ({DateTime at, List<VetPlace> data})> _cache = {};

  Future<List<VetPlace>> fetchNearby({
    required double lat,
    required double lon,
    int radiusMeters = 6000,
  }) async {
    final key =
        '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)},$radiusMeters';
    final now = DateTime.now();
    final cached = _cache[key];
    if (cached != null &&
        now.difference(cached.at) < const Duration(minutes: 10)) {
      return cached.data;
    }

    final query =
        '''
      [out:json][timeout:25];
      (
        node["amenity"="veterinary"](around:$radiusMeters,$lat,$lon);
        way["amenity"="veterinary"](around:$radiusMeters,$lat,$lon);
        relation["amenity"="veterinary"](around:$radiusMeters,$lat,$lon);
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

      double la, lo;
      if (e['type'] == 'node') {
        la = (e['lat'] as num).toDouble();
        lo = (e['lon'] as num).toDouble();
      } else {
        la = (e['center']['lat'] as num).toDouble();
        lo = (e['center']['lon'] as num).toDouble();
      }

      return VetPlace(
        id: '${e['type']}-${e['id']}',
        name: name,
        lat: la,
        lon: lo,
        openingHours: oh,
      );
    }).toList();

    _cache[key] = (at: now, data: result);
    return result;
  }

  Future<Map<String, dynamic>?> _callOverpass(String query) async {
    // Empieza en un mirror aleatorio
    final start = DateTime.now().millisecondsSinceEpoch % _endpoints.length;

    for (int i = 0; i < _endpoints.length; i++) {
      final url = _endpoints[(start + i) % _endpoints.length];

      // hasta 3 intentos por mirror con backoff exponencial
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final res = await _client.post(
            Uri.parse(url),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              'Accept-Encoding': 'gzip',
              'User-Agent': 'pets-student-app/1.0 (OSM Overpass client)',
            },
            body: {'data': query},
          );

          if (res.statusCode == 200) {
            return json.decode(utf8.decode(res.bodyBytes))
                as Map<String, dynamic>;
          }

          // 429/5xx → backoff y reintento/mirror siguiente
          if (res.statusCode == 429 ||
              (res.statusCode >= 500 && res.statusCode < 600)) {
            final baseMs = (1 << attempt) * 400; // 400, 800, 1600
            final jitterMs = Random().nextInt(250); // 0..249
            await Future.delayed(Duration(milliseconds: baseMs + jitterMs));
            continue;
          }

          // otros códigos → prueba con el siguiente mirror
          break;
        } catch (_) {
          // error de red → intenta de nuevo/siguiente mirror
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return null;
  }
}
