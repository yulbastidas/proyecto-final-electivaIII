import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/location_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final loc = LocationService();
  LatLng? me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await loc.current();
    if (p != null) setState(() => me = LatLng(p.latitude, p.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final center = me ?? LatLng(4.7110, -74.0721); // Bogotá por defecto
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(center: center, zoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.pets',
            ),
            if (me != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: me!,
                    width: 40,
                    height: 40,
                    builder: (_) =>
                        const Icon(Icons.my_location, color: Colors.red),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Ubicación'),
          ),
        ),
      ],
    );
  }
}
