import '../../data/repositories/chat_repository_impl.dart';

class ChatController {
  final ChatRepositoryImpl _repo = ChatRepositoryImpl();

  Future<String> sendMessage(String text) async {
    return await _repo.askVetAI(text);
  }

  List<Map<String, String>> getHistory() {
    return _repo.getHistory();
  }
}
