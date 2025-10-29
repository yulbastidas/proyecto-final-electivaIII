// lib/health_log_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;
final _fmt = DateFormat('dd/MM/yyyy');

class HealthLogPage extends StatefulWidget {
  const HealthLogPage({super.key});

  @override
  State<HealthLogPage> createState() => _HealthLogPageState();
}

class _HealthLogPageState extends State<HealthLogPage> {
  bool loading = true;
  String? error;

  // Puedes enlazar con tu mascota seleccionada; por ahora null (todas)
  String? petId;

  // Datos en memoria
  List<Map<String, dynamic>> vaccines = [];
  List<Map<String, dynamic>> deworms = [];
  List<Map<String, dynamic>> meds = [];
  List<Map<String, dynamic>> weights = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final ev = await _db
          .from('health_events')
          .select()
          .order('date', ascending: false);

      final ws = await _db
          .from('weights')
          .select()
          .order('date', ascending: true);

      vaccines = ev
          .where((e) => e['type'] == 'vaccine')
          .toList()
          .cast<Map<String, dynamic>>();
      deworms = ev
          .where((e) => e['type'] == 'deworm')
          .toList()
          .cast<Map<String, dynamic>>();
      meds = ev
          .where((e) => e['type'] == 'med')
          .toList()
          .cast<Map<String, dynamic>>();
      weights = ws.cast<Map<String, dynamic>>();
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  // ---------- Helpers UI ----------
  int _daysTo(DateTime? due) {
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays;
  }

  Color _dueColor(DateTime? due) {
    final d = _daysTo(due);
    if (d <= 0) return Colors.red;
    if (d <= 7) return Colors.orange;
    return Colors.green;
  }

