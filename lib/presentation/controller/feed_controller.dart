// lib/presentation/controller/feed_controller.dart
import 'package:flutter/foundation.dart';
import 'package:pets/domain/entities/post.dart';
import 'package:pets/data/services/posts_service.dart';

class FeedController extends ChangeNotifier {
  final PostsService service;
  FeedController(this.service);

  final List<Post> items = [];
  bool loading = false;
  String? filterStatus; // 'rescued' | 'adoption' | 'sale'

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    loading = true;
    if (refresh) items.clear();
    notifyListeners();

    final data = await service.fetchFeed(
      status: filterStatus,
      limit: 30,
      offset: items.length,
    );
    items.addAll(data);
    loading = false;
    notifyListeners();
  }

  Future<void> create({
    required String content,
    required String status,
    List<int>? imageBytes,
    String? filename,
  }) async {
    final post = await service.publish(
      content: content,
      status: status,
      imageBytes: imageBytes,
      filename: filename,
    );
    items.insert(0, post);
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final updated = await service.likeToggle(postId);
    final idx = items.indexWhere((e) => e.id == postId);
    if (idx != -1) {
      items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> delete(String postId) async {
    await service.remove(postId);
    items.removeWhere((e) => e.id == postId);
    notifyListeners();
  }
}
