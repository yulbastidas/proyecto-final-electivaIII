// lib/domain/entities/post.dart
class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String status; // 'rescued' | 'adoption' | 'sale'
  final int likes;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.status,
    required this.likes,
    required this.createdAt,
    this.imageUrl,
  });
}
