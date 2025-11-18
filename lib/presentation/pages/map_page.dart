import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import '../controller/map_controller.dart';
import '../../widgets/map_bottom_panel.dart';
import '../../data/models/vet_place.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _controller;
  final fmap.MapController _mapController = fmap.MapController();

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa — Pasto, Nariño'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _controller.isLoading ? null : _controller.initialize,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              _MapView(controller: _controller, mapController: _mapController),
              if (_controller.isLoading) const _LoadingOverlay(),
              MapBottomPanel(
                controller: _controller,
                mapController: _mapController,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final MapController controller;
  final fmap.MapController mapController;

  const _MapView({required this.controller, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return fmap.FlutterMap(
      mapController: mapController,
      options: fmap.MapOptions(
        initialCenter: MapController.kPastoCenter,
        initialZoom: 13,
        interactionOptions: const fmap.InteractionOptions(
          flags: ~fmap.InteractiveFlag.rotate,
        ),
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pets.app',
          retinaMode: true,
          minZoom: 3,
          maxZoom: 19,
        ),
        if (controller.routePath.isNotEmpty)
          fmap.PolylineLayer(
            polylines: [
              fmap.Polyline(
                points: controller.routePath,
                strokeWidth: 6,
                color: controller.routeMode == 'walking'
                    ? Colors.teal
                    : Colors.blueAccent,
              ),
            ],
          ),
        fmap.MarkerLayer(
          markers: [..._buildUserMarker(), ..._buildVetMarkers(context)],
        ),
      ],
    );
  }

  List<fmap.Marker> _buildUserMarker() {
    if (controller.userLocation == null) return const [];

    return [
      fmap.Marker(
        point: controller.userLocation!,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.my_location, size: 22, color: Colors.blue),
          ),
        ),
      ),
    ];
  }

  List<fmap.Marker> _buildVetMarkers(BuildContext context) {
    return controller.veterinaries.map((vet) {
      return fmap.Marker(
        point: LatLng(vet.lat, vet.lon),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _onVetTap(context, vet),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 44,
                color: Color(0xFFE53935),
              ),
              Icon(Icons.pets, size: 16, color: Colors.white),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _onVetTap(BuildContext context, VetPlace vet) async {
    await controller.navigateToVet(vet);

    if (controller.routePath.isNotEmpty) {
      _fitRouteBounds(vet);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la ruta')),
      );
    }
  }

  void _fitRouteBounds(VetPlace vet) {
    final bounds = fmap.LatLngBounds.fromPoints([
      controller.cityCenter,
      ...controller.routePath,
      LatLng(vet.lat, vet.lon),
    ]);

    mapController.fitCamera(
      fmap.CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(child: Center(child: CircularProgressIndicator())),
    );
  }
}
