import 'package:flutter/foundation.dart';
import '../../domain/entities/weight_entity.dart';
import '../../data/repositories/health_repository_impl.dart';

class HealthController extends ChangeNotifier {
  final HealthRepository repo;
  HealthController(this.repo);

  List<Weight> _weights = [];
  List<Weight> get weights => _weights;

  // Stub de eventos para que compile tu page (puedes implementar luego)
  List<Object> _events = [];
  List<Object> get events => _events;

  Future<void> load(String petId) async {
    _weights = await repo.getWeights(petId);
    notifyListeners();
  }

  Future<void> addWeight(String petId, double kg, {String? note}) async {
    await repo.addWeight(petId: petId, kg: kg, note: note);
    await load(petId);
  }

  Future<void> deleteWeight(String petId, String id) async {
    await repo.deleteWeight(id);
    await load(petId);
  }

  // Placeholders para que no truene tu page
  Future<void> addEvent() async {}
  Future<void> deleteEvent(String id) async {}
}
