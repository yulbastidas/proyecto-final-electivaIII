import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  bool _loading = true;
  String? _errorMsg;

  final List<Map<String, dynamic>> _veterinarias = [
    {
      'nombre': 'Veterinaria Pet Life',
      'direccion': 'Cl. 18 #25-40, Pasto, Nariño',
      'pos': LatLng(1.2086, -77.2772),
    },
    {
      'nombre': 'Clínica Veterinaria Animal Center',
      'direccion': 'Cra. 26 #15-32, Pasto',
      'pos': LatLng(1.2098, -77.2811),
    },
    {
      'nombre': 'Veterinaria San Francisco',
      'direccion': 'Cl. 17 #22-18, Pasto',
      'pos': LatLng(1.2107, -77.2765),
    },
    {
      'nombre': 'Mi Mascota Veterinaria',
      'direccion': 'Cra. 27 #14-45, Pasto',
      'pos': LatLng(1.2135, -77.2849),
    },
    {
      'nombre': 'Clínica Veterinaria Arca de Noé',
      'direccion': 'Cl. 19 #22-15, Pasto',
      'pos': LatLng(1.2119, -77.2788),
    },
  ];

  int _selectedMarkerIndex = -1;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _loading = true;
        _errorMsg = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMsg = 'Activa la ubicación en tu dispositivo.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMsg = 'Se necesita permiso de ubicación.';
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = 'Permiso de ubicación denegado permanentemente.';
          _loading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error obteniendo ubicación: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Veterinarias cercanas 🐾'),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : _errorMsg != null
          ? Center(
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : _currentPosition == null
          ? const Center(
              child: Text(
                "Ubicación no disponible",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        // Tu ubicación
                        Marker(
                          point: _currentPosition!,
                          width: 70,
                          height: 70,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blueAccent,
                            size: 36,
                          ),
                        ),
                        // Veterinarias
                        for (int i = 0; i < _veterinarias.length; i++)
                          Marker(
                            point: _veterinarias[i]['pos'],
                            width: 80,
                            height: 80,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedMarkerIndex = i),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.redAccent,
                                size: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Popup bonito
                if (_selectedMarkerIndex != -1)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _veterinarias[_selectedMarkerIndex]['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _veterinarias[_selectedMarkerIndex]['direccion'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    setState(() => _selectedMarkerIndex = -1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text("Cerrar"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getCurrentLocation,
        icon: const Icon(Icons.refresh),
        label: const Text("Actualizar"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }
}
