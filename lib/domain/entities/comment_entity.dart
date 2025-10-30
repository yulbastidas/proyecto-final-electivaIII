class CommentEntity {
  final int id;
  final int postId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  CommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });
}
