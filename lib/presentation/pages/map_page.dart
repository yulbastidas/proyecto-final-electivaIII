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

    // Marcadores de veterinarias
    final vetMarkers = c.filteredVets.map((VetPlace v) {
      final open = v.is247 || v.isOpenNow(DateTime.now());
      return fmap.Marker(
        point: LatLng(v.lat, v.lon),
        width: 46,
        height: 46,
        child: InkWell(
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
              if (!context.mounted) return; // ✅ context.mounted
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo calcular la ruta')),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 42,
                color: open ? Colors.green : Colors.red,
              ),
              const Icon(Icons.pets, size: 16, color: Colors.white),
            ],
          ),
        ),
      );
    }).toList();

    // Círculo del radio de búsqueda (centrado en Pasto)
    final radiusCircle = fmap.CircleLayer(
      circles: [
        fmap.CircleMarker(
          point: c.cityCenter,
          useRadiusInMeter: true,
          radius: c.radiusMeters.toDouble(),
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderStrokeWidth: 1.5,
          borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ],
    );

    final hasRoute =
        c.route.isNotEmpty &&
        c.lastDistanceKm != null &&
        c.lastDurationMin != null;

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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pets.app',
                retinaMode: true,
                minZoom: 3,
                maxZoom: 19,
              ),
              radiusCircle,
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
              fmap.MarkerLayer(markers: [...meMarker, ...vetMarkers]),
              fmap.MarkerLayer(
                markers: [
                  fmap.Marker(
                    point: app.MapController.kPastoCenter,
                    width: 16,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepPurple, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (c.loading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          if (hasRoute)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      '${c.lastDistanceKm!.toStringAsFixed(1)} km • ${c.lastDurationMin} min — ${c.routeMode == 'walking' ? 'Segura (a pie)' : 'Rápida (carro)'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Panel inferior (scrollable)
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.22,
                minChildSize: 0.18,
                maxChildSize: 0.64,
                builder: (context, scrollController) {
                  final theme = Theme.of(context);
                  return Material(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    elevation: 4,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      children: [
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

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilterChip(
                              label: const Text('Abiertas ahora'),
                              selected: c.openNowOnly,
                              onSelected: (v) =>
                                  c.setOpenNow(v), // ✅ ahora existe
                            ),
                            SegmentedButton<String>(
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Centrar Pasto',
                                  onPressed: () => _mapCtrl.move(
                                    app.MapController.kPastoCenter,
                                    14,
                                  ),
                                  icon: const Icon(Icons.map),
                                ),
                                if (c.me != null)
                                  IconButton(
                                    tooltip: 'Mi ubicación',
                                    onPressed: () => _mapCtrl.move(c.me!, 15),
                                    icon: const Icon(Icons.my_location),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.radar),
                            Expanded(
                              child: Slider(
                                value: c.radiusMeters.toDouble(),
                                min: 3000,
                                max: 10000,
                                divisions: 7,
                                label:
                                    '${(c.radiusMeters / 1000).toStringAsFixed(1)} km',
                                onChanged: (v) => c.setRadius(v.round()),
                              ),
                            ),
                            Text(
                              '${(c.radiusMeters / 1000).toStringAsFixed(1)} km',
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        if (c.filteredVets.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No se encontraron veterinarias en Pasto con los filtros actuales.',
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: c.filteredVets.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final v = c.filteredVets[i];
                              final open =
                                  v.is247 || v.isOpenNow(DateTime.now());
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: open
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.pets,
                                    color: open ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  v.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  v.openingHours == null
                                      ? (open
                                            ? 'Abierta ahora'
                                            : 'Horario no disponible')
                                      : '${open ? 'Abierta' : 'Cerrada'} • ${v.openingHours}',
                                  maxLines: 2,
                                ),
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
                                      if (!context.mounted)
                                        return; // ✅ context.mounted
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
