import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';

class PostItem extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final Function(String text) onComment;

  const PostItem({
    super.key,
    required this.post,
    required this.onLike,
    required this.onDelete,
    required this.onComment,
  });

  Future<String?> _showCommentDialog(BuildContext context) async {
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar comentario"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Escribe tu comentario"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text("Enviar"),
            onPressed: () => Navigator.pop(context, ctrl.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.mediaUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            Text(post.status, style: const TextStyle(fontSize: 16)),
            if (post.content != null)
              Text(post.content!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_outline),
                  onPressed: onLike,
                ),
                Text("${post.likes}"),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () async {
                    final text = await _showCommentDialog(context);
                    if (text != null && text.trim().isNotEmpty) {
                      onComment(text.trim());
                    }
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
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
