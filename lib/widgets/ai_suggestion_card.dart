import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/quiz.dart';
import '../theme.dart';
import 'neo_box.dart';
import 'neo_button.dart';
import 'status_chip.dart';

class AiSuggestionCard extends StatefulWidget {
  final QuizQuestion suggestion;
  final int index;
  final ValueChanged<QuizQuestion> onAccept;
  final VoidCallback onDiscard;

  const AiSuggestionCard({
    super.key,
    required this.suggestion,
    required this.index,
    required this.onAccept,
    required this.onDiscard,
  });

  @override
  State<AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends State<AiSuggestionCard> {
  late TextEditingController _promptController;
  late TextEditingController _skillTagController;
  late List<TextEditingController> _optionControllers;
  late List<TextEditingController> _explanationControllers;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.suggestion.prompt);
    _skillTagController = TextEditingController(
      text: widget.suggestion.skillTag ?? '',
    );
    _optionControllers = widget.suggestion.options
        .map((option) => TextEditingController(text: option.text))
        .toList();
    _explanationControllers = widget.suggestion.options
        .map(
          (option) =>
              TextEditingController(text: option.wrongExplanation ?? ''),
        )
        .toList();
    _correctIndex = widget.suggestion.correctIndex;
  }

  @override
  void dispose() {
    _promptController.dispose();
    _skillTagController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    for (final controller in _explanationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  QuizQuestion _editedSuggestion() {
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

    return QuizQuestion(
      id: widget.suggestion.id,
      prompt: _promptController.text,
      options: options,
      correctIndex: _correctIndex,
      skillTag: _skillTagController.text.trim().isEmpty
          ? null
          : _skillTagController.text.trim(),
      source: 'ai',
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: AppColors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                label: 'Suggestion ${widget.index + 1}',
                icon: PhosphorIconsRegular.cardsThree,
                color: AppColors.purple,
              ),
              const SizedBox(width: 10),
              const StatusChip(
                label: 'Editable',
                icon: Icons.tune,
                color: AppColors.yellow,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _promptController,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Suggested prompt',
              hintText: 'Refine this question before adding it to the quiz',
            ),
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
                    child: _SuggestionOptionEditor(
                      optionIndex: optionIndex,
                      isCorrect: isCorrect,
                      textController: _optionControllers[optionIndex],
                      explanationController:
                          _explanationControllers[optionIndex],
                      onSelected: () =>
                          setState(() => _correctIndex = optionIndex),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _skillTagController,
                  decoration: const InputDecoration(
                    labelText: 'Skill tag',
                    hintText: 'Concept tested',
                  ),
                ),
              ),
              NeoButton(
                label: 'Discard',
                color: AppColors.red,
                compact: true,
                onPressed: widget.onDiscard,
              ),
              const SizedBox(width: 10),
              NeoButton(
                label: 'Accept & Add',
                icon: PhosphorIconsRegular.rowsPlusBottom,
                color: AppColors.green,
                onPressed: () => widget.onAccept(_editedSuggestion()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionOptionEditor extends StatelessWidget {
  final int optionIndex;
  final bool isCorrect;
  final TextEditingController textController;
  final TextEditingController explanationController;
  final VoidCallback onSelected;

  const _SuggestionOptionEditor({
    required this.optionIndex,
    required this.isCorrect,
    required this.textController,
    required this.explanationController,
    required this.onSelected,
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
                style: const TextStyle(fontWeight: FontWeight.w800),
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
            decoration: const InputDecoration(labelText: 'Answer text'),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            TextField(
              controller: explanationController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Wrong-answer explanation',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
