// lib/domain/repositories/feed_repository.dart
import 'package:pets/domain/entities/post.dart';

abstract class FeedRepository {
  Future<List<Post>> getFeed({String? status, int limit, int offset});
  Future<Post> createPost({
    required String content,
    required String status,
    List<int>? imageBytes, // puedes usar Uint8List en la impl
    String? filename,
  });
  Future<Post> toggleLike({required String postId});
  Future<void> deletePost(String postId);
}
