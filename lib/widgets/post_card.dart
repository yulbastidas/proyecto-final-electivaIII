import 'package:flutter/material.dart';
import '../../widgets/post.dart';
import '../../core/constants/app_colors.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onDelete;
  const PostCard({super.key, required this.post, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final badge = switch (post.status) {
      'sale' => ('VENTA', Colors.orange),
      'rescue' => ('RESCATE', Colors.redAccent),
      _ => ('ADOPCIÓN', AppColors.primary),
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(post.countryCode)),
            title: Text(
              badge.$1,
              style: TextStyle(
                color: badge.$2,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Text(
              post.description,
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
          if (post.mediaUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Image.network(
                post.mediaUrl!,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
        ],
      ),
    );
  }
}
