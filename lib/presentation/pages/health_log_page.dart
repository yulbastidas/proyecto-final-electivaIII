import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/health_controller.dart';
import '../../domain/entities/weight_entity.dart';

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
  final _kgCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.petId);
  }

  @override
  void dispose() {
    _kgCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final kg = double.tryParse(_kgCtrl.text.replaceAll(',', '.'));
    if (kg == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Peso inválido')));
      return;
    }
    await widget.controller.addWeight(
      widget.petId,
      kg,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    _kgCtrl.clear();
    _noteCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora de salud')),
      body: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Pesos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _kgCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                          ),
                          validator: (v) {
                            final x = double.tryParse(
                              (v ?? '').replaceAll(',', '.'),
                            );
                            if (x == null) return 'Ingresa un número';
                            if (x <= 0) return 'Debe ser mayor a 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nota (opcional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (c.weights.isEmpty)
                const Text('Sin registros de peso.')
              else
                ...c.weights.map(
                  (w) => _WeightTile(
                    w: w,
                    onDelete: () => c.deleteWeight(widget.petId, w.id),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Eventos de salud',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (c.events.isEmpty) const Text('Sin eventos registrados.'),
              // Deja tu UI real de eventos aquí cuando tengas el modelo listo.
            ],
          );
        },
      ),
    );
  }
}

class _WeightTile extends StatelessWidget {
  final Weight w;
  final VoidCallback onDelete;
  const _WeightTile({required this.w, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return ListTile(
      title: Text('${w.kg} kg'),
      subtitle: Text(
        '${df.format(w.notedAt)}${w.note == null ? '' : ' — ${w.note}'}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
