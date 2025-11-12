class VetPlace {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? openingHours;

  const VetPlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.openingHours,
  });

  bool get is247 => (openingHours ?? '').contains('24/7');

  /// Parser simple de opening_hours (suficiente para patrones comunes).
  bool isOpenNow(DateTime now) {
    final oh = (openingHours ?? '').trim();
    if (oh.isEmpty) return false;
    if (is247) return true;

    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final weekday = days[(now.weekday % 7) - 1];
    final normalized = oh.replaceAll(' ', '');
    final parts = normalized.split(';');
    for (final p in parts) {
      final hasDay = p.contains(weekday) || p.contains('Mo-Su');
      if (!hasDay) continue;
      final m = RegExp(r'(\d{2}):(\d{2})-(\d{2}):(\d{2})').firstMatch(p);
      if (m == null) continue;
      final from = Duration(
        hours: int.parse(m.group(1)!),
        minutes: int.parse(m.group(2)!),
      );
      final to = Duration(
        hours: int.parse(m.group(3)!),
        minutes: int.parse(m.group(4)!),
      );
      final nowD = Duration(hours: now.hour, minutes: now.minute);
      if (nowD >= from && nowD <= to) return true;
    }
    return false;
  }
}
