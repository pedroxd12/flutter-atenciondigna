import '../../features/studies/domain/entities/study.dart';

/// Sistema de mensajes contextuales para guiar al paciente durante su visita.
///
/// Los mensajes se generan dinamicamente segun:
///   - El nombre del paciente
///   - La sucursal donde se encuentra
///   - Los estudios que tiene programados
///   - Las reglas de negocio medicas
class PatientMessages {
  PatientMessages._();

  // ──────────────────────────────────────────────────────
  // 1. MENSAJES GENERALES DEL FLUJO
  // ──────────────────────────────────────────────────────

  /// Bienvenida al llegar a la sucursal.
  static String welcome(String nombre, String sucursal) =>
      '!Hola, $nombre! Que gusto recibirte en Salud Digna sucursal $sucursal. '
      'Para iniciar tu atencion, escanea tu codigo QR en el area de recepcion.';

  /// Estimacion de tiempo total.
  static String timeEstimate(String nombre, int minutosTotal) =>
      '$nombre, calculamos que completaras tus estudios aproximadamente en '
      '$minutosTotal minutos. Vamos a hacer que tu visita sea lo mas rapida posible!';

  /// Llamado a la atencion — mantenerse pendiente de la app.
  static String stayAlert(String nombre) =>
      '$nombre, mantente muy atento a la App! Si se libera un espacio antes '
      'o podemos optimizar tu ruta, te avisaremos de inmediato para ahorrarte '
      'tiempo de espera.';

  /// Orquestacion por preparacion — estudios sin prep primero.
  static String preparationOrder(String nombre) =>
      '$nombre, para que termines mas rapido, te enviaremos primero a los '
      'estudios que NO requieren preparacion y dejaremos al final los que si '
      'la necesitan.';

  // ──────────────────────────────────────────────────────
  // 2. MENSAJES POR REGLAS DE NEGOCIO
  // ──────────────────────────────────────────────────────

  // — Mastografia —

  /// Validacion de orden medica para mastografia.
  static String mastographyOrder(String nombre, String motivo) =>
      '$nombre, para tu Mastografia, recuerda que al $motivo, es obligatorio '
      'presentar la orden medica de tu especialista para poder realizarlo.';

  // — Papanicolaou —

  /// Prioridad de secuencia con papanicolaou.
  static String papSequence(String nombre, String estudioSiguiente) =>
      '$nombre, para garantizar la precision de tus resultados, iniciaremos '
      'con tu Papanicolaou antes de realizar tu $estudioSiguiente.';

  // — Laboratorio y Ultrasonido —

  /// Vigencia de muestra de orina.
  static String urineSampleValidity(String nombre) =>
      '$nombre, si traes tu muestra de orina desde casa, recuerda que no debe '
      'pasar de las 2 horas de haber sido recolectada para que sea valida '
      'para tus analisis.';

  /// Prioridad por ayuno — laboratorio antes de ultrasonido.
  static String fastingPriority(String nombre) =>
      '$nombre, como tu estudio de laboratorio requiere ayuno previo, '
      'realizaremos primero la toma de muestra y despues pasaremos a tu '
      'ultrasonido.';

  // — Tomografia, Resonancia y Densitometria —

  /// Puntualidad critica para estudios largos.
  static String punctualityCritical(String nombre, String estudio) =>
      '$nombre, tu $estudio es un procedimiento de mayor duracion. Es muy '
      'importante ser puntual; de lo contrario, el sistema te asignara una '
      'nueva cita automaticamente.';

  /// Secuencia densitometria antes de contraste.
  static String densitometryFirst(String nombre, String estudio) =>
      '$nombre, hoy iniciaremos con tu Densitometria antes de tu $estudio '
      'con contraste. Este orden es fundamental para la calidad de tu '
      'diagnostico.';

  // — Urgencia —

