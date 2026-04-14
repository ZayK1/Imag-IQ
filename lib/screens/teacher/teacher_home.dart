import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz.dart';
import '../../store/quiz_store.dart';
import '../../theme.dart';
import '../../widgets/neo_box.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/status_chip.dart';
import 'quiz_builder.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  String? _selectedQuizId;

  @override
  Widget build(BuildContext context) {
    if (_selectedQuizId == null) {
      return _buildLibraryLanding();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1140;
        final railWidth = constraints.maxWidth >= 1550
            ? 360.0
            : constraints.maxWidth >= 1280
            ? 330.0
            : 300.0;
        final rail = _buildLibraryPanel();
        final canvas = Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedQuizId == null
                ? _buildEmptyState()
                : QuizBuilder(
                    key: ValueKey(_selectedQuizId),
                    quizId: _selectedQuizId!,
                  ),
          ),
        );

        if (stacked) {
          return Column(children: [rail, const SizedBox(height: 18), canvas]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: railWidth, child: rail),
            const SizedBox(width: 24),
            canvas,
          ],
        );
      },
    );
  }

  Widget _buildLibraryLanding() {
    return Consumer<QuizStore>(
      builder: (context, store, _) {
        final quizzes = store.quizzes;

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 1600
                ? 1260.0
                : constraints.maxWidth >= 1200
                ? 1120.0
                : constraints.maxWidth;
            final cardExtent = constraints.maxWidth >= 1400
                ? 320.0
                : constraints.maxWidth >= 900
                ? 300.0
                : 260.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NeoBox(
                        color: AppColors.white,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quiz Library',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose a quiz to edit, or start a new one.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                StatusChip(
                                  label: '${quizzes.length} quizzes',
                                  icon: Icons.library_books_outlined,
                                  color: AppColors.yellow,
                                  compact: true,
                                ),
                                const StatusChip(
                                  label: 'Teacher',
                                  icon: Icons.edit_note,
                                  color: AppColors.orange,
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quizzes.length + 1,
                        gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: cardExtent,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                              childAspectRatio: constraints.maxWidth >= 900
                                  ? 1.12
                                  : 1.02,
                            ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildCreateCard();
                          }

                          return _buildLandingQuizCard(quizzes[index - 1]);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryPanel() {
    return Consumer<QuizStore>(
      builder: (context, store, _) {
        return NeoBox(
          color: AppColors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quiz Library',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your quizzes.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: NeoButton(
                      label: '+',
                      color: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () => _createNewQuiz(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatusChip(
                    label: '${store.quizzes.length} quizzes',
                    icon: Icons.library_books_outlined,
                    color: AppColors.yellow,
                    compact: true,
                  ),
                  const StatusChip(
                    label: 'Teacher workspace',
                    icon: Icons.edit_note,
                    color: AppColors.orange,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (store.quizzes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.45),
                      width: 2.5,
                    ),
                  ),
                  child: const Text(
                    'No quizzes yet. Create one to start building.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: store.quizzes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final quiz = store.quizzes[index];
                      final isSelected = quiz.id == _selectedQuizId;

                      return InkWell(
                        onTap: () => setState(() => _selectedQuizId = quiz.id),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.yellow
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                offset: Offset(
                                  isSelected ? 6 : 3,
                                  isSelected ? 6 : 3,
                                ),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quiz.displayTitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if (quiz.topic.trim().isNotEmpty &&
                                            quiz.displayTitle !=
                                                quiz.topic.trim()) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            quiz.topic,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _deleteQuiz(context, quiz),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.red,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 2.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  StatusChip(
                                    label: quiz.focusArea.label,
                                    icon: Icons.category_outlined,
                                    color: AppColors.purple,
                                    compact: true,
                                  ),
                                  StatusChip(
                                    label: '${quiz.questions.length} questions',
                                    icon: Icons.help_outline,
                                    color: AppColors.blue,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateCard() {
    return GestureDetector(
      onTap: () => _createNewQuiz(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2.5),
                ),
                child: const Icon(Icons.add, size: 28, color: AppColors.ink),
              ),
              const Spacer(),
              const Text(
                'New Quiz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a fresh draft and open it in the builder.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandingQuizCard(Quiz quiz) {
    return GestureDetector(
      onTap: () => setState(() => _selectedQuizId = quiz.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      quiz.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deleteQuiz(context, quiz),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                          width: 2.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (quiz.topic.trim().isNotEmpty &&
                  quiz.displayTitle != quiz.topic.trim()) ...[
                const SizedBox(height: 10),
                Text(
                  quiz.topic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: quiz.focusArea.label,
                    icon: Icons.category_outlined,
                    color: AppColors.purple,
                    compact: true,
                  ),
                  StatusChip(
                    label: '${quiz.questions.length} questions',
                    icon: Icons.help_outline,
                    color: AppColors.yellow,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Text(
                    'Open builder',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return NeoBox(
      key: const ValueKey('empty-state'),
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border, width: 3),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 44,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pick a quiz from the rail',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The builder opens here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewQuiz(BuildContext context) {
    final store = context.read<QuizStore>();
    final id = store.createQuiz('Untitled Quiz', '', FocusArea.general);
    setState(() => _selectedQuizId = id);
  }

  void _deleteQuiz(BuildContext context, Quiz quiz) {
    final store = context.read<QuizStore>();
    store.deleteQuiz(quiz.id);
    if (_selectedQuizId == quiz.id) {
      setState(() => _selectedQuizId = null);
    }
  }
}
