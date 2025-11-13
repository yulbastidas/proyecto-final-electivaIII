import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/location_service.dart';
import '../../data/services/vet_places_service.dart';
import '../../data/services/routing_service.dart';
import '../../data/models/vet_place.dart';

class MapController extends ChangeNotifier {
  MapController({VetPlacesService? vetsService, RoutingService? routing})
    : _vetsSvc = vetsService ?? VetPlacesService(),
      _routing = routing ?? RoutingService();

  static const LatLng kPastoCenter = LatLng(1.2136, -77.2811);

  final _loc = LocationService();
  final VetPlacesService _vetsSvc;
  final RoutingService _routing;

  LatLng cityCenter = kPastoCenter;
  LatLng? me;

  bool loading = false;

  List<VetPlace> vets = [];
  VetPlace? selected;
  List<LatLng> route = [];
  double? lastDistanceKm;
  int? lastDurationMin;

  String routeMode = 'driving'; // 'driving' | 'walking'

  List<VetPlace> get filteredVets => vets;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      cityCenter = kPastoCenter;
      await fetchVets();
      final p = await _loc.current();
      me = (p != null) ? LatLng(p.latitude, p.longitude) : null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // 🔹 Ahora siempre carga veterinarias de Pasto (OSM)
  Future<void> fetchVets() async {
    vets = await _vetsSvc.fetchPasto();
    notifyListeners();
  }

  Future<void> buildRouteTo(VetPlace v) async {
    final from = me ?? cityCenter;
    loading = true;
    notifyListeners();
    try {
      final res = await _routing.route(
        profile: routeMode,
        from: from,
        to: LatLng(v.lat, v.lon),
      );
      route = res.path;
      selected = v;
      if (res.distanceM > 0) {
        lastDistanceKm = (res.distanceM / 1000);
        lastDurationMin = (res.durationS / 60).round();
      } else {
        lastDistanceKm = null;
        lastDurationMin = null;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    route = [];
    lastDistanceKm = null;
    lastDurationMin = null;
    notifyListeners();
  }

  Future<void> setRouteMode(String m) async {
    routeMode = m;
    notifyListeners();
    if (selected != null) {
      await buildRouteTo(selected!);
    }
  }
}
