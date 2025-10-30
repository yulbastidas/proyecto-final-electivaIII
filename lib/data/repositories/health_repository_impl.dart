import '../../core/config/supabase_config.dart';
import '../../domain/entities/health_event_entity.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/repositories/health_repository.dart';
import '../models/health_event_model.dart';
import '../models/weight_model.dart';

class HealthRepositoryImpl implements HealthRepository {
  final _c = SupabaseConfig.client;

  @override
  Future<List<HealthEventEntity>> listEvents() async {
    final rows = await _c
        .from('health_events')
        .select()
        .order('due_at', ascending: true);
    return (rows as List)
        .map((m) => HealthEventModel.fromMap(m).toEntity())
        .toList();
  }

  @override
  Future<int> addEvent({
    required String kind,
    String? title,
    DateTime? dueAt,
    DateTime? lastAt,
    String? notes,
  }) async {
    final uid = _c.auth.currentUser!.id;
    final row = await _c
        .from('health_events')
        .insert({
          'owner': uid,
          'kind': kind,
          'title': title,
          'due_at': dueAt?.toIso8601String(),
          'last_at': lastAt?.toIso8601String(),
          'notes': notes,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _c.from('health_events').delete().eq('id', id);
  }

  @override
  Future<List<WeightEntity>> listWeights() async {
    final rows = await _c.from('weights').select().order('at');
    return (rows as List)
        .map((m) => WeightModel.fromMap(m).toEntity())
        .toList();
  }

  @override
  Future<int> addWeight(double kg, DateTime at) async {
    final uid = _c.auth.currentUser!.id;
    final row = await _c
        .from('weights')
        .insert({'owner': uid, 'kg': kg, 'at': at.toIso8601String()})
        .select('id')
        .single();
    return row['id'] as int;
  }
}
