// lib/core/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

class SupabaseConfig {
  SupabaseConfig._();

  /// Cliente único para toda la app
  static SupabaseClient get client => Supabase.instance.client;

  /// Storage bucket (debe existir en Supabase → Storage)
  static const String bucketPublic = 'pets';

  /// Tablas
  static const String tablePosts = 'posts';
  static const String tableProfiles = 'profiles';
  static const String tableMessages = 'messages';
  static const String tableMarket = 'market_items';

  /// Logger solo en debug (no usa `print`)
  static void log(String message) {
    if (kDebugMode) {
      dev.log(message, name: 'SupabaseConfig');
    }
  }
}
