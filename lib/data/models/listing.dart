import 'package:meta/meta.dart';

@immutable
class Listing {
  final int id;
  final String title;
  final String description;
  final double price;

  /// 'adoption' | 'sale' | 'rescue'
  final String status;
  final String? imageUrl;
  final String author; // user uuid
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.author,
    required this.createdAt,
    this.imageUrl,
  });

  factory Listing.fromMap(Map<String, dynamic> m) {
    final priceRaw = m['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse('${priceRaw ?? 0}') ?? 0.0;

    return Listing(
      id: m['id'] as int,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      price: price,
      status: (m['status'] ?? 'sale') as String,
      imageUrl: m['image_url'] as String?,
      author: (m['author'] ?? m['user_id'] ?? '') as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsert() => {
    'title': title,
    'description': description,
    'price': price,
    'status': status,
    'image_url': imageUrl,
  };
}
