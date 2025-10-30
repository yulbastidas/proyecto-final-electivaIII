class PostEntity {
  final int id;
  final String authorId;
  final String? description;
  final String? mediaUrl;
  final String status; // adoption|sale|rescued
  final String? countryCode;
  final DateTime createdAt;

  PostEntity({
    required this.id,
    required this.authorId,
    this.description,
    this.mediaUrl,
    required this.status,
    this.countryCode,
    required this.createdAt,
  });
}
