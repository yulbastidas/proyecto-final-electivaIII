import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';

import '../presentation/controller/map_controller.dart';
import '../data/models/vet_place.dart';

class MapBottomPanel extends StatelessWidget {
  final MapController controller;
  final fmap.MapController mapController;

  const MapBottomPanel({
    super.key,
    required this.controller,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.22,
          minChildSize: 0.18,
          maxChildSize: 0.64,
          builder: (_, scrollController) {
            return _BottomSheetContent(
              controller: controller,
              mapController: mapController,
              scrollController: scrollController,
            );
          },
        ),
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final MapController controller;
  final fmap.MapController mapController;
  final ScrollController scrollController;

  const _BottomSheetContent({
    required this.controller,
    required this.mapController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      elevation: 6,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        children: [
          const _DragHandle(),
          const SizedBox(height: 10),
          _ControlsRow(controller: controller, mapController: mapController),
          const SizedBox(height: 12),
          if (controller.routePath.isNotEmpty) ...[
            _RouteInfoCard(controller: controller),
            const SizedBox(height: 12),
          ],
          _SectionTitle(theme: theme),
          const SizedBox(height: 6),
          _VeterinaryList(controller: controller, mapController: mapController),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  final MapController controller;
  final fmap.MapController mapController;

  const _ControlsRow({required this.controller, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'driving', label: Text('Rápida')),
              ButtonSegment(value: 'walking', label: Text('Segura')),
            ],
            selected: {controller.routeMode},
            onSelectionChanged: (s) => controller.changeRouteMode(s.first),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => mapController.move(MapController.kPastoCenter, 14),
          icon: const Icon(Icons.center_focus_strong),
        ),
        const SizedBox(width: 6),
        if (controller.userLocation != null)
          IconButton.filled(
            onPressed: () => mapController.move(controller.userLocation!, 15),
            icon: const Icon(Icons.my_location),
          ),
      ],
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  final MapController controller;

  const _RouteInfoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.selectedVet?.name ?? 'Veterinaria',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (controller.distanceKm != null)
                  Text(
                    '${controller.distanceKm!.toStringAsFixed(2)} km • '
                    '${controller.durationMin} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.close, size: 20),
            onPressed: controller.clearRoute,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final ThemeData theme;

  const _SectionTitle({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Veterinarias en Pasto',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _VeterinaryList extends StatelessWidget {
  final MapController controller;
  final fmap.MapController mapController;

  const _VeterinaryList({
    required this.controller,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.veterinaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: Text('Cargando o sin resultados…')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.veterinaries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        return _VeterinaryTile(
          vet: controller.veterinaries[index],
          controller: controller,
          mapController: mapController,
        );
      },
    );
  }
}

class _VeterinaryTile extends StatelessWidget {
  final VetPlace vet;
  final MapController controller;
  final fmap.MapController mapController;

  const _VeterinaryTile({
    required this.vet,
    required this.controller,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.12),
        child: const Icon(Icons.pets, color: Color(0xFFE53935)),
      ),
      title: Text(vet.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: vet.openingHours == null
          ? const Text('Veterinaria')
          : Text(
              vet.openingHours!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: FilledButton(
        onPressed: () => _navigate(context),
        child: const Text('Ir'),
      ),
      onTap: () => mapController.move(LatLng(vet.lat, vet.lon), 16),
    );
  }

  Future<void> _navigate(BuildContext context) async {
    await controller.navigateToVet(vet);

    if (controller.routePath.isNotEmpty) {
      mapController.fitCamera(
        fmap.CameraFit.bounds(
          bounds: fmap.LatLngBounds.fromPoints([
            controller.cityCenter,
            ...controller.routePath,
            LatLng(vet.lat, vet.lon),
          ]),
          padding: const EdgeInsets.all(48),
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la ruta')),
      );
    }
  }
}
