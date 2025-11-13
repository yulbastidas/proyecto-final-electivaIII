import '../entities/weight_entity.dart';

abstract class HealthRepository {
  Future<List<Weight>> getWeights(String uid);

  Future<void> addWeight({
    required String uid,
    required double kg,
    String? note,
    DateTime? date,
  });
}
