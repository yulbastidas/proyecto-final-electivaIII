class Post {
  final int id;
  final String status;
  final String? mediaUrl;
  final String? content;
  final int likes;
  final String? countryCode;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.status,
    required this.mediaUrl,
    required this.content,
    required this.likes,
    required this.countryCode,
    required this.createdAt,
  });
}
