import '../entities/health_event_entity.dart';
import '../entities/weight_entity.dart';

abstract class HealthRepository {
  Future<List<HealthEventEntity>> listEvents();
  Future<int> addEvent({
    required String kind,
    String? title,
    DateTime? dueAt,
    DateTime? lastAt,
    String? notes,
  });
  Future<void> deleteEvent(int id);

  Future<List<WeightEntity>> listWeights();
  Future<int> addWeight(double kg, DateTime at);
}
