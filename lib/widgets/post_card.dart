import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (post.status) {
      'RESCATADO' => Colors.green,
      'ADOPCION' => Colors.orange,
      'VENTA' => Colors.blue,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.mediaUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(post.mediaUrl!, fit: BoxFit.cover),
            ),
          ListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(.4)),
                  ),
                  child: Text(
                    post.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '@${post.author.substring(0, post.author.length > 6 ? 6 : post.author.length)}…',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(post.description),
            ),
            trailing: onDelete == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: onLike,
                ),
                Text('${post.likes}'),
                const Spacer(),
                TextButton.icon(
                  onPressed: onComment,
                  icon: const Icon(Icons.comment_outlined),
                  label: const Text('Comentarios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
