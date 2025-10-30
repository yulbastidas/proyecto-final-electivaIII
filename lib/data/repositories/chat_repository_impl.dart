import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final List<Map<String, String>> _history = [];

  @override
  Future<String> askVetAI(String question) async {
    final apiUrl = dotenv.env['GROQ_API_URL']!;
    final apiKey = dotenv.env['GROQ_API_KEY']!;

    final systemPrompt = '''
You are a veterinary assistant. 
Only respond to questions about pet health and wellness.
If the question is unrelated to animals or veterinary topics, answer:
"I'm sorry, I can only discuss veterinary-related topics."
''';

    _history.add({"role": "user", "content": question});

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "llama3-70b-8192",
        "messages": [
          {"role": "system", "content": systemPrompt},
          ..._history.map((m) => {"role": m["role"], "content": m["content"]}),
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'];
      _history.add({"role": "assistant", "content": reply});
      return reply;
    } else {
      return "Error contacting the veterinary assistant.";
    }
  }

  @override
  List<Map<String, String>> getHistory() => _history;
}
