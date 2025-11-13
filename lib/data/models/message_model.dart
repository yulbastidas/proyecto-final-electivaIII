import 'package:pets/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.sessionId,
    required super.petId,
    required super.userId,
    required super.role,
    required super.message,
    required super.createdAt,
  });

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      petId: entity.petId,
      userId: entity.userId,
      role: entity.role,
      message: entity.message,
      createdAt: entity.createdAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
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

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      sessionId: sessionId,
      petId: petId,
      userId: userId,
      role: role,
      message: message,
      createdAt: createdAt,
    );
  }
}
