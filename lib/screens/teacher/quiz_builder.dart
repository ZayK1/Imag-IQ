import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/quiz.dart';
import '../../services/ai_service.dart';
import '../../store/quiz_store.dart';
import '../../theme.dart';
import '../../widgets/ai_suggestion_card.dart';
import '../../widgets/neo_box.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/question_card.dart';
import '../../widgets/reveal_in.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/thinking_surface.dart';

class QuizBuilder extends StatefulWidget {
  final String quizId;

  const QuizBuilder({super.key, required this.quizId});

  @override
  State<QuizBuilder> createState() => _QuizBuilderState();
}

class _QuizBuilderState extends State<QuizBuilder> {
  final _uuid = const Uuid();

  late TextEditingController _titleController;
  late TextEditingController _topicController;
  late TextEditingController _aiPromptController;
  late FocusArea _focusArea;
  late String _syncedTopic;

  final _manualPromptController = TextEditingController();
  final _manualSkillTagController = TextEditingController();
  final List<TextEditingController> _manualOptionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _manualExplanationControllers =
      List.generate(4, (_) => TextEditingController());
  int _manualCorrectIndex = 0;
  bool _showManualComposer = false;

  List<QuizQuestion> _suggestions = [];
  bool _aiLoading = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    final quiz = context.read<QuizStore>().getQuiz(widget.quizId);
    _titleController = TextEditingController(text: quiz?.title ?? '');
    _topicController = TextEditingController(text: quiz?.topic ?? '');
    _aiPromptController = TextEditingController(text: quiz?.topic ?? '');
    _focusArea = quiz?.focusArea ?? FocusArea.general;
    _syncedTopic = quiz?.topic ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _aiPromptController.dispose();
    _manualPromptController.dispose();
    _manualSkillTagController.dispose();
    for (final controller in _manualOptionControllers) {
      controller.dispose();
    }
    for (final controller in _manualExplanationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizStore>(
      builder: (context, store, _) {
        final quiz = store.getQuiz(widget.quizId);
        if (quiz == null) {
          return const SizedBox.shrink();
        }

        final aiCount = quiz.questions
            .where((question) => question.source == 'ai')
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevealIn(
                key: ValueKey('workspace-${quiz.id}'),
                child: _buildTopWorkspace(quiz, aiCount, store),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _showManualComposer
                    ? Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: RevealIn(
                          key: const ValueKey('manual-composer'),
                          beginOffset: const Offset(0, 0.02),
                          child: _buildManualComposer(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildSuggestionStack(),
              ],
              const SizedBox(height: 24),
              RevealIn(
                key: ValueKey('question-header-${quiz.id}'),
                delay: const Duration(milliseconds: 40),
                beginOffset: const Offset(0, 0.02),
                child: _buildQuestionHeader(quiz, aiCount),
              ),
              const SizedBox(height: 14),
              _buildQuestionList(quiz, store),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopWorkspace(Quiz quiz, int aiCount, QuizStore store) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1100;
        final metadata = _buildMetadataHero(quiz, aiCount, store);
        final aiPanel = _buildAiPanel(quiz);
        final manualDock = _buildManualComposerDock();

        if (stacked) {
          return Column(
            children: [
              metadata,
              const SizedBox(height: 18),
              aiPanel,
              const SizedBox(height: 14),
              manualDock,
            ],
          );
        }

        return Column(
          children: [
            metadata,
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 14, child: aiPanel),
                const SizedBox(width: 14),
                Expanded(flex: 9, child: manualDock),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetadataHero(Quiz quiz, int aiCount, QuizStore store) {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            onChanged: (value) => store.updateQuiz(widget.quizId, title: value),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: AppColors.ink,
            ),
            decoration: const InputDecoration(
              hintText: 'Quiz title',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(
                label: '${quiz.questions.length} total questions',
                icon: Icons.quiz_outlined,
                color: AppColors.yellow,
              ),
              StatusChip(
                label: '$aiCount drafted',
                icon: PhosphorIconsRegular.cardsThree,
                color: AppColors.purple,
              ),
              StatusChip(
                label: quiz.focusArea.label,
                icon: Icons.category_outlined,
                color: AppColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 860;
              final topicField = TextField(
                controller: _topicController,
                onChanged: (value) => _handleTopicChanged(value, store),
                decoration: const InputDecoration(
                  labelText: 'Topic / subject',
                  hintText: 'e.g. Python loops, atoms, fractions',
                ),
              );

              final focusField = DropdownButtonFormField<FocusArea>(
                initialValue: _focusArea,
                decoration: const InputDecoration(labelText: 'Focus area'),
                items: FocusArea.values
                    .map(
                      (focusArea) => DropdownMenuItem<FocusArea>(
                        value: focusArea,
                        child: Text(focusArea.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _focusArea = value);
                  store.updateQuiz(widget.quizId, focusArea: value);
                },
              );

              if (stacked) {
                return Column(
                  children: [
                    topicField,
                    const SizedBox(height: 14),
                    focusField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: topicField),
                  const SizedBox(width: 14),
                  Expanded(child: focusField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiPanel(Quiz quiz) {
    final effectiveTopic = _aiPromptController.text.trim();
    final hasTopic = effectiveTopic.isNotEmpty;

    return ThinkingSurface(
      active: _aiLoading,
      radius: 20,
      pulseScale: 1.004,
      tintColor: AppColors.white,
      child: NeoBox(
        color: _aiLoading
            ? AppColors.purple.withValues(alpha: 0.92)
            : AppColors.purple,
        padding: const EdgeInsets.all(20),
        shadowOffset: _aiLoading ? 8 : 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 2.5),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.rowsPlusBottom,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _aiLoading ? 'Drafting questions...' : 'Generate',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _aiLoading
                            ? 'A quiet pass on the same topic and focus area.'
                            : 'Uses the quiz topic by default.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _aiLoading
                              ? AppColors.white.withValues(alpha: 0.94)
                              : AppColors.ink.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_aiLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 860;
                final input = TextField(
                  controller: _aiPromptController,
                  enabled: !_aiLoading,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Generation topic',
                    hintText: quiz.topic.trim().isEmpty
                        ? 'Enter a topic'
                        : null,
                  ),
                );
                final button = ThinkingSurface(
                  active: _aiLoading,
                  radius: 16,
                  pulseScale: 1.003,
                  tintColor: AppColors.white,
                  child: SizedBox(
                    width: stacked ? double.infinity : 210,
                    child: NeoButton(
                      label: _aiLoading ? 'Thinking...' : 'Generate 3',
                      icon: _aiLoading
                          ? PhosphorIconsRegular.notepad
                          : PhosphorIconsRegular.rowsPlusBottom,
                      color: _aiLoading ? AppColors.white : AppColors.green,
                      expand: true,
                      onPressed: hasTopic && !_aiLoading
                          ? _generateQuestions
                          : null,
                    ),
                  ),
                );

                if (stacked) {
                  return Column(
                    children: [input, const SizedBox(height: 14), button],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 3, child: input),
                    const SizedBox(width: 14),
                    button,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            StatusChip(
              label: _focusArea.label,
              icon: Icons.tune,
              color: AppColors.yellow,
            ),
            if (_aiError != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 2.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _aiError!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (quiz.questions.isEmpty &&
                _suggestions.isEmpty &&
                !_aiLoading &&
                hasTopic) ...[
              const SizedBox(height: 14),
              Text(
                'Generate a first draft or add one manually.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggestions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Edit and accept what you want.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        ..._suggestions.asMap().entries.map(
          (entry) {
            final suggestion = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RevealIn(
                key: ValueKey('suggestion-${suggestion.id}'),
                delay: Duration(milliseconds: entry.key * 55),
                beginOffset: const Offset(0, 0.03),
                child: AiSuggestionCard(
                  suggestion: suggestion,
                  index: entry.key,
                  onAccept: (updatedQuestion) {
                    final i = _suggestions.indexWhere((s) => s.id == suggestion.id);
                    if (i != -1) _acceptSuggestion(i, updatedQuestion);
                  },
                  onDiscard: () {
                    setState(() => _suggestions.removeWhere((s) => s.id == suggestion.id));
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManualComposer() {
    return NeoBox(
      color: AppColors.pink,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.penNib, color: AppColors.ink, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Manual Question',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _manualPromptController,
            onChanged: (_) => setState(() {}),
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Question prompt',
              hintText: 'What should the student figure out?',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _manualSkillTagController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Skill tag',
              hintText: 'e.g. Debugging, Fractions, Loops',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth > 760;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(4, (index) {
                  final isCorrect = index == _manualCorrectIndex;
                  return SizedBox(
                    width: itemWidth,
                    child: _ComposerOptionCard(
                      optionIndex: index,
                      isCorrect: isCorrect,
                      textController: _manualOptionControllers[index],
                      explanationController:
                          _manualExplanationControllers[index],
                      onSelected: () =>
                          setState(() => _manualCorrectIndex = index),
                      onChanged: () => setState(() {}),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 230,
              child: NeoButton(
                label: 'Add Question',
                icon: PhosphorIconsRegular.rowsPlusBottom,
                color: AppColors.white,
                expand: true,
                onPressed: _canAddManual() ? _addManualQuestion : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(Quiz quiz, int aiCount) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions (${quiz.questions.length})',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Edit questions directly.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: '$aiCount drafted',
              icon: PhosphorIconsRegular.cardsThree,
              color: AppColors.purple,
              compact: true,
            ),
            StatusChip(
              label: '${quiz.questions.length - aiCount} manual',
              icon: PhosphorIconsRegular.penNib,
              color: AppColors.blue,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualComposerDock() {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.penNib, color: AppColors.ink, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Manual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Open the form only when you need it.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          NeoButton(
            label: _showManualComposer ? 'Hide Form' : 'Open Form',
            icon: _showManualComposer
                ? PhosphorIconsRegular.arrowsInSimple
                : PhosphorIconsRegular.penNib,
            color: _showManualComposer ? AppColors.white : AppColors.blue,
            expand: true,
            onPressed: () =>
                setState(() => _showManualComposer = !_showManualComposer),
          ),
        ],
      ),
    );
  }

  void _handleTopicChanged(String value, QuizStore store) {
    final currentAiTopic = _aiPromptController.text.trim();
    final shouldSync =
        currentAiTopic.isEmpty || currentAiTopic == _syncedTopic.trim();

    store.updateQuiz(widget.quizId, topic: value);

    if (shouldSync) {
      _aiPromptController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      setState(() {});
    }

    _syncedTopic = value;
  }

  Widget _buildQuestionList(Quiz quiz, QuizStore store) {
    if (quiz.questions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.45),
            width: 3,
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.menu_book_outlined, size: 44, color: AppColors.muted),
            SizedBox(height: 12),
            Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Generate a draft or add one manually.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: quiz.questions
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RevealIn(
                key: ValueKey('question-card-${entry.value.id}'),
                delay: Duration(milliseconds: entry.key * 35),
                beginOffset: const Offset(0, 0.022),
                child: QuestionCard(
                  question: entry.value,
                  index: entry.key,
                  onChanged: (updatedQuestion) =>
                      store.updateQuestion(widget.quizId, updatedQuestion),
                  onDelete: () =>
                      store.removeQuestion(widget.quizId, entry.value.id),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  bool _canAddManual() {
    if (_manualPromptController.text.trim().isEmpty) return false;
    for (final controller in _manualOptionControllers) {
      if (controller.text.trim().isEmpty) return false;
    }
    return true;
  }

  void _resetManualComposer() {
    _manualPromptController.clear();
    _manualSkillTagController.clear();
    for (final controller in _manualOptionControllers) {
      controller.clear();
    }
    for (final controller in _manualExplanationControllers) {
      controller.clear();
    }
    setState(() => _manualCorrectIndex = 0);
  }

  void _addManualQuestion() {
    final store = context.read<QuizStore>();
    final options = List<OptionChoice>.generate(4, (index) {
      return OptionChoice(
        text: _manualOptionControllers[index].text.trim(),
        wrongExplanation: index == _manualCorrectIndex
            ? null
            : _manualExplanationControllers[index].text.trim().isEmpty
            ? null
            : _manualExplanationControllers[index].text.trim(),
      );
    });

    store.addQuestion(
      widget.quizId,
      QuizQuestion(
        id: _uuid.v4(),
        prompt: _manualPromptController.text.trim(),
        options: options,
        correctIndex: _manualCorrectIndex,
        skillTag: _manualSkillTagController.text.trim().isEmpty
            ? null
            : _manualSkillTagController.text.trim(),
        source: 'manual',
      ),
    );

    _resetManualComposer();
  }

  Future<void> _generateQuestions() async {
    final effectiveTopic = _aiPromptController.text.trim().isNotEmpty
        ? _aiPromptController.text.trim()
        : _topicController.text.trim();

    setState(() {
      _aiLoading = true;
      _aiError = null;
      _suggestions = [];
    });

    try {
      final questions = await AiService.generateQuestions(
        topic: effectiveTopic,
        focusArea: _focusArea,
      );
      if (!mounted) return;
      setState(() => _suggestions = questions);
    } on AiServiceError catch (error) {
      if (!mounted) return;
      setState(() => _aiError = error.message);
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  void _acceptSuggestion(int index, QuizQuestion updatedQuestion) {
    if (index < 0 || index >= _suggestions.length) return;
    final store = context.read<QuizStore>();
    setState(() => _suggestions.removeAt(index));
    store.addQuestion(
      widget.quizId,
      QuizQuestion(
        id: _uuid.v4(),
        prompt: updatedQuestion.prompt,
        options: updatedQuestion.options,
        correctIndex: updatedQuestion.correctIndex,
        skillTag: updatedQuestion.skillTag,
        source: 'ai',
      ),
    );
  }
}

class _ComposerOptionCard extends StatelessWidget {
  final int optionIndex;
  final bool isCorrect;
  final TextEditingController textController;
  final TextEditingController explanationController;
  final VoidCallback onSelected;
  final VoidCallback onChanged;

  const _ComposerOptionCard({
    required this.optionIndex,
    required this.isCorrect,
    required this.textController,
    required this.explanationController,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.green.withValues(alpha: 0.42)
            : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onSelected,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 3),
                  ),
                  child: isCorrect
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
              ),
              const SizedBox(width: 10),
              Text(
                'Option ${String.fromCharCode(65 + optionIndex)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              if (isCorrect)
                const StatusChip(
                  label: 'Correct',
                  icon: Icons.check,
                  color: AppColors.green,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: textController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Answer text',
              hintText: isCorrect ? 'Correct answer' : 'Wrong answer',
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            TextField(
              controller: explanationController,
              onChanged: (_) => onChanged(),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Wrong-answer explanation',
                hintText: 'Explain the misconception, not the solution',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
