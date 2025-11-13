import 'package:flutter/material.dart';

import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/health_event_entity.dart';
import '../controller/health_controller.dart';

class HealthLogPage extends StatefulWidget {
  final String petId;
  final HealthController controller;

  const HealthLogPage({
    super.key,
    required this.petId,
    required this.controller,
  });

  @override
  State<HealthLogPage> createState() => _HealthLogPageState();
}

class _HealthLogPageState extends State<HealthLogPage> {
  // PESO
  final _formWeightKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // EVENTO
  final _formEventKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  HealthType _selectedType = HealthType.vaccine;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.petId);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  // -------- PESO --------
  Future<void> _onSaveWeight() async {
    if (!_formWeightKey.currentState!.validate()) return;

    final text = _weightCtrl.text.trim().replaceAll(',', '.');
    final valueKg = double.tryParse(text);

    if (valueKg == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un número válido')));
      return;
    }

    await widget.controller.addWeight(
      petId: widget.petId,
      valueKg: valueKg,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    _weightCtrl.clear();
    _noteCtrl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Peso guardado')));
  }

  // -------- EVENTO --------
  Future<void> _onSaveEvent() async {
    if (!_formEventKey.currentState!.validate()) return;

    await widget.controller.addEvent(
      petId: widget.petId,
      type: _selectedType,
      title: _titleCtrl.text.trim(),
      happenedAt: _selectedDate,
      details: _detailsCtrl.text.trim().isEmpty
          ? null
          : _detailsCtrl.text.trim(),
    );

    if (!mounted) return;
    _titleCtrl.clear();
    _detailsCtrl.clear();
    _selectedType = HealthType.vaccine;
    _selectedDate = null;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento de salud guardado')));
    setState(() {});
  }

  // ---------- SOLO 3 TIPOS PERMITIDOS ----------
  String _typeLabel(HealthType t) {
    switch (t) {
      case HealthType.vaccine:
        return 'Vacuna';
      case HealthType.deworm:
        return 'Desparasitación';
      case HealthType.med:
        return 'Medicación';
    }
  }

  IconData _typeIcon(HealthType t) {
    switch (t) {
      case HealthType.vaccine:
        return Icons.vaccines;
      case HealthType.deworm:
        return Icons.bug_report;
      case HealthType.med:
        return Icons.medication;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final weights = ctrl.weights;
            final events = ctrl.events;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Bitácora de salud',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // ---------- FORM PESO ----------
                Card(
                  elevation: 0,
                  color: const Color(0xFFF5EAF5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formWeightKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Agregar peso',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim().replaceAll(',', '.');
                              final d = double.tryParse(t);
                              if (d == null) return 'Ingresa un número';
                              if (d <= 0) return 'Debe ser mayor que 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _noteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nota (opcional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _onSaveWeight,
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Historial de peso',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                if (weights.isEmpty)
                  const Text('Sin registros de peso.')
                else
                  ...weights.map(
                    (w) => _WeightTile(
                      weight: w,
                      onDelete: () async {
                        await ctrl.deleteWeight(petId: widget.petId, id: w.id);
                      },
                    ),
                  ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),

                // ---------- FORM EVENTO ----------
                Card(
                  elevation: 0,
                  color: const Color(0xFFE8F4FF),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formEventKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Agregar evento de salud',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),

                          // *** SOLO 3 TIPOS ***
                          DropdownButtonFormField<HealthType>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                            ),
                            items: HealthType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(_typeLabel(t)),
                                  ),
                                )
                                .toList(),
                            onChanged: (t) {
                              if (t == null) return;
                              setState(() => _selectedType = t);
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Título (ej: Vacuna rabia)',
                            ),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Campo obligatorio';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Fecha: hoy'
                                      : 'Fecha: ${_selectedDate!.toLocal().toString().split(' ').first}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 5),
                                    lastDate: DateTime(now.year + 1),
                                    initialDate: now,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                    });
                                  }
                                },
                                child: const Text('Cambiar fecha'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _detailsCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Detalles (opcional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _onSaveEvent,
                              child: const Text('Guardar evento'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Historial de eventos de salud',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                if (events.isEmpty)
                  const Text('Sin eventos de salud registrados.')
                else
                  ...events.map(
                    (e) => _EventTile(
                      event: e,
                      typeLabel: _typeLabel(e.type),
                      typeIcon: _typeIcon(e.type),
                      onDelete: () async {
                        await ctrl.deleteEvent(petId: widget.petId, id: e.id);
                      },
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeightTile extends StatelessWidget {
  final Weight weight;
  final VoidCallback onDelete;

  const _WeightTile({required this.weight, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${weight.valueKg.toStringAsFixed(2)} kg'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weight.notedAt.toLocal().toString().split('.').first,
              style: const TextStyle(fontSize: 12),
            ),
            if ((weight.notes ?? '').isNotEmpty)
              Text(weight.notes!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final HealthEvent event;
  final String typeLabel;
  final IconData typeIcon;
  final VoidCallback onDelete;

  const _EventTile({
    required this.event,
    required this.typeLabel,
    required this.typeIcon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(typeIcon),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$typeLabel · ${event.happenedAt.toLocal().toString().split('.').first}',
              style: const TextStyle(fontSize: 12),
            ),
            if ((event.details ?? '').isNotEmpty)
              Text(
                event.details!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
