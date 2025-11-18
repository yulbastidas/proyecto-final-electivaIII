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

  /// Verifica si la veterinaria está abierta en el momento dado.
  bool isOpenNow(DateTime now) {
    final hours = (openingHours ?? '').trim();
    if (hours.isEmpty) return false;
    if (is247) return true;

    const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final currentDay = weekdays[(now.weekday - 1) % 7];

    final normalized = hours.replaceAll(' ', '');
    final segments = normalized.split(';');

    for (final segment in segments) {
      if (!_matchesDay(segment, currentDay)) continue;

      final timeRange = _extractTimeRange(segment);
      if (timeRange == null) continue;

      if (_isWithinRange(now, timeRange)) return true;
    }

    return false;
  }

  bool _matchesDay(String segment, String currentDay) {
    return segment.contains(currentDay) || segment.contains('Mo-Su');
  }

  ({Duration start, Duration end})? _extractTimeRange(String segment) {
    final match = RegExp(
      r'(\d{2}):(\d{2})-(\d{2}):(\d{2})',
    ).firstMatch(segment);
    if (match == null) return null;

    return (
      start: Duration(
        hours: int.parse(match.group(1)!),
        minutes: int.parse(match.group(2)!),
      ),
      end: Duration(
        hours: int.parse(match.group(3)!),
        minutes: int.parse(match.group(4)!),
      ),
    );
  }

  bool _isWithinRange(DateTime now, ({Duration start, Duration end}) range) {
    final currentTime = Duration(hours: now.hour, minutes: now.minute);
    return currentTime >= range.start && currentTime <= range.end;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VetPlace && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VetPlace(id: $id, name: $name, lat: $lat, lon: $lon)';
}
