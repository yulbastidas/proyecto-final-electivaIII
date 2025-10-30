// lib/data/models/post_model.dart
import 'package:pets/domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.userId,
    required super.content,
    required super.status,
    required super.likes,
    required super.createdAt,
    super.imageUrl,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      content: (map['content'] ?? '').toString(),
      status: (map['status'] ?? 'rescued').toString(),
      likes: _asInt(map['likes']),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      imageUrl: map['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'content': content,
    'status': status,
    'likes': likes,
    'created_at': createdAt.toIso8601String(),
    'image_url': imageUrl,
  };

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }
}
