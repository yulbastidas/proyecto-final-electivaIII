import 'package:flutter/material.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/health_event_entity.dart';
import '../../domain/entities/weight_entity.dart';

class HealthLogPage extends StatefulWidget {
  const HealthLogPage({super.key});

  @override
  State<HealthLogPage> createState() => _HealthLogPageState();
}

class _HealthLogPageState extends State<HealthLogPage> {
  final repo = HealthRepositoryImpl();
  List<HealthEventEntity> events = [];
  List<WeightEntity> weights = [];
  final kgCtrl = TextEditingController();

  Future<void> _load() async {
    events = await repo.listEvents();
    weights = await repo.listWeights();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _addVaccine() async {
    await repo.addEvent(
      kind: 'vaccine',
      title: 'Vacuna',
      dueAt: DateTime.now().add(const Duration(days: 30)),
    );
    await _load();
  }

  Future<void> _addWeight() async {
    final kg = double.tryParse(kgCtrl.text);
    if (kg == null) return;
    await repo.addWeight(kg, DateTime.now());
    kgCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Bitácora de salud',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Vacunas / Desparasitación / Medicación'),
            subtitle: Text('${events.length} eventos'),
            trailing: FilledButton(
              onPressed: _addVaccine,
              child: const Text('Añadir vacuna'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peso (kg)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: kgCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(hintText: 'Ej: 6.4'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addWeight,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final w in weights)
                  Text(
                    '${w.kg.toStringAsFixed(1)} kg  •  ${w.at.toLocal().toString().split(" ").first}',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
