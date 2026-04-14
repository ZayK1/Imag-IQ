import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/quiz.dart';

class QuizStore extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<Quiz> _quizzes = [];
  final List<QuizAttempt> _attempts = [];

  List<Quiz> get quizzes => List.unmodifiable(_quizzes);
  List<QuizAttempt> get attempts => List.unmodifiable(_attempts);

  QuizStore() {
    _seedData();
  }

  void _seedData() {
    _quizzes.add(
      Quiz(
        id: _uuid.v4(),
        title: 'Python Basics',
        topic: 'Python fundamentals',
        focusArea: FocusArea.general,
        questions: [
          QuizQuestion(
            id: _uuid.v4(),
            prompt: 'What is the output of: print(type(42))?',
            options: [
              OptionChoice(text: "<class 'int'>", wrongExplanation: null),
              OptionChoice(
                text: "<class 'str'>",
                wrongExplanation:
                    "Strings are text values wrapped in quotes. The number 42 doesn't have quotes around it — think about what Python sees when there are no quotes.",
              ),
              OptionChoice(
                text: "<class 'float'>",
                wrongExplanation:
                    "Floats represent decimal numbers in Python. Consider whether 42 has a decimal point — what distinguishes a whole number from a decimal one?",
              ),
              OptionChoice(
                text: "<class 'num'>",
                wrongExplanation:
                    "Python doesn't have a 'num' type. Think about the specific numeric types Python uses — what's the difference between whole numbers and decimals in Python?",
              ),
            ],
            correctIndex: 0,
            skillTag: 'Data Types',
            source: 'manual',
          ),
          QuizQuestion(
            id: _uuid.v4(),
            prompt:
                'Which keyword starts a loop that repeats for each item in a list?',
            options: [
              OptionChoice(
                text: 'while',
                wrongExplanation:
                    "'while' does create a loop, but it repeats based on a condition being true, not by going through items one by one. Think about which keyword is specifically designed for iterating over collections.",
              ),
              OptionChoice(text: 'for', wrongExplanation: null),
              OptionChoice(
                text: 'loop',
                wrongExplanation:
                    "'loop' isn't actually a Python keyword. Python has two specific loop constructs — think about which one is designed for going through items in a sequence.",
              ),
              OptionChoice(
                text: 'each',
                wrongExplanation:
                    "'each' is used in some other programming languages but isn't a Python keyword. Python's approach to iterating over items uses a different word — it's one of the two loop types Python offers.",
              ),
            ],
            correctIndex: 1,
            skillTag: 'Loops',
            source: 'manual',
          ),
          QuizQuestion(
            id: _uuid.v4(),
            prompt:
                'What does this code print?\n\nx = 10\nif x > 5:\n    print("big")\nelse:\n    print("small")',
            options: [
              OptionChoice(text: 'big', wrongExplanation: null),
              OptionChoice(
                text: 'small',
                wrongExplanation:
                    "The else branch runs when the if condition is False. Check the condition again: is 10 greater than 5? Trace through what Python evaluates step by step.",
              ),
              OptionChoice(
                text: 'big small',
                wrongExplanation:
                    "An if/else block only executes one branch — either the if or the else, never both. Think about what the condition evaluates to and which single branch runs.",
              ),
              OptionChoice(
                text: 'Error',
                wrongExplanation:
                    "This code is valid Python — the indentation and syntax are correct. Try reading it line by line: what value does x have, and what does the condition check?",
              ),
            ],
            correctIndex: 0,
            skillTag: 'Conditionals',
            source: 'manual',
          ),
          QuizQuestion(
            id: _uuid.v4(),
            prompt: 'How do you define a function called "greet" in Python?',
            options: [
              OptionChoice(
                text: 'function greet():',
                wrongExplanation:
                    "The word 'function' is used in JavaScript and some other languages, but Python uses a shorter keyword. Think about Python's specific syntax for declaring functions.",
              ),
              OptionChoice(text: 'def greet():', wrongExplanation: null),
              OptionChoice(
                text: 'func greet():',
                wrongExplanation:
                    "'func' is used in languages like Go and Swift, but Python has its own keyword. It's a three-letter abbreviation — think about what it might be short for.",
              ),
              OptionChoice(
                text: 'define greet():',
                wrongExplanation:
                    "You're on the right track thinking about 'defining' a function, but Python abbreviates this keyword. What shorter form might Python use?",
              ),
            ],
            correctIndex: 1,
            skillTag: 'Functions',
            source: 'manual',
          ),
        ],
      ),
    );
  }

  String createQuiz(String title, String topic, FocusArea focusArea) {
    final id = _uuid.v4();
    _quizzes.add(
      Quiz(
        id: id,
        title: title,
        topic: topic,
        focusArea: focusArea,
        questions: [],
      ),
    );
    notifyListeners();
    return id;
  }

  void updateQuiz(
    String quizId, {
    String? title,
    String? topic,
    FocusArea? focusArea,
  }) {
    final index = _quizzes.indexWhere((q) => q.id == quizId);
    if (index == -1) return;
    _quizzes[index] = _quizzes[index].copyWith(
      title: title,
      topic: topic,
      focusArea: focusArea,
    );
    notifyListeners();
  }

  void deleteQuiz(String quizId) {
    _quizzes.removeWhere((q) => q.id == quizId);
    notifyListeners();
  }

  void addQuestion(String quizId, QuizQuestion question) {
    final index = _quizzes.indexWhere((q) => q.id == quizId);
    if (index == -1) return;
    final questions = List<QuizQuestion>.from(_quizzes[index].questions)
      ..add(question);
    _quizzes[index] = _quizzes[index].copyWith(questions: questions);
    notifyListeners();
  }

  void removeQuestion(String quizId, String questionId) {
    final index = _quizzes.indexWhere((q) => q.id == quizId);
    if (index == -1) return;
    final questions = _quizzes[index].questions
        .where((q) => q.id != questionId)
        .toList();
    _quizzes[index] = _quizzes[index].copyWith(questions: questions);
    notifyListeners();
  }

  void updateQuestion(String quizId, QuizQuestion updated) {
    final index = _quizzes.indexWhere((q) => q.id == quizId);
    if (index == -1) return;
    final questions = _quizzes[index].questions
        .map((q) => q.id == updated.id ? updated : q)
        .toList();
    _quizzes[index] = _quizzes[index].copyWith(questions: questions);
    notifyListeners();
  }

  Quiz? getQuiz(String id) {
    try {
      return _quizzes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  QuizAttempt submitAttempt(String quizId, Map<String, int> answers) {
    final quiz = getQuiz(quizId);
    if (quiz == null) throw Exception('Quiz not found');

    int score = 0;
    for (final question in quiz.questions) {
      if (answers[question.id] == question.correctIndex) {
        score++;
      }
    }

    final attempt = QuizAttempt(
      quizId: quizId,
      answers: answers,
      score: score,
      total: quiz.questions.length,
    );
    _attempts.add(attempt);
    notifyListeners();
    return attempt;
  }
}
