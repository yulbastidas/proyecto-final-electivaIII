import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> current() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied)
      return null;
    return Geolocator.getCurrentPosition();
  }
}
