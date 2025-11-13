import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/health_event_entity.dart';
import '../models/weight_model.dart';
import '../models/health_event_model.dart';

abstract class HealthRepository {
  // PESOS
  Future<List<Weight>> getWeights(String petId);
  Future<void> addWeight({
    required String petId,
    required double valueKg,
    String? note,
  });
  Future<void> deleteWeight(String id);

  // EVENTOS DE SALUD
  Future<List<HealthEvent>> getEvents(String petId);
  Future<void> addEvent({
    required String petId,
    required HealthType type,
    required String title,
    DateTime? happenedAt,
    String? details,
  });
  Future<void> deleteEvent(String id);
}

class HealthRepositoryImpl implements HealthRepository {
  final SupabaseClient sb;
  final String Function() getUid;

  HealthRepositoryImpl(this.sb, this.getUid);

  // ---------- PESOS ----------
  @override
  Future<List<Weight>> getWeights(String petId) async {
    final data = await sb
        .from('weights')
        .select(WeightModel.selectColumns)
        .eq('pet_id', petId)
        .order('noted_at', ascending: false);

    return (data as List)
        .map((e) => WeightModel.fromMap(e).toEntity())
        .toList();
  }

  @override
  Future<void> addWeight({
    required String petId,
    required double valueKg,
    String? note,
  }) async {
    final uid = getUid();
    await sb.from('weights').insert({
      'user_id': uid,
      'pet_id': petId,
      'value_kg': valueKg,
      if (note != null && note.trim().isNotEmpty) 'notes': note,
    });
  }

  @override
  Future<void> deleteWeight(String id) async {
    await sb.from('weights').delete().eq('id', id);
  }

  // ---------- EVENTOS DE SALUD ----------
  @override
  Future<List<HealthEvent>> getEvents(String petId) async {
    final data = await sb
        .from('health_events')
        .select(HealthEventModel.selectColumns)
        .eq('pet_id', petId)
        .order('happened_at', ascending: false);

    return (data as List)
        .map((e) => HealthEventModel.fromMap(e).toEntity())
        .toList();
  }

  @override
  Future<void> addEvent({
    required String petId,
    required HealthType type,
    required String title,
    DateTime? happenedAt,
    String? details,
  }) async {
    final uid = getUid();

    await sb.from('health_events').insert({
      'user_id': uid,
      'pet_id': petId,

      // ⛔ ESTA ES LA COLUMNA REAL EN LA BD
      // Guarda solo: "vaccine" | "deworm" | "med"
      'type': healthTypeToString(type),

      'title': title,

      'happened_at': (happenedAt ?? DateTime.now()).toIso8601String(),

      if (details != null && details.trim().isNotEmpty) 'details': details,
    });
  }

  @override
  Future<void> deleteEvent(String id) async {
    await sb.from('health_events').delete().eq('id', id);
  }
}
