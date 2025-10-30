import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/storage_service.dart';

class FeedRepositoryImpl implements FeedRepository {
  final _client = SupabaseConfig.client;
  final _storage = StorageService();

  @override
  Future<List<PostEntity>> listPosts() async {
    final rows = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((m) => PostModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<int> createPost({
    required String description,
    required String status,
    String? mediaUrl,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final inserted = await _client
        .from('posts')
        .insert({
          'author': uid,
          'description': description,
          'status': status,
          'media_url': mediaUrl,
          'country_code': 'CO',
        })
        .select('id')
        .single();
    return inserted['id'] as int;
  }

  @override
  Future<List<CommentEntity>> listComments(int postId) async {
    final rows = await _client
        .from('feed_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');
    return (rows as List)
        .map((m) => CommentModel.fromMap(m).toEntity())
        .toList();
  }

  @override
  Future<int> addComment({required int postId, required String text}) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('feed_comments')
        .insert({'post_id': postId, 'author': uid, 'text': text})
        .select('id')
        .single();
    return row['id'] as int;
  }

  @override
  Future<void> deleteOwnComment(int commentId) async {
    await _client.from('feed_comments').delete().eq('id', commentId);
  }

  // helper opcional para subir imagen desde File
  Future<String?> upload(File file) => _storage.uploadImage(file);
}
