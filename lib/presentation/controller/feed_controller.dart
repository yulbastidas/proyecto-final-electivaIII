import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

class FeedController extends ChangeNotifier {
  final _repo = FeedRepositoryImpl();

  bool loading = false;
  List<PostEntity> posts = [];

  Future<void> loadPosts() async {
    loading = true;
    notifyListeners();
    try {
      posts = await _repo.listPosts();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Sube la imagen (opcional) y crea el post.
  Future<void> publish({
    required String description,
    required String status,
    File? imageFile,
  }) async {
    loading = true;
    notifyListeners();
    try {
      String? url;
      if (imageFile != null) {
        url = await _repo.upload(imageFile);
      }
      await _repo.createPost(
        description: description,
        status: status,
        mediaUrl: url,
      );
      await loadPosts();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class CommentsController extends ChangeNotifier {
  final _repo = FeedRepositoryImpl();
  bool sending = false;
  List<CommentEntity> comments = [];

  Future<void> load(int postId) async {
    comments = await _repo.listComments(postId);
    notifyListeners();
  }

  Future<void> send(int postId, String text) async {
    if (text.trim().isEmpty) return;
    sending = true;
    notifyListeners();
    try {
      await _repo.addComment(postId: postId, text: text.trim());
      await load(postId);
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> delete(int postId, int commentId) async {
    await _repo.deleteOwnComment(commentId);
    await load(postId);
  }
}
