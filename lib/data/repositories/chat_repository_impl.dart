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

  String get apiKey => dotenv.env['QROQ_API_KEY'] ?? '';
  String get model => dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile';

  static const systemPrompt = """
Eres un asistente veterinario profesional especializado EXCLUSIVAMENTE en medicina veterinaria.

REGLAS ESTRICTAS:
- Respondes SIEMPRE en español
- SOLO respondes preguntas relacionadas con animales, mascotas, veterinaria, salud animal, nutrición animal, comportamiento animal
- Si te preguntan sobre temas NO veterinarios (política, tecnología, cocina para humanos, etc.), responde: "Lo siento, soy un asistente especializado en veterinaria. Solo puedo ayudarte con temas relacionados con la salud y cuidado de animales. ¿Tienes alguna pregunta sobre tu mascota?"
- Ayudas con: vacunas, desparasitación, medicamentos veterinarios, nutrición animal, comportamiento, primeros auxilios para mascotas, cuidado general
- NUNCA das diagnósticos médicos definitivos
- Siempre recomiendas visitar al veterinario para problemas serios
- Eres amable, profesional y empático

IMPORTANTE: Si detectas una emergencia veterinaria, indica que acudan INMEDIATAMENTE al veterinario más cercano.
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
    } catch (e) {
      print('❌ Error obteniendo sesiones: $e');
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
    } catch (e) {
      print('❌ Error obteniendo historial: $e');
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

    // Guarda mensaje del usuario
    await sb.from('pet_chats').insert({
      'session_id': sessionId,
      'pet_id': petId,
      'user_id': uid,
      'role': 'user',
      'message': message,
    });

    // Construye el historial de conversación
    List<Map<String, String>> apiMessages = [
      {"role": "system", "content": systemPrompt},
    ];

    // Últimos 10 mensajes para contexto
    final recentHistory = conversationHistory.length > 10
        ? conversationHistory.sublist(conversationHistory.length - 10)
        : conversationHistory;

    for (var msg in recentHistory) {
      apiMessages.add({"role": msg.role, "content": msg.message});
    }

    apiMessages.add({"role": "user", "content": message});

    try {
      print('🚀 Enviando a Groq API...');

      // Llamada a Groq API
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

      print('📡 Status: ${res.statusCode}');

      if (res.statusCode != 200) {
        print('❌ Error API Groq: ${res.statusCode}');
        print('📄 Body: ${res.body}');
        throw Exception('Error en la API de Groq: ${res.statusCode}');
      }

      final json = jsonDecode(res.body);

      if (json["choices"] == null || json["choices"].isEmpty) {
        throw Exception('Respuesta inválida de la API');
      }

      final reply = json["choices"][0]["message"]["content"] as String;
      print('✅ Respuesta recibida: ${reply.substring(0, 50)}...');

      // Actualiza fecha de sesión
      await sb
          .from('chat_sessions')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);

      // Guarda respuesta del asistente
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
      print('❌ Error enviando mensaje: $e');

      // Mensaje de error amigable
      final errorMsg = await sb
          .from('pet_chats')
          .insert({
            'session_id': sessionId,
            'pet_id': petId,
            'user_id': uid,
            'role': 'assistant',
            'message':
                'Lo siento, hubo un error al procesar tu mensaje. Por favor, verifica tu conexión e intenta nuevamente. Error: ${e.toString()}',
          })
          .select()
          .single();

      return MessageEntity.fromMap(errorMsg);
    }
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
