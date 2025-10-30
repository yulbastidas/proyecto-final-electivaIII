import '../../domain/entities/health_event_entity.dart';

class HealthEventModel {
  final int id;
  final String owner;
  final String kind;
  final String? title;
  final DateTime? dueAt;
  final DateTime? lastAt;
  final String? notes;

  HealthEventModel({
    required this.id,
    required this.owner,
    required this.kind,
    this.title,
    this.dueAt,
    this.lastAt,
    this.notes,
  });

  factory HealthEventModel.fromMap(Map m) => HealthEventModel(
    id: m['id'],
    owner: m['owner'],
    kind: m['kind'],
    title: m['title'],
    dueAt: m['due_at'] == null ? null : DateTime.parse(m['due_at']),
    lastAt: m['last_at'] == null ? null : DateTime.parse(m['last_at']),
    notes: m['notes'],
  );

  HealthEventEntity toEntity() => HealthEventEntity(
    id: id,
    owner: owner,
    kind: kind,
    title: title,
    dueAt: dueAt,
    lastAt: lastAt,
    notes: notes,
  );
}
