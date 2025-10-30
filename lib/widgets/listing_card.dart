import 'package:flutter/material.dart';
import '../../data/models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing item;
  final VoidCallback? onDelete;
  const ListingCard({super.key, required this.item, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                item.imageUrl!,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ListTile(
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.call, size: 18),
                    const SizedBox(width: 6),
                    Text(item.contact),
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
