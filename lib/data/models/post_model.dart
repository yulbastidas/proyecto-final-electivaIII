import '../../domain/entities/post_entity.dart';

class PostModel {
  final int id;
  final String author;
  final String? description;
  final String? mediaUrl;
  final String status;
  final String? countryCode;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.author,
    this.description,
    this.mediaUrl,
    required this.status,
    this.countryCode,
    required this.createdAt,
  });

  factory PostModel.fromMap(Map m) => PostModel(
    id: m['id'],
    author: m['author'],
    description: m['description'],
    mediaUrl: m['media_url'],
    status: m['status'],
    countryCode: m['country_code'],
    createdAt: DateTime.parse(m['created_at']),
  );

  PostEntity toEntity() => PostEntity(
    id: id,
    authorId: author,
    description: description,
    mediaUrl: mediaUrl,
    status: status,
    countryCode: countryCode,
    createdAt: createdAt,
  );
}
