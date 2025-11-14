import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pets/domain/repositories/feed_repository.dart';
import 'package:pets/data/models/post_model.dart';
import 'package:pets/data/models/comment_model.dart';
import 'package:pets/domain/entities/post.dart';
import 'package:pets/domain/entities/comment_entity.dart';

class FeedRepositoryImpl implements FeedRepository {
  final SupabaseClient client;
  final String bucketName;

  FeedRepositoryImpl(this.client, {this.bucketName = 'posts'});

  @override
  Future<List<Post>> getFeed({
    String? status,
    int limit = 30,
    int offset = 0,
  }) async {
    var q = client.from('posts').select('*');

    if (status != null && status.isNotEmpty) {
      q = q.eq('status', status);
    }

    final List data = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data
        .map((e) => PostModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Post> createPost({
    String? content,
    required String status,
    List<int>? imageBytes,
    String? filename,
    String? countryCode,
  }) async {
    String? mediaUrl;

    if (imageBytes != null && filename != null) {
      final path = 'feed/$filename';

      await client.storage
          .from(bucketName)
          .uploadBinary(
            path,
            Uint8List.fromList(imageBytes),
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      mediaUrl = client.storage.from(bucketName).getPublicUrl(path);
    }

    final inserted = await client
        .from('posts')
        .insert({
          'status': status,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (content != null) 'content': content,
          if (countryCode != null) 'country_code': countryCode,
        })
        .select()
        .single();

    return PostModel.fromMap(inserted);
  }

  @override
  Future<Post> toggleLike(int postId) async {
    final row = await client
        .from('posts')
        .select('likes')
        .eq('id', postId)
        .maybeSingle();

    final current = row?['likes'] is num
        ? row!['likes']
        : int.tryParse("${row?['likes']}") ?? 0;

    final updated = await client
        .from('posts')
        .update({'likes': current + 1})
        .eq('id', postId)
        .select()
        .single();

    return PostModel.fromMap(updated);
  }

  @override
  Future<void> deletePost(int postId) async {
    await client.from('posts').delete().eq('id', postId);
  }

  @override
  Future<CommentEntity> addComment({
    required int postId,
    required String authorId,
    required String text,
  }) async {
    final inserted = await client
        .from('comments')
        .insert({'post_id': postId, 'author': authorId, 'body': text})
        .select()
        .single();

    return CommentModel.fromMap(inserted).toEntity();
  }
}
