// lib/presentation/controller/feed_controller.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/services/posts_service.dart';
import '../../domain/entities/post.dart';

class FeedController extends ChangeNotifier {
  final PostsService _svc;
  FeedController(this._svc);

  // --- Estado de UI ---
  final TextEditingController textCtrl = TextEditingController();
  String _status = 'Adoption';
  Uint8List? _imageBytes;

  bool loading = false;
  bool publishing = false;
  bool loadingMore = false;

  // --- Datos ---
  List<Post> items = [];

  // --- Getters/Setters usados por FeedPage ---
  String get status => _status;
  set status(String v) {
    if (_status == v) return;
    _status = v;
    refresh(); // al cambiar la pestaña, refresca el feed
  }

  Uint8List? get imageBytes => _imageBytes;

  // --- Helpers ---
  void disposeAll() {
    textCtrl.dispose();
    _imageBytes = null;
  }

  void setImage(Uint8List? bytes) {
    _imageBytes = bytes;
    notifyListeners();
  }

  // --- Acciones ---
  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      // 👉 tu PostsService.fetchFeed NO acepta offset/limit: los quitamos
      items = await _svc.fetchFeed(status: _status);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loadingMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      // Si tu servicio no soporta paginación aún, hacemos un no-op corto.
      // Cuando lo tengas, reemplaza por una llamada real a _svc.fetchMore(...)
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } finally {
      loadingMore = false;
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

  Future<void> toggleLike(int postId) async {
    final updated = await _svc.like(postId);
    final i = items.indexWhere((e) => e.id == updated.id);
    if (i != -1) {
      items[i] = updated;
      notifyListeners();
    }
  }

  Future<void> remove(int postId) async {
    await _svc.remove(postId);
    items.removeWhere((e) => e.id == postId);
    notifyListeners();
  }

  // Placeholder para comentarios (no rompe compilación si lo llamas).
  Future<void> addCommentIfSupported(Post p, String text) async {
    // Implementa aquí si luego agregas comentarios en el backend.
  }
}
