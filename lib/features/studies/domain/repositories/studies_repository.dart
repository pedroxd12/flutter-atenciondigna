import '../entities/study.dart';

abstract class StudiesRepository {
  /// Lista de estudios del paciente para hoy, ya en el orden recomendado
  /// por el motor de reglas (sin preparacion -> con preparacion).
  Future<List<Study>> getTodaysStudies();
}
