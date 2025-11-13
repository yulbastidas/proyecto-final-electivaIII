class Weight {
  final String id;
  final String petId;
  final double kg;
  final DateTime notedAt;
  final String? note;

  const Weight({
    required this.id,
    required this.petId,
    required this.kg,
    required this.notedAt,
    this.note,
  });
}
