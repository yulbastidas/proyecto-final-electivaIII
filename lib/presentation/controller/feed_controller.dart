import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/posts_service.dart';
import '../../domain/entities/post.dart';

class FeedController extends ChangeNotifier {
  final PostsService svc;

  FeedController(this.svc);

  final textCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String _status = 'Adoption';

  List<Post> items = [];

  bool loading = false;
  bool publishing = false;
  bool loadingMore = false;

  String get status => _status;
  Uint8List? get imageBytes => _imageBytes;

  // -----------------------------------------------------------
  // Estado
  // -----------------------------------------------------------
  set status(String v) {
    if (_status == v) return;
    _status = v;
    refresh();
  }

  void setImage(Uint8List? bytes) {
    _imageBytes = bytes;
    notifyListeners();
  }

  void disposeAll() {
    textCtrl.dispose();
  }

  // -----------------------------------------------------------
  // Cargar feed
  // -----------------------------------------------------------
  Future<void> refresh() async {
    loading = true;
    notifyListeners();

    try {
      items = await svc.fetchFeed(status: _status);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // Publicar post
  // -----------------------------------------------------------
  Future<void> publish() async {
    publishing = true;
    notifyListeners();

    try {
      final created = await svc.publish(
        status: _status,
        content: textCtrl.text.trim().isEmpty ? null : textCtrl.text.trim(),
        imageBytes: _imageBytes,
        filename: 'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        countryCode: 'CO',
      );

      items = [created, ...items];

      textCtrl.clear();
      _imageBytes = null;
    } finally {
      publishing = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // Likes
  // -----------------------------------------------------------
  Future<void> toggleLike(int id) async {
    final updated = await svc.like(id);

    final i = items.indexWhere((e) => e.id == id);
    if (i != -1) {
      items[i] = updated;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------
  // Eliminar post
  // -----------------------------------------------------------
  Future<void> remove(int id) async {
    await svc.remove(id);
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // -----------------------------------------------------------
  // Placeholder para scroll infinito
  // -----------------------------------------------------------
  void loadMore() {}

  // -----------------------------------------------------------
  // Comentarios
  // -----------------------------------------------------------
  Future<void> addComment(Post p, String text) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await svc.addComment(postId: p.id, authorId: uid, text: text);
  }
}
