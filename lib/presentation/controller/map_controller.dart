import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/location_service.dart';
import '../../data/services/vet_places_service.dart';
import '../../data/services/routing_service.dart';
import '../../data/models/vet_place.dart';

class MapController extends ChangeNotifier {
  MapController({
    VetPlacesService? vetsService,
    RoutingService? routing,
    LocationService? locationService,
  }) : _vetsSvc = vetsService ?? VetPlacesService(),
       _routing = routing ?? RoutingService(),
       _locationSvc = locationService ?? LocationService();

  static const LatLng kPastoCenter = LatLng(1.2136, -77.2811);

  final LocationService _locationSvc;
  final VetPlacesService _vetsSvc;
  final RoutingService _routing;

  LatLng cityCenter = kPastoCenter;
  LatLng? userLocation;
  bool isLoading = false;

  List<VetPlace> veterinaries = [];
  VetPlace? selectedVet;
  List<LatLng> routePath = [];
  double? distanceKm;
  int? durationMin;
  String routeMode = 'driving';

  /// Carga veterinarias y ubicación del usuario.
  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      await _loadVeterinaries();
      await _loadUserLocation();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVeterinaries() async {
    veterinaries = await _vetsSvc.fetchPasto();
  }

  Future<void> _loadUserLocation() async {
    final position = await _locationSvc.getCurrentPosition();
    userLocation = position != null
        ? LatLng(position.latitude, position.longitude)
        : null;
  }

  /// Calcula y dibuja la ruta hacia una veterinaria.
  Future<void> navigateToVet(VetPlace vet) async {
    final origin = userLocation ?? cityCenter;

    isLoading = true;
    notifyListeners();

    try {
      final result = await _routing.route(
        profile: routeMode,
        from: origin,
        to: LatLng(vet.lat, vet.lon),
      );

      routePath = result.path;
      selectedVet = vet;

      if (result.distanceM > 0) {
        distanceKm = result.distanceM / 1000;
        durationMin = (result.durationS / 60).round();
      } else {
        distanceKm = null;
        durationMin = null;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia la ruta actual.
  void clearRoute() {
    routePath = [];
    selectedVet = null;
    distanceKm = null;
    durationMin = null;
    notifyListeners();
  }

  /// Cambia el modo de transporte y recalcula la ruta.
  Future<void> changeRouteMode(String mode) async {
    if (mode == routeMode) return;

    routeMode = mode;
    notifyListeners();

    if (selectedVet != null) {
      await navigateToVet(selectedVet!);
    }
  }

  @override
  void dispose() {
    _vetsSvc.dispose();
    _routing.dispose();
    super.dispose();
  }
}
