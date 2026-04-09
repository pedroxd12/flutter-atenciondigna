import 'package:flutter_test/flutter_test.dart';
import 'package:aplicacion/features/auth/domain/entities/patient.dart';
import 'package:aplicacion/features/branches/domain/entities/branch.dart';
import 'package:aplicacion/features/studies/domain/entities/study.dart';
import 'package:aplicacion/features/checkin/domain/entities/checkin_pass.dart';
import 'package:aplicacion/features/tracking/domain/entities/tracking_status.dart';
import 'package:aplicacion/features/waiting/domain/entities/wait_status.dart';
import 'package:aplicacion/features/results/domain/entities/study_result.dart';
import 'package:aplicacion/features/survey/domain/entities/survey_answer.dart';

void main() {
  group('Patient entity', () {
    test('should create a patient with all fields', () {
      const patient = Patient(
        id: 'uuid-1',
        email: 'test@mail.com',
        fullName: 'Juan Perez Lopez',
        photoUrl: null,
      );

      expect(patient.id, 'uuid-1');
      expect(patient.email, 'test@mail.com');
      expect(patient.fullName, 'Juan Perez Lopez');
      expect(patient.firstName, 'Juan');
    });

    test('should support equality comparison', () {
      const p1 = Patient(id: '1', email: 'a@b.com', fullName: 'A');
      const p2 = Patient(id: '1', email: 'a@b.com', fullName: 'A');
      const p3 = Patient(id: '2', email: 'c@d.com', fullName: 'B');

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('Branch entity', () {
    test('should create a branch for Coyoacan', () {
      const branch = Branch(
        id: 46,
        name: 'Salud Digna Coyoacan',
        address: 'Av. Universidad 1330',
        distanceKm: 2.5,
        waitTimeMinutes: 15,
        saturationLevel: 'bajo',
        lat: 19.3568,
        lng: -99.1716,
      );

      expect(branch.id, 46);
      expect(branch.name, 'Salud Digna Coyoacan');
      expect(branch.saturationLevel, 'bajo');
    });
  });

  group('Study entity', () {
    test('should create a study with preparations', () {
      const study = Study(
        id: 2,
        name: 'Laboratorio',
        estimatedMinutes: 20,
        requiresPreparation: true,
        preparations: ['Ayuno de 8 horas'],
        requiresMedicalOrder: false,
        area: 'Laboratorio',
      );

      expect(study.requiresPreparation, true);
      expect(study.preparations, contains('Ayuno de 8 horas'));
    });
  });

  group('CheckinPass entity', () {
    test('should generate QR payload', () {
      final pass = CheckinPass(
        token: 'abc123',
        patientId: 'patient-1',
        branchId: 46,
        studyIds: [2, 10],
        issuedAt: DateTime(2026, 4, 9, 9, 0),
        expiresAt: DateTime(2026, 4, 9, 10, 0),
      );

      final payload = pass.toQrPayload();
      expect(payload, startsWith('AD|abc123'));
      expect(payload, contains('patient-1'));
      expect(payload, contains('46'));
    });
  });

  group('TrackingStatus entity', () {
    test('should calculate progress percentage', () {
      const status = TrackingStatus(
        patientName: 'Juan',
        patientId: 'p1',
        hasActiveVisit: true,
        visitStatus: 'en_proceso',
        totalStudies: 3,
        completedStudies: 1,
        currentStudyIndex: 1,
        progressPercent: 33,
        studies: [],
        etaTotalMinutes: 60,
        etaRemainingMinutes: 40,
        saturationLevel: 'medio',
        tips: [],
      );

      expect(status.progressPercent, 33);
      expect(status.hasActiveVisit, true);
      expect(status.completedStudies, 1);
    });
  });

  group('WaitStatus entity', () {
    test('should create wait status', () {
      const status = WaitStatus(
        currentStudy: 'Laboratorio',
        area: 'Lab',
        peopleAhead: 5,
        estimatedMinutes: 15,
        saturationLevel: 'medio',
        isYourTurn: false,
        hasActiveService: true,
      );

      expect(status.peopleAhead, 5);
      expect(status.isYourTurn, false);
      expect(status.hasActiveService, true);
    });

    test('should indicate your turn', () {
      const status = WaitStatus(
        currentStudy: 'Laboratorio',
        area: 'Lab',
        peopleAhead: 0,
        estimatedMinutes: 0,
        saturationLevel: 'bajo',
        isYourTurn: true,
        hasActiveService: true,
      );

      expect(status.isYourTurn, true);
      expect(status.peopleAhead, 0);
    });
  });

  group('StudyResult entity', () {
    test('should identify ready results', () {
      final result = StudyResult(
        id: '1',
        studyName: 'Laboratorio',
        branchName: 'Coyoacan',
        takenAt: DateTime(2026, 4, 9),
        readyAt: DateTime(2026, 4, 9, 12, 0),
        status: 'ready',
      );

      expect(result.isReady, true);
    });

    test('should identify processing results', () {
      final result = StudyResult(
        id: '2',
        studyName: 'Ultrasonido',
        branchName: 'Coyoacan',
        takenAt: DateTime(2026, 4, 9),
        status: 'processing',
      );

      expect(result.isReady, false);
    });
  });

  group('SurveyAnswer', () => {
    test('should create a survey answer', () {
      const answer = SurveyAnswer(questionId: 'espera', rating: 4);

      expect(answer.questionId, 'espera');
      expect(answer.rating, 4);
    });
  });
}
