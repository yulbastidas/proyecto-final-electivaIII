import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  final http.Client _client;
  RoutingService([http.Client? client]) : _client = client ?? http.Client();

  /// profile: 'driving' (rápida) | 'walking' (segura)
  Future<({List<LatLng> path, double distanceM, double durationS})> route({
    required String profile,
    required LatLng from,
    required LatLng to,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await _client.get(url);
      if (res.statusCode != 200) {
        return (path: <LatLng>[], distanceM: 0.0, durationS: 0.0);
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final routes = (data['routes'] as List);
      if (routes.isEmpty) {
        return (path: <LatLng>[], distanceM: 0.0, durationS: 0.0);
      }
      final r = routes.first;
      final coords = (r['geometry']['coordinates'] as List)
          .map<LatLng>(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();

      return (
        path: coords,
        distanceM: (r['distance'] as num).toDouble(),
        durationS: (r['duration'] as num).toDouble(),
      );
    } catch (_) {
      return (path: <LatLng>[], distanceM: 0.0, durationS: 0.0);
    }
  }
}
