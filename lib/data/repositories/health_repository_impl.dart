import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/weight_entity.dart';
import '../models/weight_model.dart';

abstract class HealthRepository {
  Future<List<Weight>> getWeights(String petId);
  Future<void> addWeight({
    required String petId,
    required double kg,
    String? note,
  });
  Future<void> deleteWeight(String id);
}

class HealthRepositoryImpl implements HealthRepository {
  final SupabaseClient sb;
  final String Function() getUid;
  HealthRepositoryImpl(this.sb, this.getUid);

  @override
  Future<List<Weight>> getWeights(String petId) async {
    final data = await sb
        .from('weights')
        .select(WeightModel.selectColumns)
        .eq('pet_id', petId)
        .order('noted_at', ascending: false);

    final list = (data as List)
        .map((e) => WeightModel.fromMap(e).toEntity())
        .toList();
    return list;
  }

  @override
  Future<void> addWeight({
    required String petId,
    required double kg,
    String? note,
  }) async {
    final uid = getUid();
    await sb.from('weights').insert({
      'owner': uid,
      'pet_id': petId,
      'kg': kg,
      if (note != null && note.trim().isNotEmpty) 'note': note,
      // noted_at => default now()
    });
  }

  @override
  Future<void> deleteWeight(String id) async {
    await sb.from('weights').delete().eq('id', id);
  }
}
