import 'package:meta/meta.dart';

@immutable
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String status; // Sale | Adoption | Rescued
  final String? imageUrl;
  final String author;
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
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String,
      price: price,
      status: m['status'] as String,
      imageUrl: m['image_url'] as String?,
      author: m['author'] as String,
      createdAt: DateTime.parse(m['created_at']),
    );
  }

  Map<String, dynamic> toInsert(String userId) => {
    'title': title,
    'description': description,
    'price': price,
    'status': 'Sale', // <-- Siempre Venta
    'image_url': imageUrl,
    'author': userId,
  };
}
