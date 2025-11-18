import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/listing.dart';

class ListingsService {
  static const _buckets = ['media'];
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Listing>> getAll() async {
    final res = await _client
        .from('listings')
        .select()
        .order('created_at', ascending: false);

    return (res as List)
        .map((m) => Listing.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String title,
    required String description,
    required double price,
    String? imageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user');

    await _client.from('listings').insert({
      'title': title,
      'description': description,
      'price': price,
      'status': 'Sale',
      'image_url': imageUrl,
      'author': user.id,
    });
  }

  Future<void> delete(String id) async {
    await _client.from('listings').delete().eq('id', id);
  }

  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'marketplace/$filename';

    for (final bucket in _buckets) {
      try {
        await _client.storage
            .from(bucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/*',
              ),
            );
        return _client.storage.from(bucket).getPublicUrl(path);
      } catch (_) {}
    }

    return null;
  }
}
