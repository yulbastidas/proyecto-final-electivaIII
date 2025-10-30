class HealthEventEntity {
  final int id;
  final String owner;
  final String kind; // vaccine|deworm|medication
  final String? title;
  final DateTime? dueAt;
  final DateTime? lastAt;
  final String? notes;

  HealthEventEntity({
    required this.id,
    required this.owner,
    required this.kind,
    this.title,
    this.dueAt,
    this.lastAt,
    this.notes,
  });
}
