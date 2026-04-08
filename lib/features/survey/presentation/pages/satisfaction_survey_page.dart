import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/survey_answer.dart';
import '../providers/survey_providers.dart';

const _questions = <_Question>[
  _Question('q1', 'Como calificas el tiempo de espera?'),
  _Question('q2', 'Que tan claro fue el orden de tus estudios?'),
  _Question('q3', 'Como fue la atencion del personal?'),
  _Question('q4', 'Recomendarias esta sucursal?'),
];

class SatisfactionSurveyPage extends ConsumerStatefulWidget {
  const SatisfactionSurveyPage({super.key});

  @override
  ConsumerState<SatisfactionSurveyPage> createState() =>
      _SatisfactionSurveyPageState();
}

class _SatisfactionSurveyPageState
    extends ConsumerState<SatisfactionSurveyPage> {
  final Map<String, int> _ratings = {};
  bool _submitting = false;

  bool get _complete => _ratings.length == _questions.length;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final answers = _ratings.entries
        .map((e) => SurveyAnswer(questionId: e.key, rating: e.value))
        .toList();
    final submit = ref.read(submitSurveyProvider);
    await submit(SubmitSurveyParams(branchId: 1, answers: answers));
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gracias'),
        content: const Text(
          'Tu opinion nos ayuda a mejorar la atencion en cada sucursal.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encuesta de satisfaccion')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '4 preguntas rapidas. Tarda menos de 30 segundos.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ..._questions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (i) {
                          final value = i + 1;
                          final selected = _ratings[q.id] == value;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _ratings[q.id] = value),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.star_rounded,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _complete && !_submitting ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(54),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar respuestas'),
          ),
        ],
      ),
    );
  }
}

class _Question {
  const _Question(this.id, this.text);
  final String id;
  final String text;
}
