import 'package:pets/domain/entities/chat_session_entity.dart';

class ChatSessionModel extends ChatSessionEntity {
  ChatSessionModel({
    required super.id,
    required super.petId,
    required super.userId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatSessionModel.fromEntity(ChatSessionEntity entity) {
    return ChatSessionModel(
      id: entity.id,
      petId: entity.petId,
      userId: entity.userId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatSessionEntity toEntity() {
    return ChatSessionEntity(
      id: id,
      petId: petId,
      userId: userId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
