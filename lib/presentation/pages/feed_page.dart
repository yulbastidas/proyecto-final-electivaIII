import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import 'comments_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final repo = FeedRepositoryImpl();
  final text = TextEditingController();
  String status = 'adoption';
  List<PostEntity> posts = [];
  File? picked;

  Future<void> _load() async {
    final data = await repo.listPosts();
    setState(() => posts = data);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => picked = File(x.path));
  }

  Future<void> _publish() async {
    String? url;
    if (picked != null) {
      url = await repo.upload(picked!);
    }
    await repo.createPost(
      description: text.text.trim(),
      status: status,
      mediaUrl: url,
    );
    text.clear();
    picked = null;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("¿Qué publicas hoy?"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: text,
                    decoration: const InputDecoration(
                      hintText: 'Venta / adopción / rescatado...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: status,
                        items: const [
                          DropdownMenuItem(
                            value: 'adoption',
                            child: Text('Adopción'),
                          ),
                          DropdownMenuItem(value: 'sale', child: Text('Venta')),
                          DropdownMenuItem(
                            value: 'rescued',
                            child: Text('Rescatado'),
                          ),
                        ],
                        onChanged: (v) => setState(() => status = v!),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pick,
                        icon: const Icon(Icons.photo),
                        label: const Text('Foto'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _publish,
                        child: const Text('Publicar'),
                      ),
                    ],
                  ),
                  if (picked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.file(
                        picked!,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final p in posts)
            _PostTile(
              post: p,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CommentsPage(post: p)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final PostEntity post;
  final VoidCallback onOpen;
  const _PostTile({required this.post, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(post.authorId.substring(0, 2).toUpperCase()),
                  ),
                  const SizedBox(width: 8),
                  Text(post.status.toUpperCase()),
                  const Spacer(),
                  Text(
                    '${post.createdAt.hour}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (post.mediaUrl != null)
                Image.network(post.mediaUrl!, height: 180, fit: BoxFit.cover),
              if (post.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(post.description!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
