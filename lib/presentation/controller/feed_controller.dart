import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/posts_service.dart';
import '../../domain/entities/post.dart';

class FeedController extends ChangeNotifier {
  final PostsService _svc;

  FeedController(this._svc);

  final TextEditingController textCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String _status = 'Adoption';

  List<Post> items = [];

  bool loading = false;
  bool publishing = false;
  bool loadingMore = false;

  String get status => _status;
  Uint8List? get imageBytes => _imageBytes;

  set status(String v) {
    if (v == _status) return;
    _status = v;
    refresh();
  }

  void setImage(Uint8List? b) {
    _imageBytes = b;
    notifyListeners();
  }

  void disposeAll() {
    textCtrl.dispose();
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();

    try {
      items = await _svc.fetchFeed(status: _status);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> publish() async {
    publishing = true;
    notifyListeners();

    try {
      final created = await _svc.publish(
        status: _status,
        content: textCtrl.text.trim().isEmpty ? null : textCtrl.text.trim(),
        imageBytes: _imageBytes,
        filename: "post_${DateTime.now().millisecondsSinceEpoch}.jpg",
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

  Future<void> toggleLike(int id) async {
    final updated = await _svc.like(id);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> remove(int id) async {
    await _svc.remove(id);
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void loadMore() {
    // No hace nada, pero evita el error.
  }

  Future<void> addComment(Post p, String text) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _svc.addComment(postId: p.id, authorId: userId, text: text);
  }
}