  /// Prioridad por malestar/urgencia.
  static String urgencyPriority(String nombre) =>
      '$nombre, entendemos tu situacion. Al ser una necesidad urgente, '
      'nuestro sistema te ha priorizado en la fila para que seas atendido '
      'lo antes posible.';

  // ──────────────────────────────────────────────────────
  // 3. GENERADOR DE TIPS CONTEXTUALES
  // ──────────────────────────────────────────────────────

  /// Genera una lista de mensajes relevantes basados en los estudios del
  /// paciente. Cada entrada es un (icono, mensaje).
  static List<({String icon, String message})> tipsForStudies(
    String nombre,
    List<Study> studies,
  ) {
    final tips = <({String icon, String message})>[];

    final names = studies.map((s) => s.name.toLowerCase()).toList();
    final areas = studies.map((s) => s.area.toLowerCase()).toSet();
    final hasPrep = studies.any((s) => s.requiresPreparation);
    final hasNoPrep = studies.any((s) => !s.requiresPreparation);

    // Tip: orquestacion por preparacion
    if (hasPrep && hasNoPrep) {
      tips.add((icon: 'route', message: preparationOrder(nombre)));
    }

    // Tip: mastografia
    if (names.any((n) => n.contains('mastograf'))) {
      tips.add((
        icon: 'medical',
        message: mastographyOrder(
          nombre,
          'ser menor de 35 anos o tener menos de 6 meses de tu ultimo estudio',
        ),
      ));
    }

    // Tip: papanicolaou + combinaciones
    final hasPap = names.any((n) => n.contains('papanicolaou') || n.contains('pap'));
    if (hasPap) {
      String? siguiente;
      if (names.any((n) => n.contains('cultivo vaginal'))) {
        siguiente = 'Cultivo vaginal';
      } else if (names.any((n) => n.contains('vph'))) {
        siguiente = 'VPH';
      } else if (names.any((n) => n.contains('ultrasonido transvaginal'))) {
        siguiente = 'Ultrasonido transvaginal';
      }
      if (siguiente != null) {
        tips.add((icon: 'sequence', message: papSequence(nombre, siguiente)));
      }
    }

    // Tip: muestra de orina
    if (areas.contains('laboratorio') &&
        names.any((n) =>
            n.contains('orina') ||
            n.contains('urocultivo') ||
            n.contains('examen general de orina'))) {
      tips.add((icon: 'sample', message: urineSampleValidity(nombre)));
    }

    // Tip: ayuno — laboratorio + ultrasonido
    final hasLab = areas.contains('laboratorio');
    final hasUltrasound = names.any((n) => n.contains('ultrasonido'));
    final requiresFasting = studies.any(
      (s) => s.requiresPreparation && s.area.toLowerCase() == 'laboratorio',
    );
    if (hasLab && hasUltrasound && requiresFasting) {
      tips.add((icon: 'fasting', message: fastingPriority(nombre)));
    }

    // Tip: puntualidad critica para estudios largos
    for (final s in studies) {
      final lower = s.name.toLowerCase();
      if (lower.contains('tomograf') ||
          lower.contains('resonancia') ||
          lower.contains('densitometr')) {
        tips.add((
          icon: 'punctual',
          message: punctualityCritical(nombre, s.name),
        ));
        break; // solo un mensaje
      }
    }

    // Tip: densitometria antes de contraste
    final hasDensitometry = names.any((n) => n.contains('densitometr'));
    if (hasDensitometry) {
      final contraste = studies.where(
        (s) =>
            s.name.toLowerCase().contains('tomograf') ||
            s.name.toLowerCase().contains('resonancia'),
      );
      if (contraste.isNotEmpty) {
        tips.add((
          icon: 'density',
          message: densitometryFirst(nombre, contraste.first.name),
        ));
      }
    }

    return tips;
  }

  /// Icono de Material Design para cada tipo de tip.
  static String iconNameForTip(String tipIcon) => tipIcon;
}
