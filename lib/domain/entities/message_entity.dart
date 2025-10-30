class MessageEntity {
  final int id;
  final String userId;
  final String role; // user|assistant
  final String text;
  final DateTime createdAt;

  MessageEntity({
    required this.id,
    required this.userId,
    required this.role,
    required this.text,
    required this.createdAt,
  });
}
