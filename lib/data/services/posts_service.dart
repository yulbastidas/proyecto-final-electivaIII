import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/post_model.dart';

class PostsService {
  final SupabaseClient _db = SupabaseConfig.client;

  Future<String> _userCountry() async {
    final uid = _db.auth.currentUser!.id;
    final p = await _db
        .from(SupabaseConfig.tableProfiles)
        .select()
        .eq('id', uid)
        .single();
    return (p['country_code'] ?? 'CO') as String;
  }

  Future<List<Post>> getLocalizedFeed() async {
    final cc = await _userCountry();
    final rows = await _db
        .from(SupabaseConfig.tablePosts)
        .select()
        .eq('country_code', cc)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Post.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final path = 'p_${DateTime.now().millisecondsSinceEpoch}_$filename';
    await _db.storage
        .from(SupabaseConfig.bucketPublic)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _db.storage.from(SupabaseConfig.bucketPublic).getPublicUrl(path);
  }

  Future<void> createPost({
    required String description,
    required String status,
    String? mediaUrl,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final cc = await _userCountry();
    await _db.from(SupabaseConfig.tablePosts).insert({
      'author': uid,
      'description': description,
      'status': status,
      'country_code': cc,
      'media_url': mediaUrl,
    });
  }

  Future<void> toggleLike(String postId, {required bool like}) async {
    try {
      await _db.rpc(
        'increment_likes',
        params: {'p_post_id': postId, 'p_delta': like ? 1 : -1},
      );
    } catch (_) {
      final row = await _db
          .from(SupabaseConfig.tablePosts)
          .select('likes')
          .eq('id', postId)
          .maybeSingle();
      final current = (row?['likes'] ?? 0) as int;
      await _db
          .from(SupabaseConfig.tablePosts)
          .update({'likes': current + (like ? 1 : -1)})
          .eq('id', postId);
    }
  }

  Future<void> deletePost(String postId) =>
      _db.from(SupabaseConfig.tablePosts).delete().eq('id', postId);
}
