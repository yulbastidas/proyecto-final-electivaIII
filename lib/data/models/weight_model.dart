import '../../domain/entities/weight_entity.dart';

class WeightModel {
  final String id;
  final String petId;
  final String userId;
  final double valueKg; // ✅
  final DateTime notedAt;
  final String? notes; // ✅

  const WeightModel({
    required this.id,
    required this.petId,
    required this.userId,
    required this.valueKg,
    required this.notedAt,
    this.notes,
  });

  // ✅ columnas EXACTAS de la tabla weights
  static const selectColumns = 'id, pet_id, user_id, noted_at, value_kg, notes';

  factory WeightModel.fromMap(Map<String, dynamic> m) {
    return WeightModel(
      id: m['id'].toString(),
      petId: m['pet_id'] as String,
      userId: m['user_id'] as String,
      valueKg: (m['value_kg'] as num).toDouble(), // ✅ value_kg
      notedAt: DateTime.parse(m['noted_at'] as String),
      notes: m['notes'] as String?, // ✅ notes
    );
  }

  Weight toEntity() => Weight(
    id: id,
    petId: petId,
    userId: userId,
    valueKg: valueKg,
    notedAt: notedAt,
    notes: notes,
  );
}
