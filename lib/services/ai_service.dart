import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/quiz.dart';

class AiService {
  static const _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _requestTimeout = Duration(seconds: 90);
  static const _maxTokensByCount = {1: 500, 2: 1000, 3: 1400};
  static final _uuid = const Uuid();

  static String get _apiKey => AppConfig.openRouterApiKey;
  static String get _model => AppConfig.openRouterModel;

  static bool get hasApiKey => AppConfig.hasOpenRouterApiKey;

  static String _focusAreaInstruction(FocusArea focus) {
    switch (focus) {
      case FocusArea.general:
        return 'balanced mix of conceptual and applied questions';
      case FocusArea.theory:
        return 'conceptual understanding, definitions, statement-checking, and core ideas';
      case FocusArea.practical:
        return 'code output, applied scenarios, what-happens-when questions, and hands-on reasoning';
      case FocusArea.problemSolving:
        return 'debugging, fix-the-error prompts, logic puzzles, and stepwise reasoning';
    }
  }

  static Future<List<QuizQuestion>> generateQuestions({
    required String topic,
    required FocusArea focusArea,
    int count = 3,
  }) async {
    final normalizedCount = count.clamp(1, 3).toInt();
    final trimmedTopic = topic.trim();

    if (!hasApiKey) {
      throw AiServiceError(
        'OpenRouter is not configured. Add OPENROUTER_API_KEY to the Imag-IQ project .env or pass it with --dart-define.',
      );
    }

    if (trimmedTopic.isEmpty) {
      throw AiServiceError('Add a topic before generating questions.');
    }

    final prompt = _buildPrompt(
      topic: trimmedTopic,
      focusArea: focusArea,
      count: normalizedCount,
    );

    try {
      final response = await _postGenerationRequest(
        prompt: prompt,
        count: normalizedCount,
      );

      final body = _decodeBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiServiceError(_extractError(body, response.statusCode));
      }

      final rawContent = _extractAssistantContent(body);
      final jsonPayload = _extractJsonPayload(rawContent);
      final decoded = _decodeGeneratedPayload(jsonPayload);
      final rawQuestions = _extractQuestions(decoded);

      final questions = rawQuestions
          .map(_parseQuestion)
          .take(normalizedCount)
          .toList();

      if (questions.isEmpty) {
        throw AiServiceError('The model did not return any usable questions.');
      }

      return questions;
    } on TimeoutException {
      throw AiServiceError(
        'Generation is taking longer than expected. Try again in a moment.',
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint('Imag-IQ AI parse failure: ${error.message}');
      }
      throw AiServiceError(
        'The response came back in an unexpected format. Try again.',
      );
    } on AiServiceError {
      rethrow;
    } catch (_) {
      throw AiServiceError(
        'Question generation failed. Check your connection and try again.',
      );
    }
  }

  static String _buildPrompt({
    required String topic,
    required FocusArea focusArea,
    required int count,
  }) {
    return '''
You are a quiz question generator for educational assessments.

Topic: $topic
Focus area: ${focusArea.label}
Style direction: ${_focusAreaInstruction(focusArea)}

Generate exactly $count multiple-choice questions.

Each question must include:
- A clear prompt
- Exactly 4 options
- Exactly 1 correct answer
- "correctIndex" as an integer from 0 to 3
- A short "skillTag"
- "wrongExplanation" for each wrong option
- "wrongExplanation": null for the correct option

Wrong-answer explanations must:
- Be 1 to 2 sentences
- Guide the student toward the concept
- Explain the misconception
- Avoid revealing the correct answer directly

Return only valid JSON.

Use this exact shape:
{
  "questions": [
    {
      "prompt": "Question text",
      "options": [
        {"text": "Option A", "wrongExplanation": null},
        {"text": "Option B", "wrongExplanation": "Why this is incorrect"},
        {"text": "Option C", "wrongExplanation": "Why this is incorrect"},
        {"text": "Option D", "wrongExplanation": "Why this is incorrect"}
      ],
      "correctIndex": 0,
      "skillTag": "Short concept label"
    }
  ]
}
''';
  }

  static Future<http.Response> _postGenerationRequest({
    required String prompt,
    required int count,
  }) {
    return http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://imagiq.local',
            'X-Title': 'Imag-IQ',
          },
          body: jsonEncode({
            'model': _model,
            'route': 'fallback',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You create educational multiple-choice questions and must return valid JSON only.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'response_format': {'type': 'json_object'},
            'temperature': 0.35,
            'top_p': 0.9,
            'max_tokens': _maxTokensByCount[count] ?? 1700,
            'provider': {'sort': 'latency'},
            'plugins': [
              {'id': 'response-healing'},
            ],
          }),
        )
        .timeout(_requestTimeout);
  }

  static Map<String, dynamic> _decodeBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response was not a JSON object.');
    }
    return decoded;
  }

  static dynamic _decodeGeneratedPayload(String payload) {
    final decoded = jsonDecode(payload);

    if (decoded is String) {
      final trimmed = decoded.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return jsonDecode(trimmed);
      }
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['content'] ?? decoded['output'] ?? decoded['data'];
      if (nested is String) {
        final trimmed = nested.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          return jsonDecode(trimmed);
        }
      }
    }

    return decoded;
  }

  static String _extractError(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return 'OpenRouter error ($statusCode): ${message.trim()}';
      }
    }

    return 'OpenRouter error ($statusCode).';
  }

  static String _extractAssistantContent(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('No choices returned.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw const FormatException('Choice payload was invalid.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('Message payload was invalid.');
    }

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text =
              item['text'] ??
              item['content'] ??
              item['value'] ??
              (item['type'] == 'text' ? item['text'] : null);
          if (text is String && text.trim().isNotEmpty) {
            if (buffer.isNotEmpty) {
              buffer.writeln();
            }
            buffer.write(text.trim());
          }
        }
      }

      final joined = buffer.toString().trim();
      if (joined.isNotEmpty) {
        return joined;
      }
    }

    throw const FormatException('No response text returned.');
  }

  static String _extractJsonPayload(String content) {
    final cleaned = content
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```$', multiLine: true), '')
        .trim();

    final arrayStart = cleaned.indexOf('[');
    final arrayEnd = cleaned.lastIndexOf(']');
    if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
      return cleaned.substring(arrayStart, arrayEnd + 1);
    }

    final objectStart = cleaned.indexOf('{');
    final objectEnd = cleaned.lastIndexOf('}');
    if (objectStart != -1 && objectEnd != -1 && objectEnd > objectStart) {
      return cleaned.substring(objectStart, objectEnd + 1);
    }

    throw const FormatException('No JSON payload found.');
  }

  static List<Map<String, dynamic>> _extractQuestions(dynamic decoded) {
    final rawList = switch (decoded) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['questions'] is List<dynamic> =>
        map['questions'] as List<dynamic>,
      Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      Map<String, dynamic> map when map['data'] is List<dynamic> =>
        map['data'] as List<dynamic>,
      Map<String, dynamic> map when map['results'] is List<dynamic> =>
        map['results'] as List<dynamic>,
      Map<String, dynamic> map when map['question'] is Map<String, dynamic> => [
        map['question'] as Map<String, dynamic>,
      ],
      Map<String, dynamic> map when map['questions'] is String =>
        _extractQuestions(_decodeGeneratedPayload(map['questions'] as String)),
      _ => throw const FormatException('Response did not contain questions.'),
    };

    final questions = <Map<String, dynamic>>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        questions.add(item);
      }
    }

    if (questions.isEmpty) {
      throw const FormatException('No valid question objects found.');
    }

    return questions;
  }

  static QuizQuestion _parseQuestion(Map<String, dynamic> json) {
    final prompt = (json['prompt'] as String?)?.trim();
    if (prompt == null || prompt.isEmpty) {
      throw const FormatException('Question prompt missing.');
    }

    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.length < 4) {
      throw const FormatException('Question options missing.');
    }

    final options = rawOptions
        .take(4)
        .map((option) {
          if (option is! Map<String, dynamic>) {
            throw const FormatException('Option payload missing.');
          }

          final text = (option['text'] as String?)?.trim();
          if (text == null || text.isEmpty) {
            throw const FormatException('Option text missing.');
          }

          final explanation = (option['wrongExplanation'] as String?)?.trim();
          return OptionChoice(
            text: text,
            wrongExplanation: explanation == null || explanation.isEmpty
                ? null
                : explanation,
          );
        })
        .toList(growable: false);

    var correctIndex = json['correctIndex'];
    if (correctIndex is! int || correctIndex < 0 || correctIndex > 3) {
      final inferredIndex = options.indexWhere(
        (option) => option.wrongExplanation == null,
      );
      if (inferredIndex == -1) {
        throw const FormatException('Correct answer index missing.');
      }
      correctIndex = inferredIndex;
    }

    final normalizedOptions = List<OptionChoice>.generate(options.length, (
      index,
    ) {
      final option = options[index];
      if (index == correctIndex) {
        return option.copyWith(wrongExplanation: null);
      }

      return option.copyWith(
        wrongExplanation:
            option.wrongExplanation ??
            'This choice points to a different idea. Recheck the concept behind the question.',
      );
    }, growable: false);

    return QuizQuestion(
      id: _uuid.v4(),
      prompt: prompt,
      options: normalizedOptions,
      correctIndex: correctIndex,
      skillTag: (json['skillTag'] as String?)?.trim(),
      source: 'ai',
    );
  }
}

class AiServiceError implements Exception {
  final String message;

  const AiServiceError(this.message);

  @override
  String toString() => message;
}
