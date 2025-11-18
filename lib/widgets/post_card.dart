import 'package:flutter/material.dart';
import 'package:pets/domain/entities/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final ValueChanged<int>? onLike;
  final ValueChanged<int>? onDelete;

  const PostCard({super.key, required this.post, this.onLike, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.mediaUrl!, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Text(post.status, style: theme.titleMedium),
            if ((post.content ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(post.content!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () => onLike?.call(post.id),
                ),
                Text('${post.likes}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete?.call(post.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
