import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class StorageService {
  final _client = SupabaseConfig.client;
  final _bucket = 'posts';

  Future<String?> uploadImage(File file) async {
    final id = const Uuid().v4();
    final path = 'images/$id.jpg';
    await _client.storage
        .from(_bucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    final url = _client.storage.from(_bucket).getPublicUrl(path);
    return url;
  }
}
