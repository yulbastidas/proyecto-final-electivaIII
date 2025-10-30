// lib/data/repositories/feed_repository_impl.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pets/domain/repositories/feed_repository.dart';
import 'package:pets/data/models/post_model.dart';
import 'package:pets/domain/entities/post.dart';

class FeedRepositoryImpl implements FeedRepository {
  final SupabaseClient client;

  /// Asegúrate de tener un bucket en Storage, p.ej. "posts"
  final String bucketName;

  FeedRepositoryImpl(this.client, {this.bucketName = 'posts'});

  @override
  Future<List<Post>> getFeed({
    String? status,
    int limit = 30,
    int offset = 0,
  }) async {
    // Aplica filtros ANTES de order(), porque eq no existe después de .order()
    var sel = client.from('posts').select('*');
    if (status != null && status.isNotEmpty) {
      sel = sel.eq('status', status);
    }

    final List<dynamic> data = await sel
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data
        .map((e) => PostModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Post> createPost({
    required String content,
    required String status,
    List<int>? imageBytes,
    String? filename,
  }) async {
    String? imageUrl;

    if (imageBytes != null && filename != null) {
      final path = 'feed/$filename';
      await client.storage
          .from(bucketName)
          .uploadBinary(
            path,
            Uint8List.fromList(imageBytes), // <- corrige List<int> -> Uint8List
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      imageUrl = client.storage.from(bucketName).getPublicUrl(path);
    }

    final userId = client.auth.currentUser?.id ?? 'anonymous';

    final inserted =
        await client
                .from('posts')
                .insert({
                  'user_id': userId,
                  'content': content,
                  'status': status,
                  'image_url': imageUrl,
                })
                .select()
                .single()
            as Map<String, dynamic>;

    return PostModel.fromMap(inserted);
  }

  @override
  Future<Post> toggleLike({required String postId}) async {
    // Evita condiciones no booleanas y operadores mal formados
    final row =
        await client
                .from('posts')
                .select('likes')
                .eq('id', postId)
                .maybeSingle()
            as Map<String, dynamic>?;

    final likesVal = row?['likes'];
    final currentLikes = likesVal is int
        ? likesVal
        : int.tryParse('$likesVal') ?? 0;

    final updated =
        await client
                .from('posts')
                .update({'likes': currentLikes + 1})
                .eq('id', postId)
                .select()
                .single()
            as Map<String, dynamic>;

    return PostModel.fromMap(updated);
  }

  @override
  Future<void> deletePost(String postId) async {
    await client.from('posts').delete().eq('id', postId);
  }
}
