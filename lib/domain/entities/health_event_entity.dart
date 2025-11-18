enum HealthType { vaccine, deworm, med }

class HealthEvent {
  final String id;
  final String userId;
  final HealthType type;
  final String title;
  final DateTime happenedAt;
  final String? details;

  const HealthEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.happenedAt,
    this.details,
  });
}

HealthType healthTypeFromString(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();

  for (final t in HealthType.values) {
    if (t.name == v) return t;
  }

  switch (v) {
    case 'vacuna':
    case 'vaccine':
      return HealthType.vaccine;
    case 'desparasitación':
    case 'desparasitacion':
    case 'deworm':
      return HealthType.deworm;
    case 'medicación':
    case 'medicacion':
    case 'medication':
    case 'med':
    case 'meds':
      return HealthType.med;
  }

  return HealthType.med;
}

String healthTypeToString(HealthType t) {
  switch (t) {
    case HealthType.vaccine:
      return 'vaccine';
    case HealthType.deworm:
      return 'deworm';
    case HealthType.med:
      return 'med';
  }
}
