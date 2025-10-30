import 'package:flutter/foundation.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/health_event_entity.dart';
import '../../domain/entities/weight_entity.dart';

class HealthController extends ChangeNotifier {
  final _repo = HealthRepositoryImpl();

  bool loading = false;
  List<HealthEventEntity> events = [];
  List<WeightEntity> weights = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      events = await _repo.listEvents();
      weights = await _repo.listWeights();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent({
    required String kind, // 'vaccine' | 'deworm' | 'medication'
    String? title,
    DateTime? dueAt,
    DateTime? lastAt,
    String? notes,
  }) async {
    await _repo.addEvent(
      kind: kind,
      title: title,
      dueAt: dueAt,
      lastAt: lastAt,
      notes: notes,
    );
    await load();
  }

  Future<void> deleteEvent(int id) async {
    await _repo.deleteEvent(id);
    await load();
  }

  Future<void> addWeight(double kg, DateTime at) async {
    await _repo.addWeight(kg, at);
    await load();
  }
}
