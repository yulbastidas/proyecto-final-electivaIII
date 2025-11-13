import '../../domain/entities/weight_entity.dart';

class WeightModel {
  final String id;
  final String petId;
  final double kg;
  final DateTime notedAt;
  final String? note;

  const WeightModel({
    required this.id,
    required this.petId,
    required this.kg,
    required this.notedAt,
    this.note,
  });

  // Columnas exactas de la tabla
  static const selectColumns = 'id,pet_id,kg,noted_at,note';

  factory WeightModel.fromMap(Map<String, dynamic> m) {
    return WeightModel(
      id: m['id'].toString(),
      petId: m['pet_id'] as String,
      kg: (m['kg'] as num).toDouble(),
      notedAt: DateTime.parse(m['noted_at'] as String),
      note: m['note'] as String?,
    );
  }

  Map<String, dynamic> toInsert({required String uid, required String petId}) =>
      {
        'owner': uid, // para pasar RLS
        'pet_id': petId,
        'kg': kg,
        if (note != null && note!.trim().isNotEmpty) 'note': note,
        // 'noted_at' lo pone el default now()
      };

  Weight toEntity() =>
      Weight(id: id, petId: petId, kg: kg, notedAt: notedAt, note: note);
}
