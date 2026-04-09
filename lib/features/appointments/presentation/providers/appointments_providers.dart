import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/appointments_remote_datasource.dart';
import '../../domain/appointment.dart';

final appointmentsRemoteProvider = Provider<AppointmentsRemoteDataSource>(
  (ref) => AppointmentsRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Parametros para consultar slots disponibles del dia.
class SlotsQuery {
  const SlotsQuery({
    required this.branchId,
    required this.date,
    required this.studyIds,
  });
  final int branchId;
  final String date;
  final List<int> studyIds;

  @override
  bool operator ==(Object other) =>
      other is SlotsQuery &&
      other.branchId == branchId &&
      other.date == date &&
      _listEq(other.studyIds, studyIds);

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(branchId, date, Object.hashAll(studyIds));
}

class AvailableSlot {
  const AvailableSlot({
    required this.date,
    required this.hour,
    required this.time,
    required this.waitMin,
    required this.serviceMin,
    required this.totalEstimatedMin,
    required this.saturationLevel,
    required this.score,
    required this.reason,
    required this.orderedStudyIds,
    required this.citasRegistradas,
    required this.capacidadLibre,
    required this.recommended,
    required this.tag,
  });
  final String date;
  final int hour;
  final String time;
  final int waitMin;
  final int serviceMin;
  final double totalEstimatedMin;
  final String saturationLevel;
  final double score;
  final String reason;
  final List<int> orderedStudyIds;

  /// Cuantas citas ya hay registradas a esa hora.
  final int citasRegistradas;

  /// Cuantos consultorios quedan libres a esa hora.
  final int capacidadLibre;

  /// True si el motor lo marca como el mejor slot.
  final bool recommended;

  /// Tag visible: "Recomendado", "Buena opcion", "Alta demanda", "".
  final String tag;

  factory AvailableSlot.fromJson(Map<String, dynamic> j) {
    final wait = (j['waitMin'] as num?)?.toInt() ?? 0;
    final service = (j['serviceMin'] as num?)?.toInt() ?? 0;
    final total = (j['totalEstimatedMin'] as num?)?.toDouble() ??
        (wait + service).toDouble();
    return AvailableSlot(
      date: (j['date'] as String?) ?? '',
      hour: (j['hour'] as num?)?.toInt() ?? 0,
      time: (j['time'] as String?) ?? '00:00',
      waitMin: wait,
      serviceMin: service,
      totalEstimatedMin: total,
      saturationLevel: (j['saturationLevel'] as String?) ?? 'medio',
      score: (j['score'] as num?)?.toDouble() ?? 1.0,
      reason: (j['reason'] as String?) ?? '',
      orderedStudyIds: ((j['orderedStudyIds'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      citasRegistradas: (j['citasRegistradas'] as num?)?.toInt() ?? 0,
      capacidadLibre: (j['capacidadLibre'] as num?)?.toInt() ?? 0,
      recommended: (j['recommended'] as bool?) ?? false,
      tag: (j['tag'] as String?) ?? '',
    );
  }
}

class SlotsResponse {
  const SlotsResponse({
    required this.slots,
    required this.message,
    required this.weeklyOpen,
    required this.weeklyClose,
  });
  final List<AvailableSlot> slots;
  final String? message;
  final int weeklyOpen;
  final int weeklyClose;
}

/// Slots disponibles para un (sucursal, fecha, estudios).
final availableSlotsProvider =
    FutureProvider.family<SlotsResponse, SlotsQuery>((ref, q) async {
  final raw = await ref.watch(appointmentsRemoteProvider).availableSlots(
        branchId: q.branchId,
        date: q.date,
        studyIds: q.studyIds,
        topN: 12,
      );
  final list = (raw['slots'] as List<dynamic>?) ?? const [];
  final wh = raw['weeklyHours'] as Map<String, dynamic>?;
  return SlotsResponse(
    slots: list
        .cast<Map<String, dynamic>>()
        .map(AvailableSlot.fromJson)
        .toList(),
    message: raw['message'] as String?,
    weeklyOpen: (wh?['open'] as num?)?.toInt() ?? 0,
    weeklyClose: (wh?['close'] as num?)?.toInt() ?? 0,
  );
});

// ──────────────────────────────────────────────
// Check-time: validar hora elegida por el paciente
// ──────────────────────────────────────────────

class CheckTimeQuery {
  const CheckTimeQuery({
    required this.branchId,
    required this.date,
    required this.time,
    required this.studyIds,
  });
  final int branchId;
  final String date;
  final String time; // HH:mm
  final List<int> studyIds;

  @override
  bool operator ==(Object other) =>
      other is CheckTimeQuery &&
      other.branchId == branchId &&
      other.date == date &&
      other.time == time &&
      SlotsQuery._listEq(other.studyIds, studyIds);

  @override
  int get hashCode =>
      Object.hash(branchId, date, time, Object.hashAll(studyIds));
}

class StudyAvailability {
  const StudyAvailability({
    required this.studyId,
    required this.studyName,
    required this.available,
    required this.waitMin,
    required this.serviceMin,
    required this.saturationLevel,
    required this.suggestedTime,
    required this.roomsTotal,
    required this.roomsOccupied,
  });
  final int studyId;
  final String studyName;
  final bool available;
  final int waitMin;
  final int serviceMin;
  final String saturationLevel;
  final String? suggestedTime;
  final int roomsTotal;
  final int roomsOccupied;

  factory StudyAvailability.fromJson(Map<String, dynamic> j) {
    return StudyAvailability(
      studyId: (j['studyId'] as num).toInt(),
      studyName: j['studyName'] as String? ?? '',
      available: j['available'] as bool? ?? false,
      waitMin: (j['waitMin'] as num?)?.toInt() ?? 0,
      serviceMin: (j['serviceMin'] as num?)?.toInt() ?? 0,
      saturationLevel: j['saturationLevel'] as String? ?? 'medio',
      suggestedTime: j['suggestedTime'] as String?,
      roomsTotal: (j['roomsTotal'] as num?)?.toInt() ?? 0,
      roomsOccupied: (j['roomsOccupied'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecommendedSlot {
  const RecommendedSlot({
    required this.time,
    required this.waitMin,
    required this.totalEstimatedMin,
    required this.saturationLevel,
    required this.reason,
  });
  final String time;
  final int waitMin;
  final int totalEstimatedMin;
  final String saturationLevel;
  final String reason;

  factory RecommendedSlot.fromJson(Map<String, dynamic> j) {
    return RecommendedSlot(
      time: j['time'] as String? ?? '',
      waitMin: (j['waitMin'] as num?)?.toInt() ?? 0,
      totalEstimatedMin: (j['totalEstimatedMin'] as num?)?.toInt() ?? 0,
      saturationLevel: j['saturationLevel'] as String? ?? 'medio',
      reason: j['reason'] as String? ?? '',
    );
  }
}

class CheckTimeResponse {
  const CheckTimeResponse({
    required this.feasible,
    required this.reason,
    required this.studies,
    required this.totalEstimatedMin,
    required this.orderedStudyIds,
    required this.recommendedSlot,
    required this.weeklyOpen,
    required this.weeklyClose,
  });
  final bool feasible;
  final String? reason;
  final List<StudyAvailability> studies;
  final int totalEstimatedMin;
  final List<int> orderedStudyIds;
  final RecommendedSlot? recommendedSlot;
  final int weeklyOpen;
  final int weeklyClose;

  factory CheckTimeResponse.fromJson(Map<String, dynamic> j) {
    final studies = (j['studies'] as List<dynamic>?) ?? [];
    final rec = j['recommendedSlot'] as Map<String, dynamic>?;
    final wh = j['weeklyHours'] as Map<String, dynamic>?;
    return CheckTimeResponse(
      feasible: j['feasible'] as bool? ?? false,
      reason: j['reason'] as String?,
      studies: studies
          .cast<Map<String, dynamic>>()
          .map(StudyAvailability.fromJson)
          .toList(),
      totalEstimatedMin: (j['totalEstimatedMin'] as num?)?.toInt() ?? 0,
      orderedStudyIds:
          ((j['orderedStudyIds'] as List<dynamic>?) ?? [])
              .map((e) => (e as num).toInt())
              .toList(),
      recommendedSlot: rec != null ? RecommendedSlot.fromJson(rec) : null,
      weeklyOpen: (wh?['open'] as num?)?.toInt() ?? 0,
      weeklyClose: (wh?['close'] as num?)?.toInt() ?? 0,
    );
  }
}

final checkTimeProvider =
    FutureProvider.family<CheckTimeResponse, CheckTimeQuery>((ref, q) async {
  final raw = await ref.watch(appointmentsRemoteProvider).checkTime(
        branchId: q.branchId,
        date: q.date,
        time: q.time,
        studyIds: q.studyIds,
      );
  return CheckTimeResponse.fromJson(raw);
});

class CreateAppointmentParams {
  CreateAppointmentParams({
    required this.branchId,
    required this.date,
    required this.time,
    required this.studyIds,
  });
  final int branchId;
  final String date;
  final String? time;
  final List<int> studyIds;
}

class SmartCreateParams {
  SmartCreateParams({
    required this.branchId,
    required this.date,
    required this.studyIds,
    this.prioridad = 'cita',
    this.horaApertura = 7,
    this.horaCierre = 20,
    this.confirm = true,
  });
  final int branchId;
  final String date;
  final List<int> studyIds;
  final String prioridad;
  final int horaApertura;
  final int horaCierre;
  final bool confirm;
}

final smartCreateProvider =
    Provider<Future<Map<String, dynamic>> Function(SmartCreateParams)>(
  (ref) => (params) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null) {
      throw Exception('Necesitas iniciar sesion para agendar');
    }
    return ref.read(appointmentsRemoteProvider).smartCreate(
          patientId: patientId,
          branchId: params.branchId,
          date: params.date,
          studyIds: params.studyIds,
          prioridad: params.prioridad,
          horaApertura: params.horaApertura,
          horaCierre: params.horaCierre,
          confirm: params.confirm,
        );
  },
);

final createAppointmentProvider =
    Provider<Future<Appointment> Function(CreateAppointmentParams)>(
  (ref) => (params) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null) {
      throw Exception('Necesitas iniciar sesion para agendar');
    }
    return ref.read(appointmentsRemoteProvider).create(
          patientId: patientId,
          branchId: params.branchId,
          date: params.date,
          time: params.time,
          studyIds: params.studyIds,
        );
  },
);
