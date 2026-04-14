import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/quiz.dart';
import '../../services/ai_service.dart';
import '../../store/quiz_store.dart';
import '../../theme.dart';
import '../../widgets/neo_box.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/reveal_in.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/thinking_surface.dart';

enum _StudentStage { intro, taking, results }

class TakeQuizScreen extends StatefulWidget {
  final String quizId;
  final QuizAttempt? existingAttempt;
  final VoidCallback onBack;
  final ValueChanged<QuizAttempt> onSubmitted;

  const TakeQuizScreen({
    super.key,
    required this.quizId,
    this.existingAttempt,
    required this.onBack,
    required this.onSubmitted,
  });

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final Map<String, int> _answers = {};
  QuizAttempt? _attempt;
  _StudentStage _stage = _StudentStage.intro;

  final Map<String, QuizQuestion> _practiceQuestions = {};
  final Map<String, int?> _practiceAnswers = {};
  final Map<String, bool> _practiceLoading = {};
  final Map<String, String?> _practiceErrors = {};

  @override
  void initState() {
    super.initState();
    _attempt = widget.existingAttempt;
    if (_attempt != null) {
      _answers.addAll(_attempt!.answers);
      _stage = _StudentStage.results;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.read<QuizStore>().getQuiz(widget.quizId);
    if (quiz == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildTopBar(quiz),
        const SizedBox(height: 18),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: switch (_stage) {
              _StudentStage.intro => _buildIntro(quiz),
              _StudentStage.taking => _buildTaking(quiz),
              _StudentStage.results => _buildResults(quiz),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(Quiz quiz) {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
                  SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          StatusChip(
            label: switch (_stage) {
              _StudentStage.intro => 'Ready',
              _StudentStage.taking =>
                '${_answers.length}/${quiz.questions.length}',
              _StudentStage.results => 'Reviewed',
            },
            icon: switch (_stage) {
              _StudentStage.intro => Icons.flag_outlined,
              _StudentStage.taking => Icons.edit_outlined,
              _StudentStage.results => Icons.check_circle_outline,
            },
            color: switch (_stage) {
              _StudentStage.intro => AppColors.blue,
              _StudentStage.taking => AppColors.yellow,
              _StudentStage.results => AppColors.green,
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(Quiz quiz) {
    return SingleChildScrollView(
      key: const ValueKey('intro'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 48),
            child: RevealIn(
              key: ValueKey('quiz-intro-${quiz.id}'),
              child: NeoBox(
                color: AppColors.white,
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border, width: 4),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 34,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      quiz.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      quiz.topic.trim().isEmpty
                          ? 'A focused quiz.'
                          : 'A focused check-in on ${quiz.topic}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        StatusChip(
                          label: '${quiz.questions.length} questions',
                          icon: Icons.check_circle_outline,
                          color: AppColors.yellow,
                        ),
                        StatusChip(
                          label: quiz.topic.trim().isEmpty
                              ? 'General topic'
                              : quiz.topic,
                          icon: Icons.menu_book_outlined,
                          color: AppColors.blue,
                        ),
                        StatusChip(
                          label: quiz.focusArea.label,
                          icon: Icons.tune,
                          color: AppColors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: NeoButton(
                            label: 'Back to Quizzes',
                            icon: Icons.arrow_back,
                            color: AppColors.white,
                            expand: true,
                            onPressed: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: NeoButton(
                            label: 'Let\'s Go',
                            icon: Icons.play_arrow_rounded,
                            color: AppColors.green,
                            expand: true,
                            onPressed: () =>
                                setState(() => _stage = _StudentStage.taking),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaking(Quiz quiz) {
    final allAnswered = _answers.length == quiz.questions.length;

    return LayoutBuilder(
      key: const ValueKey('taking'),
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1400
            ? 920.0
            : constraints.maxWidth >= 1100
            ? 960.0
            : constraints.maxWidth >= 860
            ? 900.0
            : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                RevealIn(
                  key: ValueKey('taking-progress-${quiz.id}'),
                  beginOffset: const Offset(0, 0.015),
                  child: NeoBox(
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            quiz.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusChip(
                          label:
                              '${_answers.length} / ${quiz.questions.length}',
                          icon: Icons.assignment_turned_in_outlined,
                          color: AppColors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...quiz.questions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: RevealIn(
                              key: ValueKey(
                                'taking-question-${entry.value.id}',
                              ),
                              delay: Duration(
                                milliseconds: 40 + (entry.key * 45),
                              ),
                              beginOffset: const Offset(0, 0.022),
                              child: _TakingQuestionCard(
                                question: entry.value,
                                index: entry.key,
                                selectedIndex: _answers[entry.value.id],
                                onSelected: (value) => setState(
                                  () => _answers[entry.value.id] = value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        RevealIn(
                          key: ValueKey(
                            'taking-submit-${quiz.id}-${_answers.length}',
                          ),
                          delay: const Duration(milliseconds: 120),
                          beginOffset: const Offset(0, 0.03),
                          child: Center(
                            child: SizedBox(
                              width: 300,
                              child: NeoButton(
                                label: allAnswered
                                    ? 'Submit Quiz'
                                    : 'Answer all questions',
                                icon: Icons.send_outlined,
                                color: allAnswered
                                    ? AppColors.green
                                    : Colors.grey.shade300,
                                expand: true,
                                onPressed: allAnswered
                                    ? () => _submitQuiz(quiz)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults(Quiz quiz) {
    final attempt = _attempt!;
    final score = attempt.score;
    final percentage = attempt.total == 0
        ? 0
        : ((score / attempt.total) * 100).round();
    final stampColor = percentage >= 70
        ? AppColors.green
        : percentage >= 40
        ? AppColors.yellow
        : AppColors.red;

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.only(bottom: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevealIn(
                key: ValueKey('results-score-${quiz.id}-${attempt.score}'),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.08,
                          child: Container(
                            width: 320,
                            height: 210,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.20),
                                width: 6,
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: -0.05,
                          child: NeoBox(
                            color: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 26,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'FINAL SCORE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.4,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '$score',
                                        style: const TextStyle(fontSize: 64),
                                      ),
                                      TextSpan(
                                        text: '/${attempt.total}',
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: AppColors.ink.withValues(
                                            alpha: 0.42,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stampColor,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        offset: Offset(4, 4),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '$percentage%  ${_scoreLabel(percentage)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Review Answers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              ...quiz.questions.asMap().entries.map((entry) {
                final question = entry.value;
                final selectedIndex = attempt.answers[question.id];
                final isCorrect = selectedIndex == question.correctIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: RevealIn(
                    key: ValueKey('result-card-${question.id}'),
                    delay: Duration(milliseconds: 40 + (entry.key * 55)),
                    beginOffset: const Offset(0, 0.024),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NeoBox(
                          color: AppColors.white,
                          padding: const EdgeInsets.all(22),
                          shadowColor: isCorrect
                              ? AppColors.success
                              : AppColors.error,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? AppColors.green
                                          : AppColors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Icon(
                                      isCorrect ? Icons.check : Icons.close,
                                      size: 20,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Question ${entry.key + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          question.prompt,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.ink,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              ...question.options.asMap().entries.map(
                                (optionEntry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _ResultOptionTile(
                                    label: optionEntry.value.text,
                                    isSelected:
                                        selectedIndex == optionEntry.key,
                                    isCorrect:
                                        question.correctIndex ==
                                        optionEntry.key,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCorrect && selectedIndex != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 16),
                            child: NeoBox(
                              color: AppColors.purple,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.lightbulbFilament,
                                        color: AppColors.ink,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Review',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (question.skillTag != null)
                                        StatusChip(
                                          label: question.skillTag!,
                                          icon: Icons.local_offer_outlined,
                                          color: AppColors.white,
                                          compact: true,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Why this missed',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    question
                                            .options[selectedIndex]
                                            .wrongExplanation ??
                                        'Review the idea behind this option and compare it carefully against the correct answer pattern.',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPracticeSection(question, quiz),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              RevealIn(
                key: ValueKey('results-back-${quiz.id}'),
                delay: const Duration(milliseconds: 140),
                beginOffset: const Offset(0, 0.03),
                child: Center(
                  child: SizedBox(
                    width: 320,
                    child: NeoButton(
                      label: 'Back to Quizzes',
                      icon: Icons.arrow_back,
                      color: AppColors.blue,
                      expand: true,
                      onPressed: widget.onBack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeSection(QuizQuestion question, Quiz quiz) {
    final practiceQuestion = _practiceQuestions[question.id];
    final loading = _practiceLoading[question.id] == true;
    final error = _practiceErrors[question.id];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: practiceQuestion != null
          ? _PracticeQuestionCard(
              key: ValueKey('practice-card-${question.id}'),
              practiceQuestion: practiceQuestion,
              selectedIndex: _practiceAnswers[question.id],
              onSelected: (value) =>
                  setState(() => _practiceAnswers[question.id] = value),
            )
          : loading
          ? ThinkingSurface(
              key: ValueKey('practice-loading-${question.id}'),
              active: true,
              radius: 18,
              pulseScale: 1.003,
              tintColor: AppColors.white,
              child: NeoBox(
                color: AppColors.blue.withValues(alpha: 0.42),
                padding: const EdgeInsets.all(16),
                shadowOffset: 4,
                radius: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 2.2),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.exam,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drafting a follow-up',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Same topic, same focus area, one fresh question.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              key: ValueKey('practice-trigger-${question.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 240,
                  child: NeoButton(
                    label: 'Practice This',
                    icon: Icons.refresh,
                    color: AppColors.blue,
                    expand: true,
                    onPressed: () => _generatePractice(question.id, quiz),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _scoreLabel(int percentage) {
    if (percentage >= 70) return 'Great Job!';
    if (percentage >= 40) return 'Good Effort!';
    return 'Needs Review';
  }

  void _submitQuiz(Quiz quiz) {
    final store = context.read<QuizStore>();
    final attempt = store.submitAttempt(
      widget.quizId,
      Map<String, int>.from(_answers),
    );
    setState(() {
      _attempt = attempt;
      _stage = _StudentStage.results;
    });
    widget.onSubmitted(attempt);
  }

  Future<void> _generatePractice(String questionId, Quiz quiz) async {
    setState(() {
      _practiceLoading[questionId] = true;
      _practiceErrors[questionId] = null;
    });

    try {
      final questions = await AiService.generateQuestions(
        topic: quiz.topic.isEmpty ? quiz.title : quiz.topic,
        focusArea: quiz.focusArea,
        count: 1,
      );
      if (!mounted) return;
      if (questions.isNotEmpty) {
        setState(() => _practiceQuestions[questionId] = questions.first);
      }
    } on AiServiceError catch (error) {
      if (!mounted) return;
      setState(() => _practiceErrors[questionId] = error.message);
    } finally {
      if (mounted) {
        setState(() => _practiceLoading[questionId] = false);
      }
    }
  }
}

class _TakingQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _TakingQuestionCard({
    required this.question,
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q${index + 1}.',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.prompt,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: AppColors.ink,
                      ),
                    ),
                    if (question.skillTag != null) ...[
                      const SizedBox(height: 12),
                      StatusChip(
                        label: question.skillTag!,
                        icon: Icons.local_offer_outlined,
                        color: AppColors.yellow,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...question.options.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelected(entry.key),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: selectedIndex == entry.key
                        ? AppColors.yellow
                        : AppColors.canvas,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        offset: Offset(
                          selectedIndex == entry.key ? 6 : 3,
                          selectedIndex == entry.key ? 6 : 3,
                        ),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 3),
                        ),
                        child: selectedIndex == entry.key
                            ? const Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.ink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SizedBox(width: 12, height: 12),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.text,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selectedIndex == entry.key
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCorrect;

  const _ResultOptionTile({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final background = isCorrect
        ? AppColors.green.withValues(alpha: 0.45)
        : isSelected
        ? AppColors.red.withValues(alpha: 0.6)
        : AppColors.canvas;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2.4),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: isSelected
                ? const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 10, height: 10),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (isCorrect)
            const Text(
              'Correct answer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.muted,
              ),
            ),
          if (isSelected && !isCorrect)
            const Text(
              'Your answer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _PracticeQuestionCard extends StatelessWidget {
  final QuizQuestion practiceQuestion;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _PracticeQuestionCard({
    super.key,
    required this.practiceQuestion,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswered = selectedIndex != null;
    final isCorrect = selectedIndex == practiceQuestion.correctIndex;

    return NeoBox(
      color: AppColors.blue.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(18),
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.exam, color: AppColors.ink, size: 18),
              const SizedBox(width: 8),
              Text(
                'Practice',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practiceQuestion.prompt,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...practiceQuestion.options.asMap().entries.map((entry) {
            final isSelected = selectedIndex == entry.key;
            final isActuallyCorrect =
                practiceQuestion.correctIndex == entry.key;

            final color = hasAnswered
                ? isActuallyCorrect
                      ? AppColors.green.withValues(alpha: 0.5)
                      : isSelected
                      ? AppColors.red.withValues(alpha: 0.55)
                      : AppColors.white
                : isSelected
                ? AppColors.yellow
                : AppColors.white;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: hasAnswered ? null : () => onSelected(entry.key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 2.4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (hasAnswered && isActuallyCorrect)
                        const Icon(Icons.check, color: AppColors.success),
                      if (hasAnswered && isSelected && !isActuallyCorrect)
                        const Icon(Icons.close, color: AppColors.error),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (hasAnswered) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.green : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2.4),
              ),
              child: Text(
                isCorrect
                    ? 'Correct. You repaired the misunderstanding on the follow-up.'
                    : practiceQuestion
                              .options[selectedIndex!]
                              .wrongExplanation ??
                          'Not quite. Revisit the misconception and compare it against the pattern of the correct answer.',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
