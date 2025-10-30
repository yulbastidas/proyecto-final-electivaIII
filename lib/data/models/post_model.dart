class Post {
  final String id;
  final String author; // user id
  final String description;
  final String status; // RESCATADO | ADOPCION | VENTA
  final String countryCode;
  final String? mediaUrl;
  final int likes;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.description,
    required this.status,
    required this.countryCode,
    this.mediaUrl,
    required this.likes,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> m) {
    return Post(
      id: '${m['id']}',
      author: '${m['author']}',
      description: '${m['description'] ?? ''}',
      status: '${m['status'] ?? ''}',
      countryCode: '${m['country_code'] ?? ''}',
      mediaUrl: m['media_url'] as String?,
      likes: (m['likes'] ?? 0) is int
          ? m['likes'] as int
          : int.tryParse('${m['likes']}') ?? 0,
      createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
    );
  }
}
