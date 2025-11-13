// lib/domain/entities/health_event_entity.dart

/// Tipos de evento de salud admitidos.
enum HealthKind {
  vaccine, // vacuna
  deworm, // desparasitación
  surgery, // cirugía
  checkup, // chequeo general
  medication, // medicación
  other, // otros
}

/// Entidad de EVENTO DE SALUD (dominio)
class HealthEvent {
  final String id;
  final String userId;
  final HealthKind kind;
  final String title;
  final DateTime happenedAt;
  final String? details;

  const HealthEvent({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.happenedAt,
    this.details,
  });
}

/// Helper: parsea string → HealthKind (case-insensitive, incluye alias comunes)
HealthKind healthKindFromString(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();

  // Coincidencia directa con .name
  for (final k in HealthKind.values) {
    if (k.name == v) return k;
  }

  // Aliases
  switch (v) {
    case 'vacuna':
    case 'vaccine':
      return HealthKind.vaccine;

    case 'desparasitacion':
    case 'desparasitación':
    case 'deworm':
      return HealthKind.deworm;

    case 'cirugia':
    case 'cirugía':
    case 'surgery':
      return HealthKind.surgery;

    case 'chequeo':
    case 'check':
    case 'checkup':
      return HealthKind.checkup;

    case 'med':
    case 'meds':
    case 'medicacion':
    case 'medicación':
    case 'medication':
      return HealthKind.medication;
  }

  return HealthKind.other;
}

/// Helper inverso: HealthKind → string a guardar en DB
String healthKindToString(HealthKind k) => k.name;