  String _safeStr(dynamic v) => (v ?? '').toString();

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  // ---------- CRUD ----------
  Future<void> _addEventDialog(String kind) async {
    final form = GlobalKey<FormState>();
    final title = TextEditingController();
    final dose = TextEditingController();
    final freq = TextEditingController();
    final notes = TextEditingController();
    DateTime? date = DateTime.now();
    DateTime? due;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        kind == 'vaccine'
                            ? Icons.vaccines
                            : kind == 'deworm'
                            ? Icons.bug_report
                            : Icons.medication,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        kind == 'vaccine'
                            ? 'Nueva vacuna'
                            : kind == 'deworm'
                            ? 'Nueva desparasitación'
                            : 'Nueva medicación',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Rabia / Albendazol / Amoxicilina',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  if (kind != 'deworm') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: dose,
                      decoration: const InputDecoration(
                        labelText: 'Dosis',
                        hintText: 'Ej: 0.5 ml / 250 mg',
                      ),
                    ),
                  ],
                  if (kind == 'med') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: freq,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia',
                        hintText: 'Ej: cada 8 horas por 5 días',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fecha aplicada'),
                          subtitle: Text(_fmt.format(date!)),
                          trailing: const Icon(Icons.event),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date!,
                              firstDate: DateTime(2015),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => date = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Próxima fecha (opcional)'),
                    subtitle: Text(due == null ? '—' : _fmt.format(due!)),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => due = null),
                        ),
                        IconButton(
                          tooltip: 'Elegir',
                          icon: const Icon(Icons.event_available),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  due ??
                                  DateTime.now().add(const Duration(days: 180)),
                              firstDate: DateTime(2015),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => due = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      hintText: 'Observaciones adicionales…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        final payload = {
                          'type': kind,
                          'title': title.text.trim(),
                          'dose': dose.text.trim().isEmpty
                              ? null
                              : dose.text.trim(),
                          'frequency': freq.text.trim().isEmpty
                              ? null
                              : freq.text.trim(),
                          'date': DateTime(
                            date!.year,
                            date!.month,
                            date!.day,
                          ).toIso8601String(),
                          'due_date': due == null
                              ? null
                              : DateTime(
                                  due!.year,
                                  due!.month,
                                  due!.day,
                                ).toIso8601String(),
                          'notes': notes.text.trim().isEmpty
                              ? null
                              : notes.text.trim(),
                          'pet_id': petId, // puedes ignorarlo si aún no lo usas
                        };
                        await _db.from('health_events').insert(payload);
                        if (mounted) Navigator.pop(ctx);
                        _loadAll();
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteEvent(int id) async {
    await _db.from('health_events').delete().eq('id', id);
    _loadAll();
  }

  Future<void> _addWeightDialog() async {
    final form = GlobalKey<FormState>();
    final kgCtrl = TextEditingController();
    DateTime date = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Agregar peso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: kgCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Kg',
                    hintText: 'Ej: 12.4',
                  ),
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Ingresa un número válido'
                      : null,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha'),
                  subtitle: Text(_fmt.format(date)),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => date = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!form.currentState!.validate()) return;
                      await _db.from('weights').insert({
                        'pet_id': petId,
                        'kg': double.parse(kgCtrl.text),
                        'date': DateTime(
                          date.year,
                          date.month,
                          date.day,
                        ).toIso8601String(),
                      });
                      if (mounted) Navigator.pop(ctx);
                      _loadAll();
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- UI secciones ----------
  Widget _sectionHeader(String title, {List<Widget> actions = const []}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        ...actions,
      ],
    );
  }

  Widget _eventsList(
    List<Map<String, dynamic>> items, {
    required String emptyLabel,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(emptyLabel, style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return Column(
      children: items.map((e) {
        final id = e['id'] as int?;
        final title = _safeStr(e['title']);
        final dose = _safeStr(e['dose']);
        final freq = _safeStr(e['frequency']);
        final notes = _safeStr(e['notes']);
        final date = _parseDate(e['date']);
        final due = _parseDate(e['due_date']);
        final days = _daysTo(due);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _dueColor(due).withOpacity(.15),
              child: Icon(Icons.event_available, color: _dueColor(due)),
            ),
            title: Text(title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null) Text('Aplicada: ${_fmt.format(date)}'),
                if (due != null)
                  Text(
                    'Próxima: ${_fmt.format(due)} • ${days < 0 ? 'Vencida' : '$days días'}',
                    style: TextStyle(color: _dueColor(due)),
                  ),
                if (dose.isNotEmpty) Text('Dosis: $dose'),
                if (freq.isNotEmpty) Text('Frecuencia: $freq'),
                if (notes.isNotEmpty) Text('Notas: $notes'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: id == null ? null : () => _deleteEvent(id),
              tooltip: 'Eliminar',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _weightChart() {
    if (weights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Sin registros de peso',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < weights.length; i++) {
      final w = weights[i];
      final d =
          _parseDate(w['date']) ??
          DateTime.now().subtract(Duration(days: weights.length - i));
      final kg = (w['kg'] is num)
          ? (w['kg'] as num).toDouble()
          : double.tryParse(_safeStr(w['kg'])) ?? 0;
      spots.add(FlSpot(d.millisecondsSinceEpoch.toDouble(), kg));
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 36),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, meta) {
                  final dt = DateTime.fromMillisecondsSinceEpoch(x.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MM/yy').format(dt),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora de salud')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Error: $error'))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vacunas
                  _sectionHeader(
                    'Vacunas',
                    actions: [
                      IconButton(
                        onPressed: () => _addEventDialog('vaccine'),
                        icon: const Icon(Icons.add),
                        tooltip: 'Agregar vacuna',
                      ),
                    ],
                  ),
                  _eventsList(vaccines, emptyLabel: 'Aún no registras vacunas'),
                  const SizedBox(height: 16),

                  // Desparasitación
                  _sectionHeader(
                    'Desparasitación',
                    actions: [
                      IconButton(
                        onPressed: () => _addEventDialog('deworm'),
                        icon: const Icon(Icons.add),
                        tooltip: 'Agregar desparasitación',
                      ),
                    ],
                  ),
                  _eventsList(
                    deworms,
                    emptyLabel: 'Aún no registras desparasitación',
                  ),
                  const SizedBox(height: 16),

                  // Medicaciones
                  _sectionHeader(
                    'Medicaciones',
                    actions: [
                      IconButton(
                        onPressed: () => _addEventDialog('med'),
                        icon: const Icon(Icons.add),
                        tooltip: 'Agregar medicación',
                      ),
                    ],
                  ),
                  _eventsList(
                    meds,
                    emptyLabel: 'Aún no registras medicaciones',
                  ),
                  const SizedBox(height: 16),

                  // Peso
                  _sectionHeader(
                    'Peso',
                    actions: [
                      IconButton(
                        onPressed: _addWeightDialog,
                        icon: const Icon(Icons.add),
                        tooltip: 'Agregar peso',
                      ),
                    ],
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _weightChart(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
