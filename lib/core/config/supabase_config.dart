// lib/core/config/supabase_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception('Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    }

    await Supabase.initialize(url: url, anonKey: anonKey);

    _initialized = true;
    _dbg('Supabase inicializado');
  }

  /// Cliente global
  static SupabaseClient get client => Supabase.instance.client;

  /// Nombres de buckets/tablas
  static const String bucketPublic = 'pets';
  static const String tableProfiles = 'profiles';
  static const String tablePosts = 'posts';
  static const String tableMessages = 'messages';
  static const String tableMarket = 'market_items';

  /// Logger solo en debug
  static void _dbg(String message) {
    if (kDebugMode) dev.log(message, name: 'SupabaseConfig');
  }
}
