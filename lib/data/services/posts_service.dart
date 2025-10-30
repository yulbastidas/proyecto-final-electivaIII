// lib/data/services/posts_service.dart
import 'dart:typed_data';
import 'package:pets/domain/entities/post.dart';
import 'package:pets/domain/repositories/feed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final FeedRepository repo;
  PostsService(this.repo);

  // API limpia
  Future<List<Post>> fetchFeed({
    String? status,
    int limit = 30,
    int offset = 0,
  }) => repo.getFeed(status: status, limit: limit, offset: offset);

  Future<Post> publish({
    required String content,
    required String status,
    List<int>? imageBytes,
    String? filename,
  }) => repo.createPost(
    content: content,
    status: status,
    imageBytes: imageBytes,
    filename: filename,
  );

  Future<Post> likeToggle(String postId) => repo.toggleLike(postId: postId);
  Future<void> remove(String postId) => repo.deletePost(postId);

  // ---- Wrappers (compatibilidad con tu UI actual) ----
  Future<List<Post>> getLocalizedFeed({
    String? status,
    int limit = 30,
    int offset = 0,
  }) => fetchFeed(status: status, limit: limit, offset: offset);

  Future<Post> createPost({
    required String content,
    required String status,
    List<int>? imageBytes,
    String? filename,
  }) => publish(
    content: content,
    status: status,
    imageBytes: imageBytes,
    filename: filename,
  );

  Future<Post> toggleLike(String postId) => likeToggle(postId);
  Future<void> deletePost(String postId) => remove(postId);

  /// Tu UI llama a esto directo: lo exponemos aquí.
  Future<String?> uploadImageBytes(
    List<int> bytes,
    String filename, {
    String bucket = 'posts',
  }) async {
    final client = Supabase.instance.client;
    final path = 'feed/$filename';
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
