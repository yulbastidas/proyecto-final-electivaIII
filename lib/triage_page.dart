import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class TriagePage extends StatefulWidget {
  const TriagePage({super.key});
  @override
  State<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends State<TriagePage> {
  final supa = Supabase.instance.client;
  String petType = 'perro';
  final symCtrl = TextEditingController();
  int durationH = 6;
  int severity = 2;
  String? advice;
  bool loading = false;

  Future<void> _consult() async {
    setState(() {
      loading = true;
      advice = null;
    });

    final uid = supa.auth.currentUser!.id;
    final p = await supa.from('profiles').select().eq('id', uid).single();
    final cc = (p['country_code'] ?? 'CO') as String;

    // ✅ URL correcta (v1)
    final url = Uri.parse(
      'https://zanejjvwjarxjryaqbdc.supabase.co/functions/v1/ai-triage',
    );

    final body = {
      'petType': petType,
      'symptoms': symCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'durationH': durationH,
      'severity': severity,
      'countryCode': cc,
      // ✅ modelo que ya funciona en tu cuenta
      'model': 'llama-3.1-8b-instant',
    };

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // Si vuelves a activar "Verify JWT…" en la función, agrega:
        // 'Authorization': 'Bearer <TU_SUPABASE_ANON_KEY>',
      },
      body: jsonEncode(body),
    );

    if (!mounted) return;

    if (res.statusCode != 200) {
      setState(() {
        advice = 'Error ${res.statusCode}: ${res.body}';
        loading = false;
      });
      return;
    }

    final Map<String, dynamic> json = jsonDecode(res.body);
    advice = json['advice'] as String?;

    // Guarda el reporte (aunque advice sea null)
    await supa.from('symptom_reports').insert({
      'owner': uid,
      'pet_type': petType,
      'symptoms': body['symptoms'],
      'duration_h': durationH,
      'severity': severity,
      'ai_advice': advice,
      'country_code': cc,
    });

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat IA de síntomas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              '⚠️ Orientación general. No reemplaza a un veterinario.',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              value: petType,
              items: const [
                DropdownMenuItem(value: 'perro', child: Text('Perro')),
                DropdownMenuItem(value: 'gato', child: Text('Gato')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (v) => setState(() => petType = v as String),
              decoration: const InputDecoration(labelText: 'Mascota'),
            ),
            TextField(
              controller: symCtrl,
              decoration: const InputDecoration(
                labelText: 'Síntomas (separa por comas)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Duración (h)'),
                Expanded(
                  child: Slider(
                    value: durationH.toDouble(),
                    min: 0,
                    max: 72,
                    divisions: 72,
                    label: '$durationH',
                    onChanged: (v) => setState(() => durationH = v.toInt()),
                  ),
                ),
                Text('$durationH'),
              ],
            ),
            Row(
              children: [
                const Text('Severidad'),
                Expanded(
                  child: Slider(
                    value: severity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$severity',
                    onChanged: (v) => setState(() => severity = v.toInt()),
                  ),
                ),
                Text('$severity'),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: loading ? null : _consult,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Consultar IA'),
            ),
            const SizedBox(height: 12),
            if (advice != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(advice!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
