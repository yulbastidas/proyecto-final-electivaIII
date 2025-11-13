import '../../domain/entities/health_event_entity.dart';

class HealthEventModel {
  final String id;
  final String petId;
  final String userId;
  final HealthType type;
  final String title;
  final DateTime happenedAt;
  final String? details;

  const HealthEventModel({
    required this.id,
    required this.petId,
    required this.userId,
    required this.type,
    required this.title,
    required this.happenedAt,
    this.details,
  });

  // Columnas reales en la base de datos
  static const selectColumns =
      'id, pet_id, user_id, type, title, happened_at, details';

  factory HealthEventModel.fromMap(Map<String, dynamic> m) {
    return HealthEventModel(
      id: m['id'].toString(),
      petId: m['pet_id'] as String,
      userId: m['user_id'] as String,
      type: healthTypeFromString(m['type'] as String?),
      title: m['title'] as String,
      happenedAt: DateTime.parse(m['happened_at'] as String),
      details: m['details'] as String?,
    );
  }

  HealthEvent toEntity() => HealthEvent(
    id: id,
    userId: userId,
    type: type,
    title: title,
    happenedAt: happenedAt,
    details: details,
  );
}
