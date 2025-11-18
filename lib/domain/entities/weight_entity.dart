class Weight {
  final String id;
  final String petId;
  final String userId;
  final double valueKg;
  final DateTime notedAt;
  final String? notes;

  const Weight({
    required this.id,
    required this.petId,
    required this.userId,
    required this.valueKg,
    required this.notedAt,
    this.notes,
  });
}
