// lib/data/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (username != null) 'username': username,
      },
    );

    final userId = res.user?.id ?? res.session?.user.id;
    if (userId != null) {
      await _upsertProfileSafe({
        'id': userId,
        if (fullName != null) 'full_name': fullName,
        'username': (username ?? email.split('@').first),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = res.session?.user.id;
    if (userId != null) {
      await _upsertProfileSafe({
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Upsert “seguro”: intenta upsert con onConflict y si falla (400) hace update/insert.
  Future<void> _upsertProfileSafe(Map<String, dynamic> profile) async {
    try {
      // Intento 1: upsert normal
      await _client.from('profiles').upsert(profile, onConflict: 'id');
      return;
    } on PostgrestException catch (_) {
      // Intento 2: fallback sin on_conflict (evita el bug web del ':1')
      final id = profile['id'] as String;
      final exists = await _client
          .from('profiles')
          .select('id')
          .eq('id', id)
          .maybeSingle();

      if (exists != null) {
        final update = Map<String, dynamic>.from(profile)..remove('id');
        if (update.isNotEmpty) {
          await _client.from('profiles').update(update).eq('id', id);
        }
      } else {
        await _client.from('profiles').insert(profile);
      }
    }
  }
}
