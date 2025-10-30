import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Handles Supabase initialization and provides a global client instance.
/// The configuration values are loaded from the .env file.
class SupabaseConfig {
  static Future<void> init() async {
    // Get values from .env file
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    // Validate existence
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    }

    // Initialize Supabase
    await Supabase.initialize(url: url.trim(), anonKey: anonKey.trim());

    print('✅ Supabase initialized successfully');
  }

  // Global Supabase client
  static SupabaseClient get client => Supabase.instance.client;
}
