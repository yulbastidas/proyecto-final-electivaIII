import '../../core/config/supabase_config.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final _client = SupabaseConfig.client;

  @override
  Future<List<MessageEntity>> history() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: true)
        .limit(50);
    return (rows as List)
        .map((m) => MessageModel.fromMap(m).toEntity())
        .toList();
  }

  @override
  Future<MessageEntity> sendUser(String text) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('chat_messages')
        .insert({'user_id': uid, 'role': 'user', 'text': text})
        .select()
        .single();
    return MessageModel.fromMap(row).toEntity();
  }

  @override
  Future<MessageEntity> sendAssistant(String text) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('chat_messages')
        .insert({'user_id': uid, 'role': 'assistant', 'text': text})
        .select()
        .single();
    return MessageModel.fromMap(row).toEntity();
  }
}
