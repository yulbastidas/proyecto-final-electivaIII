import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  final http.Client _client;

  RoutingService([http.Client? client]) : _client = client ?? http.Client();

  /// Calcula una ruta entre dos puntos usando OSRM.
  /// [profile]: 'driving' (rápida) o 'walking' (segura)
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
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return (path: <LatLng>[], distanceM: 0.0, durationS: 0.0);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = (data['routes'] as List?) ?? [];

      if (routes.isEmpty) {
        return (path: <LatLng>[], distanceM: 0.0, durationS: 0.0);
      }

      final route = routes.first;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = (geometry['coordinates'] as List)
          .map<LatLng>(
            (coord) => LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            ),
          )
          .toList();

      return (
        path: coordinates,
        distanceM: (route['distance'] as num).toDouble(),
        durationS: (route['duration'] as num).toDouble(),
      );
    } catch (e) {
      return (path: <LatLng>[], distanceM: 0.0, durationS: 0.0);
    }
  }

  void dispose() {
    _client.close();
  }
}
