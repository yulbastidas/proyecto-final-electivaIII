import 'package:flutter/foundation.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/ai_service.dart';
import '../../domain/entities/message_entity.dart';

class ChatController extends ChangeNotifier {
  final _repo = ChatRepositoryImpl();
  final _ai = AiService();

  bool loading = false;
  List<MessageEntity> messages = [];

  Future<void> load() async {
    messages = await _repo.history();
    notifyListeners();
  }

  Future<void> send(String userText) async {
    if (userText.trim().isEmpty) return;
    loading = true;
    notifyListeners();

    // Guarda del usuario
    final me = await _repo.sendUser(userText.trim());
    messages.add(me);
    notifyListeners();

    try {
      // Llama a la IA (con prompt veterinario dentro del AiService)
      final answer = await _ai.ask(userText.trim());
      final asst = await _repo.sendAssistant(answer);
      messages.add(asst);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
