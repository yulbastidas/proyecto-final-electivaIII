import '../../domain/entities/health_event_entity.dart';

class HealthEventModel {
  final String id;
  final String userId;
  final HealthKind kind; // en BD se llama "type"
  final String title;
  final DateTime happenedAt; // en BD es date; parsea OK
  final String? details; // en BD se llama "notes"

  const HealthEventModel({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.happenedAt,
    this.details,
  });

  // columnas reales en la BD
  static const selectColumns = 'id,user_id,type,title,happened_at,notes';

  factory HealthEventModel.fromMap(Map<String, dynamic> m) {
    return HealthEventModel(
      id: m['id'].toString(), // bigint -> String
      userId: m['user_id'] as String,
      kind: healthKindFromString(m['type'] as String),
      title: m['title'] as String,
      happenedAt: DateTime.parse(m['happened_at'] as String),
      details: m['notes'] as String?, // mapear notes -> details
    );
  }

  Map<String, dynamic> toInsert(String uid) => {
    'user_id': uid,
    'type': healthKindToString(kind), // usamos "type" de la BD
    'title': title,
    'happened_at': happenedAt.toIso8601String(),
    if (details != null && details!.trim().isNotEmpty) 'notes': details,
  };

  HealthEvent toEntity() => HealthEvent(
    id: id,
    userId: userId,
    kind: kind,
    title: title,
    happenedAt: happenedAt,
    details: details,
  );
}
