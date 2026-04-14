import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/quiz.dart';
import '../theme.dart';
import 'neo_box.dart';
import 'status_chip.dart';

class QuestionCard extends StatefulWidget {
  final QuizQuestion question;
  final int index;
  final ValueChanged<QuizQuestion> onChanged;
  final VoidCallback onDelete;

  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _promptController;
  late TextEditingController _skillTagController;
  late List<TextEditingController> _optionControllers;
  late List<TextEditingController> _explanationControllers;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    _setControllersFromQuestion(widget.question);
  }

  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _disposeControllers();
      _setControllersFromQuestion(widget.question);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _setControllersFromQuestion(QuizQuestion question) {
    _promptController = TextEditingController(text: question.prompt);
    _skillTagController = TextEditingController(text: question.skillTag ?? '');
    _optionControllers = question.options
        .map((option) => TextEditingController(text: option.text))
        .toList();
    _explanationControllers = question.options
        .map(
          (option) =>
              TextEditingController(text: option.wrongExplanation ?? ''),
        )
        .toList();
    _correctIndex = question.correctIndex;
  }

  void _disposeControllers() {
    _promptController.dispose();
    _skillTagController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    for (final controller in _explanationControllers) {
      controller.dispose();
    }
  }

  QuizQuestion _currentQuestion() {
    final options = List<OptionChoice>.generate(4, (index) {
      return OptionChoice(
        text: _optionControllers[index].text,
        wrongExplanation: index == _correctIndex
            ? null
            : _explanationControllers[index].text.trim().isEmpty
            ? null
            : _explanationControllers[index].text.trim(),
      );
    });

    return widget.question.copyWith(
      prompt: _promptController.text,
      options: options,
      correctIndex: _correctIndex,
      skillTag: _skillTagController.text.trim().isEmpty
          ? null
          : _skillTagController.text.trim(),
    );
  }

  void _emit() {
    widget.onChanged(_currentQuestion());
  }

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 3),
            ),
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        onChanged: (_) => _emit(),
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Question prompt',
                          hintText: 'Write the question students should answer',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth > 760;
                    final itemWidth = twoColumns
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(4, (optionIndex) {
                        final isCorrect = optionIndex == _correctIndex;
                        return SizedBox(
                          width: itemWidth,
                          child: _QuestionOptionEditor(
                            optionIndex: optionIndex,
                            isCorrect: isCorrect,
                            textController: _optionControllers[optionIndex],
                            explanationController:
                                _explanationControllers[optionIndex],
                            onSelected: () {
                              setState(() => _correctIndex = optionIndex);
                              _emit();
                            },
                            onChanged: _emit,
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _skillTagController,
                        onChanged: (_) => _emit(),
                        decoration: const InputDecoration(
                          labelText: 'Skill tag',
                          hintText: 'e.g. Loops',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusChip(
                      label: widget.question.source == 'ai'
                          ? 'Drafted'
                          : 'Manual',
                      icon: widget.question.source == 'ai'
                          ? PhosphorIconsRegular.cardsThree
                          : PhosphorIconsRegular.penNib,
                      color: widget.question.source == 'ai'
                          ? AppColors.purple
                          : AppColors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionOptionEditor extends StatelessWidget {
  final int optionIndex;
  final bool isCorrect;
  final TextEditingController textController;
  final TextEditingController explanationController;
  final VoidCallback onSelected;
  final VoidCallback onChanged;

  const _QuestionOptionEditor({
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
            ? AppColors.green.withValues(alpha: 0.45)
            : AppColors.canvas,
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
                    color: isCorrect ? AppColors.white : AppColors.white,
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
                  fontSize: 14,
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
              hintText: isCorrect ? 'Correct answer' : 'Distractor answer',
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
                hintText:
                    'Explain the misconception without revealing the answer',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
