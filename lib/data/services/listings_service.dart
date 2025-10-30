import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/listing.dart';

class ListingsService {
  // Usa el bucket que ya tengas. Intento primero 'pets-media' y luego 'public'.
  static const _candidatesBuckets = ['media'];

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
    required String status, // 'adoption' | 'sale' | 'rescue'
    String? imageUrl,
  }) async {
    await _client.from('listings').insert({
      'title': title,
      'description': description,
      'price': price,
      'status': status,
      'image_url': imageUrl,
    });
  }

  Future<void> delete(int id) async {
    await _client.from('listings').delete().eq('id', id);
  }

  /// Sube bytes y devuelve URL pública. Prueba varios buckets para
  /// evitar el problema de que no te deje crear 'public'.
  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'marketplace/$filename';
    for (final bucket in _candidatesBuckets) {
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
      } catch (_) {
        // probamos el siguiente bucket
      }
    }
    return null;
  }
}
