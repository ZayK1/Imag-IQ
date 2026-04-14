import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz.dart';
import '../../store/quiz_store.dart';
import '../../theme.dart';
import '../../widgets/neo_box.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/status_chip.dart';
import 'take_quiz.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String? _activeQuizId;
  QuizAttempt? _lastAttempt;

  @override
  Widget build(BuildContext context) {
    if (_activeQuizId != null) {
      return TakeQuizScreen(
        quizId: _activeQuizId!,
        existingAttempt: _lastAttempt,
        onBack: () => setState(() {
          _activeQuizId = null;
          _lastAttempt = null;
        }),
        onSubmitted: (attempt) => setState(() => _lastAttempt = attempt),
      );
    }

    return Consumer<QuizStore>(
      builder: (context, store, _) {
        final quizzes = store.quizzes
            .where((quiz) => quiz.questions.isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeoBox(
              color: AppColors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Quizzes',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a quiz, step into a focused taking mode, then review exactly where your thinking went off track.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusChip(
                        label: '${quizzes.length} ready to take',
                        icon: Icons.assignment_turned_in_outlined,
                        color: AppColors.blue,
                      ),
                      const StatusChip(
                        label: 'Student mode',
                        icon: Icons.school_outlined,
                        color: AppColors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (quizzes.isEmpty)
              Expanded(
                child: NeoBox(
                  color: AppColors.white,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppColors.border,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.quiz_outlined,
                            size: 44,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Nothing to take yet',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Switch to Teacher mode and publish a few questions first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final aspectRatio = maxWidth >= 1500
                        ? 1.22
                        : maxWidth >= 1100
                        ? 1.16
                        : maxWidth >= 720
                        ? 1.08
                        : 1.45;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxWidth >= 1600 ? 360 : 380,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        return _QuizPickerCard(
                          quiz: quizzes[index],
                          onPressed: () =>
                              setState(() => _activeQuizId = quizzes[index].id),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuizPickerCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onPressed;

  const _QuizPickerCard({required this.quiz, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (quiz.topic.trim().isNotEmpty)
                          StatusChip(
                            label: quiz.topic,
                            icon: Icons.book_outlined,
                            color: AppColors.blue,
                            compact: true,
                          ),
                        StatusChip(
                          label: quiz.focusArea.label,
                          icon: Icons.tune,
                          color: AppColors.purple,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: Text(
                  '${quiz.questions.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          NeoButton(
            label: 'Start Quiz',
            icon: Icons.play_arrow_rounded,
            trailingIcon: Icons.chevron_right,
            color: AppColors.yellow,
            expand: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
