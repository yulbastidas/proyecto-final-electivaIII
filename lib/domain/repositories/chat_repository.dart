import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<MessageEntity>> history();
  Future<MessageEntity> sendUser(String text);
  Future<MessageEntity> sendAssistant(String text);
}
