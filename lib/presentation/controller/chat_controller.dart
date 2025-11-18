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

  // -----------------------------------------------------------
  // Cargar sesiones
  // -----------------------------------------------------------
  Future<void> loadSessions(String petId) async {
    _setLoading(true);

    try {
      sessions = await repo.getChatSessions(petId);
      error = null;
    } catch (e) {
      error = 'Error al cargar sesiones: $e';
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------
  // Crear sesión
  // -----------------------------------------------------------
  Future<void> createNewSession(String petId, {String? title}) async {
    _setLoading(true);

    try {
      final now = DateTime.now();
      final sessionTitle = title ?? 'Consulta ${now.day}/${now.month}';

      currentSession = await repo.createChatSession(petId, sessionTitle);

      sessions.insert(0, currentSession!);
      messages = [];
      error = null;
    } catch (e) {
      error = 'Error al crear sesión: $e';
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------
  // Cargar mensajes de una sesión
  // -----------------------------------------------------------
  Future<void> loadSession(String sessionId) async {
    _setLoading(true);

    try {
      messages = await repo.getHistory(sessionId);
      currentSession = sessions.firstWhere((s) => s.id == sessionId);
      error = null;
    } catch (e) {
      error = 'Error al cargar historial: $e';
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------
  // Enviar mensaje
  // -----------------------------------------------------------
  Future<void> send(String petId, String text) async {
    if (currentSession == null) {
      await createNewSession(petId);
      if (currentSession == null) {
        error = 'No se pudo crear la sesión';
        notifyListeners();
        return;
      }
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
    } catch (e) {
      error = 'Error al enviar mensaje: $e';
    } finally {
      isTyping = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // Eliminar sesión
  // -----------------------------------------------------------
  Future<void> deleteSession(String sessionId) async {
    try {
      await repo.deleteSession(sessionId);

      sessions.removeWhere((s) => s.id == sessionId);

      if (currentSession?.id == sessionId) {
        currentSession = null;
        messages = [];
      }

      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Error al eliminar sesión: $e';
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // Actualizar título
  // -----------------------------------------------------------
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    try {
      await repo.updateSessionTitle(sessionId, newTitle);

      final i = sessions.indexWhere((s) => s.id == sessionId);
      if (i != -1) {
        sessions[i] = ChatSessionEntity(
          id: sessions[i].id,
          petId: sessions[i].petId,
          userId: sessions[i].userId,
          title: newTitle,
          createdAt: sessions[i].createdAt,
          updatedAt: DateTime.now(),
        );
      }

      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Error al actualizar título: $e';
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // Limpiar error
  // -----------------------------------------------------------
  void clearError() {
    error = null;
    notifyListeners();
  }

  // -----------------------------------------------------------
  // Utilidad interna
  // -----------------------------------------------------------
  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }
}
