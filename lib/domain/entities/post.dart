class Post {
  final int id;
  final String status;
  final String? mediaUrl; // antes imageUrl
  final String? content; // opcional (tu tabla puede no tenerla)
  final int likes; // opcional (0 si no existe en DB)
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
