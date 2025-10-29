// lib/feed_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

final _supabase = Supabase.instance.client;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _descCtrl = TextEditingController();
  bool _publishing = false;

  Future<List<Post>> _loadPosts() async {
    final res = await _supabase
        .from('posts')
        .select('*')
        .order('created_at', ascending: false);

    // Mapear con tipos fuertes y defaults seguros
    return (res as List)
        .map((m) => Post.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> _publish() async {
    if (_descCtrl.text.trim().isEmpty) return;
    setState(() => _publishing = true);
    try {
      await _supabase.from('posts').insert({
        'description': _descCtrl.text.trim(),
        'status': 'rescatado',
        'country_code': 'CO',
        // si manejas media_url, súbela primero a storage y coloca aquí la URL
      });
      _descCtrl.clear();
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Composer(
            controller: _descCtrl,
            loading: _publishing,
            onSend: _publish,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Post>>(
            future: _loadPosts(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snap.error}'),
                );
              }
              final data = snap.data ?? const <Post>[];
              if (data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aún no hay publicaciones')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _PostCard(post: data[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.loading,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '¿Qué publicas hoy?',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: loading ? null : onSend,
                icon: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Publicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final created = timeago.format(post.createdAt, locale: 'es');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              child: Text(
                (post.countryCode?.toUpperCase() ?? 'CO').substring(0, 1),
              ),
            ),
            title: Text((post.status ?? 'Publicación').toUpperCase()),
            subtitle: Text(created),
            trailing: Text(post.countryCode?.toUpperCase() ?? 'CO'),
          ),

          // Imagen (opcional)
          if ((post.mediaUrl ?? '').isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.mediaUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),

          // Descripción
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(post.description ?? ''),
          ),

          // Footer con contadores — ¡AQUÍ ESTABA EL CRASH!
          // Usa toString() para convertir ints a String antes de pasarlos a Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _IconText(
                  icon: Icons.favorite_border,
                  text: post.likes.toString(),
                ),
                const SizedBox(width: 16),
                _IconText(
                  icon: Icons.mode_comment_outlined,
                  text: post.comments.toString(),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {}, // compartir
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(text), // <-- Text ahora siempre recibe String
      ],
    );
  }
}

/// Modelo tipado (evita errores de tipos al convertir desde Supabase)
class Post {
  final int id;
  final String author;
  final String? description;
  final String? mediaUrl;
  final String? status;
  final String? countryCode;
  final DateTime createdAt;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.author,
    required this.createdAt,
    this.description,
    this.mediaUrl,
    this.status,
    this.countryCode,
    this.likes = 0,
    this.comments = 0,
  });

  factory Post.fromMap(Map<String, dynamic> m) {
    return Post(
      id: (m['id'] as num).toInt(),
      author: (m['author'] as String),
      description: m['description'] as String?,
      mediaUrl: m['media_url'] as String?,
      status: m['status'] as String?,
      countryCode: m['country_code'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      likes: (m['likes'] is num) ? (m['likes'] as num).toInt() : 0,
      comments: (m['comments'] is num) ? (m['comments'] as num).toInt() : 0,
    );
  }
}
