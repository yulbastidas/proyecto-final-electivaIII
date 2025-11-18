import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_session_entity.dart';

abstract class ChatRepository {
  Future<List<ChatSessionEntity>> getChatSessions(String petId);
  Future<ChatSessionEntity> createChatSession(String petId, String title);
  Future<List<MessageEntity>> getHistory(String sessionId);
  Future<MessageEntity> sendMessage(
    String sessionId,
    String petId,
    String message,
    List<MessageEntity> conversationHistory,
  );
  Future<void> deleteSession(String sessionId);
  Future<void> updateSessionTitle(String sessionId, String title);
}

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient sb;
  final String Function() getUid;

  ChatRepositoryImpl({required this.sb, required this.getUid});

  String get apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  String get model => dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile';

  static const systemPrompt = """
Eres un asistente veterinario profesional especializado EXCLUSIVAMENTE en medicina veterinaria.
- Respondes SIEMPRE en español
- SOLO respondes preguntas sobre animales
- Si te preguntan algo no veterinario: 
  "Lo siento, soy un asistente especializado en veterinaria..."
- No das diagnósticos definitivos
- Si detectas emergencia → recomendar ir a un veterinario
""";

  @override
  Future<List<ChatSessionEntity>> getChatSessions(String petId) async {
    try {
      final uid = getUid();
      final data = await sb
          .from('chat_sessions')
          .select()
          .eq('pet_id', petId)
          .eq('user_id', uid)
          .order('updated_at', ascending: false);

      return data
          .map<ChatSessionEntity>((m) => ChatSessionEntity.fromMap(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ChatSessionEntity> createChatSession(
    String petId,
    String title,
  ) async {
    final uid = getUid();

    final inserted = await sb
        .from('chat_sessions')
        .insert({
          'pet_id': petId,
          'user_id': uid,
          'title': title,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return ChatSessionEntity.fromMap(inserted);
  }

  @override
  Future<List<MessageEntity>> getHistory(String sessionId) async {
    try {
      final data = await sb
          .from('pet_chats')
          .select()
          .eq('session_id', sessionId)
          .order('created_at');

      return data.map<MessageEntity>((m) => MessageEntity.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MessageEntity> sendMessage(
    String sessionId,
    String petId,
    String message,
    List<MessageEntity> conversationHistory,
  ) async {
    final uid = getUid();

    await sb.from('pet_chats').insert({
      'session_id': sessionId,
      'pet_id': petId,
      'user_id': uid,
      'role': 'user',
      'message': message,
    });

    final apiMessages = <Map<String, String>>[
      {"role": "system", "content": systemPrompt},
      ..._buildContext(conversationHistory),
      {"role": "user", "content": message},
    ];

    try {
      final res = await http
          .post(
            Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
            headers: {
              "Authorization": "Bearer $apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "model": model,
              "messages": apiMessages,
              "temperature": 0.7,
              "max_tokens": 1000,
              "top_p": 1,
              "stream": false,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw Exception('API error');
      }

      final json = jsonDecode(res.body);
      final reply = json["choices"][0]["message"]["content"] as String;

      await sb
          .from('chat_sessions')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);

      final inserted = await sb
          .from('pet_chats')
          .insert({
            'session_id': sessionId,
            'pet_id': petId,
            'user_id': uid,
            'role': 'assistant',
            'message': reply,
          })
          .select()
          .single();

      return MessageEntity.fromMap(inserted);
    } catch (e) {
      final errorMsg = await sb
          .from('pet_chats')
          .insert({
            'session_id': sessionId,
            'pet_id': petId,
            'user_id': uid,
            'role': 'assistant',
            'message':
                'Lo siento, hubo un error al procesar tu mensaje. Por favor intenta nuevamente. Error: ${e.toString()}',
          })
          .select()
          .single();

      return MessageEntity.fromMap(errorMsg);
    }
  }

  List<Map<String, String>> _buildContext(List<MessageEntity> history) {
    if (history.length <= 10) {
      return history
          .map((m) => {"role": m.role, "content": m.message})
          .toList();
    }

    final recent = history.sublist(history.length - 10);
    return recent.map((m) => {"role": m.role, "content": m.message}).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await sb.from('pet_chats').delete().eq('session_id', sessionId);
    await sb.from('chat_sessions').delete().eq('id', sessionId);
  }

  @override
  Future<void> updateSessionTitle(String sessionId, String title) async {
    await sb.from('chat_sessions').update({'title': title}).eq('id', sessionId);
  }
}
