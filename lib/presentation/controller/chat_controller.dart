import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_session_entity.dart';
import '../../data/repositories/chat_repository_impl.dart';

class ChatController extends ChangeNotifier {
  final ChatRepository repo;

  ChatController(this.repo);

  List<ChatSessionEntity> sessions = [];
  List<MessageEntity> messages = [];
  ChatSessionEntity? currentSession;
  bool isTyping = false;
  bool isLoading = false;
  String? error;

  Future<void> loadSessions(String petId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      sessions = await repo.getChatSessions(petId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Error al cargar sesiones: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNewSession(String petId, {String? title}) async {
    try {
      isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final sessionTitle = title ?? 'Consulta ${now.day}/${now.month}';
      currentSession = await repo.createChatSession(petId, sessionTitle);

      sessions.insert(0, currentSession!);
      messages = [];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Error al crear sesión: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSession(String sessionId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      messages = await repo.getHistory(sessionId);
      currentSession = sessions.firstWhere((s) => s.id == sessionId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Error al cargar historial: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send(String petId, String text) async {
    if (currentSession == null) {
      await createNewSession(petId);
    }

    if (currentSession == null) {
      error = 'No se pudo crear la sesión';
      notifyListeners();
      return;
    }

    try {
      final userMessage = MessageEntity(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: currentSession!.id,
        petId: petId,
        userId: 'current-user',
        role: 'user',
        message: text,
        createdAt: DateTime.now(),
      );

      messages.add(userMessage);
      isTyping = true;
      error = null;
      notifyListeners();

      await repo.sendMessage(currentSession!.id, petId, text, messages);

      messages = await repo.getHistory(currentSession!.id);

      isTyping = false;
      notifyListeners();
    } catch (e) {
      error = 'Error al enviar mensaje: $e';
      isTyping = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await repo.deleteSession(sessionId);
      sessions.removeWhere((s) => s.id == sessionId);

      if (currentSession?.id == sessionId) {
        currentSession = null;
        messages = [];
      }

      notifyListeners();
    } catch (e) {
      error = 'Error al eliminar sesión: $e';
      notifyListeners();
    }
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    try {
      await repo.updateSessionTitle(sessionId, newTitle);

      final index = sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        sessions[index] = ChatSessionEntity(
          id: sessions[index].id,
          petId: sessions[index].petId,
          userId: sessions[index].userId,
          title: newTitle,
          createdAt: sessions[index].createdAt,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      error = 'Error al actualizar título: $e';
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
