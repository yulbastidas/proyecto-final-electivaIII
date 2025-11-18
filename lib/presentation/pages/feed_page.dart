// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/feed_controller.dart';
import '../../data/services/posts_service.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../widgets/post_item.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final FeedController c;

  @override
  void initState() {
    super.initState();
    final repo = FeedRepositoryImpl(Supabase.instance.client);
    final svc = PostsService(repo);
    c = FeedController(svc);
    c.refresh();
  }

  @override
  void dispose() {
    c.disposeAll();
    c.dispose();
    super.dispose();
  }

  Future<void> _pickImageWeb() async {
    if (!kIsWeb) return;

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;

    if (input.files == null || input.files!.isEmpty) return;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(input.files!.first);

    await reader.onLoadEnd.first;
    c.setImage(reader.result as Uint8List?);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Feed'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: c.loading ? null : c.refresh,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildComposer(),
                const SizedBox(height: 12),
                _buildFilters(),
                const SizedBox(height: 12),
                _buildPosts(),
                const SizedBox(height: 8),
                _buildLoadMore(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- COMPOSER ----------------
  Widget _buildComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: c.textCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '¿Qué estás pensando?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: c.status,
                    items: const [
                      DropdownMenuItem(
                        value: 'Adoption',
                        child: Text('Adoption'),
                      ),
                      DropdownMenuItem(value: 'Sale', child: Text('Sale')),
                      DropdownMenuItem(
                        value: 'Rescued',
                        child: Text('Rescued'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) c.status = v;
                    },
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _pickImageWeb,
                  icon: const Icon(Icons.image_outlined),
                ),
              ],
            ),
            if (c.imageBytes != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  c.imageBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: c.publishing ? null : c.publish,
                child: c.publishing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTROS ----------------
  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      children: [_filter('Adoption'), _filter('Sale'), _filter('Rescued')],
    );
  }

  Widget _filter(String value) {
    return FilterChip(
      label: Text(value),
      selected: c.status == value,
      onSelected: (_) {
        c.status = value;
        c.refresh();
      },
    );
  }

  // ---------------- POSTS ----------------
  Widget _buildPosts() {
    if (c.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: c.items.map((Post p) {
        return PostItem(
          post: p,
          onLike: () => c.toggleLike(p.id),
          onDelete: () => c.remove(p.id),
          onComment: (_) {},
        );
      }).toList(),
    );
  }

  // ---------------- LOAD MORE ----------------
  Widget _buildLoadMore() {
    if (c.loadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: TextButton.icon(
        onPressed: c.loadMore,
        icon: const Icon(Icons.expand_more),
        label: const Text('Cargar más'),
      ),
    );
  }
}
