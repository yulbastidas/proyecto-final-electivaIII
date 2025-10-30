import '../../domain/entities/weight_entity.dart';

class WeightModel {
  final int id;
  final String owner;
  final double kg;
  final DateTime at;

  WeightModel({
    required this.id,
    required this.owner,
    required this.kg,
    required this.at,
  });

  factory WeightModel.fromMap(Map m) => WeightModel(
    id: m['id'],
    owner: m['owner'],
    kg: (m['kg'] as num).toDouble(),
    at: DateTime.parse(m['at'].toString()),
  );

  WeightEntity toEntity() => WeightEntity(id: id, owner: owner, kg: kg, at: at);
}
