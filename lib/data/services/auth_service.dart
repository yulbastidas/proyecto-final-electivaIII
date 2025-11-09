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
      await _client.from('profiles').upsert({
        'id': userId,
        if (fullName != null) 'full_name': fullName,
        'username': (username ?? email.split('@').first),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id'); // <-- clave
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
      await _client.from('profiles').upsert({
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id'); // <-- clave
    }
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();
}
