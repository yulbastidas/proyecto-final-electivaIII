import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/post.dart';
import '../../data/services/posts_service.dart';
import '../widgets/post_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_text_field.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _service = PostsService();
  late Future<List<Post>> _future;
  @override
  void initState() {
    super.initState();
    _future = _service.fetchPosts();
  }

  Future<void> _refresh() async =>
      setState(() => _future = _service.fetchPosts());

  Future<void> _openCreate() async {
    final desc = TextEditingController();
    String status = 'adoption';
    File? image;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nuevo post',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: desc,
              hint: '¿Qué publicas hoy?',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: status,
                    items: const [
                      DropdownMenuItem(
                        value: 'adoption',
                        child: Text('Adopción'),
                      ),
                      DropdownMenuItem(value: 'sale', child: Text('Venta')),
                      DropdownMenuItem(value: 'rescue', child: Text('Rescate')),
                    ],
                    onChanged: (v) => status = v as String,
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () async {
                    final x = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (x != null) image = File(x.path);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Publicar',
              onPressed: () async {
                Navigator.pop(context);
                await _service.createPost(
                  description: desc.text,
                  imageFile: image,
                  status: status,
                );
                if (context.mounted) _refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final posts = snap.data as List<Post>? ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    label: 'Publicar',
                    icon: Icons.add,
                    onPressed: _openCreate,
                  ),
                );
              }
              final p = posts[i - 1];
              return PostCard(
                post: p,
                onDelete: () async {
                  await _service.deleteOwnPost(p.id);
                  _refresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}
