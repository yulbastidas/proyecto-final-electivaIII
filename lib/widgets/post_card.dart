// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:pets/domain/entities/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final VoidCallback? onComment; // <- nuevo

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onDelete,
    this.onComment, // <- nuevo
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(post.imageUrl!, fit: BoxFit.cover),
            ),
          ListTile(
            title: Text(post.content),
            subtitle: Text(post.status.toUpperCase()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onComment,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: onLike,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Likes: ${post.likes}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
