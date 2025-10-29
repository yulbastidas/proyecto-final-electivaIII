// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final _endpoint = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  String get _model => dotenv.env['GROQ_MODEL'] ?? 'llama-3.1-8b-instant';

  /// “Entrenamiento”: prompt del sistema (puedes editarlo a tu gusto)
  static const String systemPrompt = '''
Eres una IA de orientación veterinaria para mascotas. 
Habla breve, clara y empática. 
No reemplazas a un veterinario. 
Si detectas urgencia (sangrado, convulsiones, dificultad respiratoria, coma, ingestión de venenos), aconseja acudir a urgencias de inmediato.
''';

  /// Envía el mensaje del usuario y devuelve el texto de la IA.
  Future<String> ask(String userMessage) async {
    if (_apiKey.isEmpty) {
      return '⚠️ Falta GROQ_API_KEY en .env';
    }

    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': _model,
      'temperature': 0.4,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    });

    final res = await http.post(_endpoint, headers: headers, body: body);

    if (res.statusCode == 401) {
      return '⚠️ 401 No autorizado: revisa tu GROQ_API_KEY del .env';
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return '⚠️ Error ${res.statusCode}: ${res.body}';
    }

    final data = jsonDecode(res.body);
    final text = data['choices']?[0]?['message']?['content']?.toString();
    return (text == null || text.isEmpty) ? 'Sin respuesta' : text.trim();
  }
}
