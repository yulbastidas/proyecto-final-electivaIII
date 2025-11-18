class MessageEntity {
  final String id;
  final String sessionId;
  final String petId;
  final String userId;
  final String role;
  final String message;
  final DateTime createdAt;

  MessageEntity({
    required this.id,
    required this.sessionId,
    required this.petId,
    required this.userId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  factory MessageEntity.fromMap(Map<String, dynamic> map) {
    return MessageEntity(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      petId: map['pet_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'pet_id': petId,
      'user_id': userId,
      'role': role,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
