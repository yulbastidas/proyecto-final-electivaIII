import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  final _endpoint = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );
  final _model = 'llama3-8b-8192';

  String get _apiKey => dotenv.env['GROQ_API_KEY']!.trim();

  Future<String> ask(String userText) async {
    final system = '''
Eres una IA veterinaria. SOLO respondes temas de mascotas, salud animal, nutrición y cuidados.
Si te preguntan de otro tema, responde: "Solo puedo ayudarte con temas veterinarios."''';

    final body = {
      "model": _model,
      "temperature": 0.3,
      "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": userText},
      ],
    };

    final res = await http.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('AI error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    return data['choices'][0]['message']['content'];
  }
}
