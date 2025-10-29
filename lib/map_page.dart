// lib/map_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _map = MapController();

  // Centro inicial: Pasto aprox
  LatLng? _myPos = const LatLng(-1.2136, -77.2811);
  bool _loading = false;

  // Veterinarias (ejemplo fijo)
  final List<_Vet> _vets = const [
    _Vet('Vet. San Francisco', LatLng(-1.2096, -77.2829)),
    _Vet('Clínica Vet. La Merced', LatLng(-1.2129, -77.2778)),
    _Vet('Vet. El Bosque', LatLng(-1.2158, -77.2863)),
    _Vet('Centro Vet. Sur', LatLng(-1.2215, -77.2784)),
    _Vet('PetCare Pasto', LatLng(-1.2068, -77.2910)),
  ];

  // Ruta actual y vet seleccionada
  List<LatLng> _routePoints = [];
  _Vet? _selectedVet;

  @override
  void initState() {
    super.initState();
    _ensureLocation();
  }

  Future<void> _ensureLocation() async {
    setState(() => _loading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showSnack('Activa el GPS para centrar en tu ubicación.');
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        _showSnack('Permisos de ubicación denegados permanentemente.');
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _myPos = LatLng(pos.latitude, pos.longitude);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_myPos != null) _map.move(_myPos!, 15);
        });
      }
    } catch (_) {
      // usar centro por defecto
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _routeToVet(_Vet vet) async {
    if (_myPos == null) {
      _showSnack('No tengo tu ubicación todavía.');
      return;
    }

    setState(() {
      _loading = true;
      _selectedVet = vet;
      _routePoints = [];
    });

    // OSRM sin API key (a pie). Cambia 'foot' por 'driving' si quieres en carro.
    final src = '${_myPos!.longitude},${_myPos!.latitude}';
    final dst = '${vet.pos.longitude},${vet.pos.latitude}';
    final url =
        'https://router.project-osrm.org/route/v1/foot/$src;$dst?overview=full&geometries=geojson';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = (data['routes'][0]['geometry']['coordinates'] as List)
            .cast<List>()
            .map<LatLng>(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();

        setState(() => _routePoints = coords);

        final bounds = LatLngBounds.fromPoints([...coords, _myPos!, vet.pos]);
        _map.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
        );
      } else {
        _showSnack('No se pudo trazar la ruta (OSRM ${res.statusCode}).');
      }
    } catch (_) {
      _showSnack('Error de red al pedir la ruta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _selectedVet = null;
    });
    if (_myPos != null) {
      _map.move(_myPos!, 15);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final markers = <Marker>[
      if (_myPos != null)
        Marker(
          point: _myPos!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.person_pin_circle,
            size: 36,
            color: Colors.blue,
          ),
        ),
      ..._vets.map(
        (v) => Marker(
          point: v.pos,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _routeToVet(v),
            child: Tooltip(
              message: 'Ir a ${v.name}',
              child: const Icon(
                Icons.local_hospital,
                size: 36,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarias cercanas 🐾'),
        actions: [
          IconButton(
            tooltip: 'Mi ubicación',
            onPressed: _ensureLocation,
            icon: const Icon(Icons.my_location),
          ),
          if (_routePoints.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar ruta',
              onPressed: _clearRoute,
              icon: const Icon(Icons.clear_all),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _myPos ?? const LatLng(-1.2136, -77.2811),
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Capa base OSM
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.pets',
              ),

              // Ruta dibujada
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: theme.colorScheme.primary,
                      strokeWidth: 4,
                    ),
                  ],
                ),

              // Marcadores
              MarkerLayer(markers: markers),

              // 👇 Nuevo: atribución OSM correcta en flutter_map 7.x
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    // onTap opcional con url_launcher (puedes quitarlo si no usas url_launcher)
                    // onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          ),

          if (_selectedVet != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 18,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.local_hospital, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedVet!.name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _routeToVet(_selectedVet!),
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Ruta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ensureLocation,
        icon: const Icon(Icons.gps_fixed),
        label: const Text('Actualizar'),
      ),
    );
  }
}

class _Vet {
  final String name;
  final LatLng pos;
  const _Vet(this.name, this.pos);
}
