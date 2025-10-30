import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';
import '../../data/services/posts_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_composer.dart';
import 'dart:typed_data';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _svc = PostsService();
  bool _loading = true;
  List<Post> _posts = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _posts = await _svc.getLocalizedFeed();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _create({
    required String description,
    required String status,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    String? url;
    if (imageBytes != null && filename != null) {
      url = await _svc.uploadImageBytes(bytes: imageBytes, filename: filename);
    }
    await _svc.createPost(
      description: description,
      status: status,
      mediaUrl: url,
    );
    await _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  PostComposer(onCreate: _create),
                  const SizedBox(height: 12),
                  for (final p in _posts)
                    PostCard(
                      post: p,
                      onLike: () => _svc
                          .toggleLike(p.id, like: true)
                          .then((_) => _load()),
                      onDelete: () =>
                          _svc.deletePost(p.id).then((_) => _load()),
                      onComment: () {},
                    ),
                ],
              ),
            ),
    );
  }
}
