import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tracking_status.dart';

/// Timeline vertical tipo stepper que muestra todos los estudios del paciente.
/// - Completado: checkmark verde
/// - Actual: punto azul pulsante
/// - Pendiente: circulo gris
class StudyTimeline extends StatelessWidget {
  const StudyTimeline({
    super.key,
    required this.studies,
    required this.currentIndex,
  });

  final List<StudyStep> studies;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TUS ESTUDIOS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(studies.length, (i) {
          final study = studies[i];
          final isLast = i == studies.length - 1;
          return _TimelineItem(
            study: study,
            isCurrent: i == currentIndex,
            isLast: isLast,
          );
        }),
      ],
    );
  }
}

class _TimelineItem extends StatefulWidget {
  const _TimelineItem({
    required this.study,
    required this.isCurrent,
    required this.isLast,
  });

  final StudyStep study;
  final bool isCurrent;
  final bool isLast;

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotCtrl;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _dotAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) _dotCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_dotCtrl.isAnimating) {
      _dotCtrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _dotCtrl.isAnimating) {
      _dotCtrl.stop();
      _dotCtrl.reset();
    }
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.study;
    final isCompleted = s.isCompleted;
    final isCurrent = widget.isCurrent;
    final isCalled = s.isCalled;

    final dotColor = isCompleted
        ? AppColors.success
        : isCurrent
            ? (isCalled ? AppColors.success : const Color(0xFF3B82F6))
            : AppColors.border;

    final lineColor = isCompleted ? AppColors.success : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Dot
                if (isCompleted)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  )
                else if (isCurrent)
                  AnimatedBuilder(
                    animation: _dotAnim,
                    builder: (_, __) => Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: _dotAnim.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                  ),
                // Line
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? (isCalled
                          ? AppColors.success.withValues(alpha: 0.08)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.06))
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? (isCalled
                            ? AppColors.success.withValues(alpha: 0.3)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.2))
                        : AppColors.border,
                    width: isCurrent ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        _SmallBadge(status: s.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.area,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (s.folio != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Folio: ${s.folio}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (isCurrent && isCalled) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Dirigete al area asignada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (isCompleted && s.serviceMinutes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Completado en ${s.serviceMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      'en_espera' => ('Espera', AppColors.warning.withValues(alpha: 0.15), AppColors.warning),
      'llamado' => ('Llamado', AppColors.success.withValues(alpha: 0.15), AppColors.success),
      'en_proceso' => ('En curso', const Color(0xFF3B82F6).withValues(alpha: 0.15), const Color(0xFF3B82F6)),
      'completado' => ('Listo', AppColors.success.withValues(alpha: 0.15), AppColors.success),
      _ => (status, AppColors.inputFill, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
