import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> current() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      return null; // sin permiso → devolvemos null (la UI usa un fallback)
    }
    return Geolocator.getCurrentPosition();
  }
}
