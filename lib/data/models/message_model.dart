import '../../domain/entities/message_entity.dart';

class MessageModel {
  final int id;
  final String userId;
  final String role;
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map m) => MessageModel(
    id: m['id'],
    userId: m['user_id'],
    role: m['role'],
    text: m['text'],
    createdAt: DateTime.parse(m['created_at']),
  );

  MessageEntity toEntity() => MessageEntity(
    id: id,
    userId: userId,
    role: role,
    text: text,
    createdAt: createdAt,
  );
}
