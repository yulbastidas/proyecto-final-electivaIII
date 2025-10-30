import '../../domain/entities/comment_entity.dart';

class CommentModel {
  final int id;
  final int postId;
  final String author;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map m) => CommentModel(
    id: m['id'],
    postId: m['post_id'],
    author: m['author'],
    text: m['text'],
    createdAt: DateTime.parse(m['created_at']),
  );

  CommentEntity toEntity() => CommentEntity(
    id: id,
    postId: postId,
    authorId: author,
    text: text,
    createdAt: createdAt,
  );
}
