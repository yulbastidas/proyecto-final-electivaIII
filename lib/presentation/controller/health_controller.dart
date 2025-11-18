import 'package:flutter/material.dart';

import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/health_event_entity.dart';
import '../../data/repositories/health_repository_impl.dart';

class HealthController extends ChangeNotifier {
  final HealthRepository repo;
  HealthController(this.repo);

  List<Weight> _weights = [];
  List<HealthEvent> _events = [];

  List<Weight> get weights => _weights;
  List<HealthEvent> get events => _events;

  Future<void> load(String petId) async {
    _weights = await repo.getWeights(petId);
    _events = await repo.getEvents(petId);
    notifyListeners();
  }

  Future<void> addWeight({
    required String petId,
    required double valueKg,
    String? note,
  }) async {
    await repo.addWeight(petId: petId, valueKg: valueKg, note: note);
    await load(petId);
  }

  Future<void> deleteWeight({required String petId, required String id}) async {
    await repo.deleteWeight(id);
    await load(petId);
  }

  Future<void> addEvent({
    required String petId,
    required HealthType type,
    required String title,
    DateTime? happenedAt,
    String? details,
  }) async {
    await repo.addEvent(
      petId: petId,
      type: type,
      title: title,
      happenedAt: happenedAt,
      details: details,
    );
    await load(petId);
  }

  Future<void> deleteEvent({required String petId, required String id}) async {
    await repo.deleteEvent(id);
    await load(petId);
  }
}
