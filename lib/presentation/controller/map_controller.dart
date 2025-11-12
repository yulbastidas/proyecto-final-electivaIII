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
  bool openNowOnly = false;
  int radiusMeters = 6000;

  List<VetPlace> get filteredVets {
    if (!openNowOnly) return vets;
    final now = DateTime.now();
    return vets.where((v) => v.is247 || v.isOpenNow(now)).toList();
  }

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

  Future<void> fetchVets() async {
    vets = await _vetsSvc.fetchNearby(
      lat: cityCenter.latitude,
      lon: cityCenter.longitude,
      radiusMeters: radiusMeters,
    );
    final dist = const Distance();
    vets.sort((a, b) {
      final da = dist(LatLng(a.lat, a.lon), cityCenter);
      final db = dist(LatLng(b.lat, b.lon), cityCenter);
      return da.compareTo(db);
    });
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

  // ✅ método que faltaba
  void setOpenNow(bool value) {
    openNowOnly = value;
    notifyListeners();
  }

  // ✅ debounce para evitar 429 en Overpass
  Timer? _radiusDebounce;
  Future<void> setRadius(int meters) async {
    radiusMeters = meters;
    notifyListeners(); // actualiza etiqueta del slider

    _radiusDebounce?.cancel();
    _radiusDebounce = Timer(const Duration(milliseconds: 700), () async {
      await fetchVets();
    });
  }
}
