import 'package:pets/domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.status,
    required super.mediaUrl,
    required super.content,
    required super.likes,
    required super.countryCode,
    required super.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> m) {
    final likesVal = m['likes'];
    final likes = likesVal is num
        ? likesVal.toInt()
        : int.tryParse('$likesVal') ?? 0;

    return PostModel(
      id: (m['id'] as num).toInt(),
      status: (m['status'] ?? '').toString(),
      mediaUrl: m['media_url'] as String?,
      content:
          m['content'] as String?, // puede venir null si no existe en tabla
      likes: likes,
      countryCode: m['country_code'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsert() => {
    'status': status,
    if (mediaUrl != null) 'media_url': mediaUrl,
    // Solo enviamos content si existe en tu tabla
    if (content != null) 'content': content,
    if (countryCode != null) 'country_code': countryCode,
  };
}
