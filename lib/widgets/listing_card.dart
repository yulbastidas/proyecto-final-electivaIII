import 'package:flutter/material.dart';
import '../../data/models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onDelete;

  const ListingCard({super.key, required this.listing, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (listing.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                listing.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(listing.description, style: textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    Chip(label: Text('Status: ${listing.status}')),
                    Chip(
                      label: Text(
                        'Price: \$${listing.price.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Publicado: ${listing.createdAt}',
                      style: textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
