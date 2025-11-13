import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';

import '../controller/map_controller.dart' as app;
import '../../data/models/vet_place.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final app.MapController c;
  final fmap.MapController _mapCtrl = fmap.MapController();

  @override
  void initState() {
    super.initState();
    c = app.MapController();
    c.addListener(_onChange);
    c.refresh();
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    c.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mi ubicación (si existe)
    final meMarker = c.me == null
        ? <fmap.Marker>[]
        : [
            fmap.Marker(
              point: c.me!,
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

    // Marcadores de veterinarias (bonitos)
    final vetMarkers = c.vets.map((VetPlace v) {
      return fmap.Marker(
        point: LatLng(v.lat, v.lon),
        width: 48,
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await c.buildRouteTo(v);
              if (c.route.isNotEmpty) {
                final b = fmap.LatLngBounds.fromPoints([
                  c.cityCenter,
                  ...c.route,
                  LatLng(v.lat, v.lon),
                ]);
                _mapCtrl.fitCamera(
                  fmap.CameraFit.bounds(
                    bounds: b,
                    padding: const EdgeInsets.all(48),
                  ),
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo calcular la ruta')),
                );
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // pin
                const Icon(
                  Icons.location_on_rounded,
                  size: 44,
                  color: Color(0xFFE53935),
                ),
                // ícono
                const Icon(Icons.pets, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa — Pasto, Nariño'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: c.loading ? null : c.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa OSM
          fmap.FlutterMap(
            mapController: _mapCtrl,
            options: fmap.MapOptions(
              initialCenter: app.MapController.kPastoCenter,
              initialZoom: 13,
              interactionOptions: const fmap.InteractionOptions(
                flags: ~fmap.InteractiveFlag.rotate,
              ),
            ),
            children: [
              fmap.TileLayer(
                // sin subdominios (menos warnings en web)
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pets.app',
                retinaMode: true,
                minZoom: 3,
                maxZoom: 19,
              ),
              // Ruta dibujada (si existe)
              fmap.PolylineLayer(
                polylines: [
                  if (c.route.isNotEmpty)
                    fmap.Polyline(
                      points: c.route,
                      strokeWidth: 6,
                      color: c.routeMode == 'walking'
                          ? Colors.teal
                          : Colors.blueAccent,
                    ),
                ],
              ),
              // Marcadores
              fmap.MarkerLayer(markers: [...meMarker, ...vetMarkers]),
            ],
          ),

          // Cargando
          if (c.loading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Panel inferior: limpio, sin filtros extras
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.22,
                minChildSize: 0.18,
                maxChildSize: 0.64,
                builder: (context, scrollController) {
                  return Material(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    elevation: 6,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      children: [
                        // handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Controles mínimos
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'driving',
                                    label: Text('Rápida'),
                                  ),
                                  ButtonSegment(
                                    value: 'walking',
                                    label: Text('Segura'),
                                  ),
                                ],
                                selected: {c.routeMode},
                                onSelectionChanged: (s) =>
                                    c.setRouteMode(s.first),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Centrar Pasto',
                              onPressed: () => _mapCtrl.move(
                                app.MapController.kPastoCenter,
                                14,
                              ),
                              icon: const Icon(Icons.center_focus_strong),
                            ),
                            const SizedBox(width: 6),
                            if (c.me != null)
                              IconButton.filled(
                                tooltip: 'Mi ubicación',
                                onPressed: () => _mapCtrl.move(c.me!, 15),
                                icon: const Icon(Icons.my_location),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'Veterinarias en Pasto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),

                        if (c.vets.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Center(
                              child: Text('Cargando o sin resultados…'),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: c.vets.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final v = c.vets[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFFE53935,
                                  ).withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.pets,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                title: Text(
                                  v.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: v.openingHours == null
                                    ? const Text('Veterinaria')
                                    : Text(v.openingHours!, maxLines: 2),
                                trailing: FilledButton(
                                  onPressed: () async {
                                    await c.buildRouteTo(v);
                                    if (c.route.isNotEmpty) {
                                      _mapCtrl.fitCamera(
                                        fmap.CameraFit.bounds(
                                          bounds: fmap.LatLngBounds.fromPoints([
                                            c.cityCenter,
                                            ...c.route,
                                            LatLng(v.lat, v.lon),
                                          ]),
                                          padding: const EdgeInsets.all(48),
                                        ),
                                      );
                                    } else {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No se pudo calcular la ruta',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Ir'),
                                ),
                                onTap: () =>
                                    _mapCtrl.move(LatLng(v.lat, v.lon), 16),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
