enum FocusArea {
  general,
  theory,
  practical,
  problemSolving;

  String get label {
    switch (this) {
      case FocusArea.general:
        return 'General';
      case FocusArea.theory:
        return 'Theory';
      case FocusArea.practical:
        return 'Practical';
      case FocusArea.problemSolving:
        return 'Problem-Solving';
    }
  }
}

class OptionChoice {
  final String text;
  final String? wrongExplanation;

  OptionChoice({required this.text, this.wrongExplanation});

  OptionChoice copyWith({String? text, String? wrongExplanation}) {
    return OptionChoice(
      text: text ?? this.text,
      wrongExplanation: wrongExplanation ?? this.wrongExplanation,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'wrongExplanation': wrongExplanation,
  };

  factory OptionChoice.fromJson(Map<String, dynamic> json) {
    return OptionChoice(
      text: json['text'] as String,
      wrongExplanation: json['wrongExplanation'] as String?,
    );
  }
}

class QuizQuestion {
  final String id;
  final String prompt;
  final List<OptionChoice> options;
  final int correctIndex;
  final String? skillTag;
  final String source; // 'manual' or 'ai'

  QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.skillTag,
    this.source = 'manual',
  });

  QuizQuestion copyWith({
    String? prompt,
    List<OptionChoice>? options,
    int? correctIndex,
    String? skillTag,
    String? source,
  }) {
    return QuizQuestion(
      id: id,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      skillTag: skillTag ?? this.skillTag,
      source: source ?? this.source,
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String topic;
  final FocusArea focusArea;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.topic,
    this.focusArea = FocusArea.general,
    required this.questions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Quiz copyWith({
    String? title,
    String? topic,
    FocusArea? focusArea,
    List<QuizQuestion>? questions,
  }) {
    return Quiz(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      focusArea: focusArea ?? this.focusArea,
      questions: questions ?? this.questions,
      createdAt: createdAt,
    );
  }
}

class QuizAttempt {
  final String quizId;
  final Map<String, int> answers; // questionId -> selected option index
  final int score;
  final int total;
  final DateTime submittedAt;

  QuizAttempt({
    required this.quizId,
    required this.answers,
    required this.score,
    required this.total,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();
}
