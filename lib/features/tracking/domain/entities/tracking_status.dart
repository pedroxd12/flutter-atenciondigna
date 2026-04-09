import 'package:equatable/equatable.dart';

/// Estado de un estudio individual dentro del tracking.
class StudyStep extends Equatable {
  const StudyStep({
    required this.id,
    required this.name,
    required this.area,
    required this.status,
    required this.order,
    required this.estimatedMinutes,
    this.serviceMinutes,
    this.folio,
    this.peopleAhead,
    this.preparationTip,
    this.educationalInfo,
    this.locationHint,
  });

  final int id;
  final String name;
  final String area;
  final String status; // en_espera, llamado, en_proceso, completado
  final int order;
  final int estimatedMinutes;
  final int? serviceMinutes;
  final String? folio;
  final int? peopleAhead;
  final String? preparationTip;
  final String? educationalInfo;
  final String? locationHint;

  bool get isCompleted => status == 'completado';
  bool get isCalled => status == 'llamado';
  bool get isInProgress => status == 'en_proceso';
  bool get isWaiting => status == 'en_espera';

  factory StudyStep.fromJson(Map<String, dynamic> j) => StudyStep(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        area: j['area'] as String? ?? '',
        status: j['status'] as String? ?? 'en_espera',
        order: (j['order'] as num?)?.toInt() ?? 0,
        estimatedMinutes: (j['estimatedMinutes'] as num?)?.toInt() ?? 0,
        serviceMinutes: (j['serviceMinutes'] as num?)?.toInt(),
        folio: j['folio'] as String?,
        peopleAhead: (j['peopleAhead'] as num?)?.toInt(),
        preparationTip: j['preparationTip'] as String?,
        educationalInfo: j['educationalInfo'] as String?,
        locationHint: j['locationHint'] as String?,
      );

  @override
  List<Object?> get props => [id, status, order, peopleAhead];
}

/// Informacion de la sucursal.
class TrackingBranch extends Equatable {
  const TrackingBranch({
    required this.id,
    required this.name,
    this.address,
  });

  final int id;
  final String name;
  final String? address;

  factory TrackingBranch.fromJson(Map<String, dynamic> j) => TrackingBranch(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        address: j['address'] as String?,
      );

  @override
  List<Object?> get props => [id, name];
}

/// Estado completo del tracking del paciente.
class TrackingStatus extends Equatable {
  const TrackingStatus({
    required this.patientName,
    required this.patientId,
    required this.hasActiveVisit,
    required this.visitStatus,
    required this.totalStudies,
    required this.completedStudies,
    required this.currentStudyIndex,
    required this.progressPercent,
    this.currentStudy,
    this.nextStudy,
    required this.studies,
    required this.etaTotalMinutes,
    required this.etaRemainingMinutes,
    required this.saturationLevel,
    this.branch,
    this.message,
    required this.tips,
    this.serverTime,
  });

  final String patientName;
  final String patientId;
  final bool hasActiveVisit;
  final String visitStatus;
  final int totalStudies;
  final int completedStudies;
  final int currentStudyIndex;
  final int progressPercent;
  final StudyStep? currentStudy;
  final StudyStep? nextStudy;
  final List<StudyStep> studies;
  final int etaTotalMinutes;
  final int etaRemainingMinutes;
  final String saturationLevel;
  final TrackingBranch? branch;
  final String? message;
  final List<String> tips;
  final String? serverTime;

  factory TrackingStatus.fromJson(Map<String, dynamic> j) {
    final studiesJson = j['studies'] as List<dynamic>? ?? [];
    final tipsJson = j['tips'] as List<dynamic>? ?? [];
    final currentJson = j['currentStudy'] as Map<String, dynamic>?;
    final nextJson = j['nextStudy'] as Map<String, dynamic>?;
    final branchJson = j['branch'] as Map<String, dynamic>?;

    return TrackingStatus(
      patientName: j['patientName'] as String? ?? '',
      patientId: j['patientId'] as String? ?? '',
      hasActiveVisit: j['hasActiveVisit'] as bool? ?? false,
      visitStatus: j['visitStatus'] as String? ?? '',
      totalStudies: (j['totalStudies'] as num?)?.toInt() ?? 0,
      completedStudies: (j['completedStudies'] as num?)?.toInt() ?? 0,
      currentStudyIndex: (j['currentStudyIndex'] as num?)?.toInt() ?? 0,
      progressPercent: (j['progressPercent'] as num?)?.toInt() ?? 0,
      currentStudy:
          currentJson != null ? StudyStep.fromJson(currentJson) : null,
      nextStudy: nextJson != null ? StudyStep.fromJson(nextJson) : null,
      studies: studiesJson
          .cast<Map<String, dynamic>>()
          .map(StudyStep.fromJson)
          .toList(),
      etaTotalMinutes: (j['etaTotalMinutes'] as num?)?.toInt() ?? 0,
      etaRemainingMinutes: (j['etaRemainingMinutes'] as num?)?.toInt() ?? 0,
      saturationLevel: j['saturationLevel'] as String? ?? 'bajo',
      branch: branchJson != null ? TrackingBranch.fromJson(branchJson) : null,
      message: j['message'] as String?,
      tips: tipsJson.cast<String>(),
      serverTime: j['serverTime'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        patientId,
        hasActiveVisit,
        visitStatus,
        completedStudies,
        currentStudyIndex,
        progressPercent,
      ];
}
