import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/location_service.dart';

class MapController extends ChangeNotifier {
  final _loc = LocationService();
  LatLng? me;

  Future<void> refresh() async {
    final p = await _loc.current();
    if (p != null) {
      me = LatLng(p.latitude, p.longitude);
      notifyListeners();
    }
  }
}
