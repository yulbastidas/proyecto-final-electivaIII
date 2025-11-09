import 'package:flutter/material.dart';
import 'package:pets/domain/entities/post.dart';

class PostItem extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final VoidCallback? onComment;

  const PostItem({
    super.key,
    required this.post,
    this.onLike,
    this.onDelete,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(post.status, style: Theme.of(context).textTheme.titleMedium),
            if ((post.content ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(post.content!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  tooltip: 'Me gusta',
                  onPressed: onLike,
                ),
                Text('${post.likes}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined),
                  tooltip: 'Comentar',
                  onPressed: onComment,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
