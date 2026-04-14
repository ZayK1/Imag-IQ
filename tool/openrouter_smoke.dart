import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final count = _parseCountArg(args);
  const requestTimeout = Duration(seconds: 90);
  final env = await _loadEnv();
  final apiKey = _trimWrapped(env['OPENROUTER_API_KEY'] ?? '');
  final model = _trimWrapped(env['OPENROUTER_MODEL'] ?? 'moonshotai/kimi-k2.5');

  if (apiKey.isEmpty) {
    stderr.writeln(
      'Missing OPENROUTER_API_KEY. Add it to the Imag-IQ project .env or ../.env first.',
    );
    exitCode = 1;
    return;
  }

  final response = await http
      .post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://imagiq.local',
          'X-Title': 'Imag-IQ Smoke Test',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': 'Return valid JSON only.'},
            {
              'role': 'user',
              'content':
                  '''
Generate exactly $count multiple-choice question(s) about Python fundamentals.
Return only valid JSON in this shape:
{
  "questions": [
    {
      "prompt": "...",
      "options": [
        {"text": "...", "wrongExplanation": null},
        {"text": "...", "wrongExplanation": "..."},
        {"text": "...", "wrongExplanation": "..."},
        {"text": "...", "wrongExplanation": "..."}
      ],
      "correctIndex": 0,
      "skillTag": "..."
    }
  ]
}
''',
            },
          ],
          'temperature': 0.45,
          'response_format': {'type': 'json_object'},
          'max_tokens': count == 1
              ? 500
              : count == 2
              ? 1000
              : 1400,
          'route': 'fallback',
          'provider': {'sort': 'latency'},
          'plugins': [
            {'id': 'response-healing'},
          ],
        }),
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode < 200 || response.statusCode >= 300) {
    stderr.writeln(
      'OpenRouter error (${response.statusCode}): ${body['error']}',
    );
    exitCode = 1;
    return;
  }

  final content = _extractContent(body);
  final payload = _extractJsonPayload(content);
  final decoded = jsonDecode(payload);

  final questions = switch (decoded) {
    List<dynamic> list => list,
    Map<String, dynamic> map when map['questions'] is List<dynamic> =>
      map['questions'] as List<dynamic>,
    _ => <dynamic>[],
  };

  if (questions.isEmpty) {
    stderr.writeln('Smoke test failed: no questions returned.');
    exitCode = 1;
    return;
  }

  final firstQuestion = questions.first as Map<String, dynamic>;
  stdout.writeln('Smoke test passed with model: $model');
  stdout.writeln('Question count requested: $count');
  stdout.writeln('Prompt: ${firstQuestion['prompt']}');
}

int _parseCountArg(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--count=')) {
      final parsed = int.tryParse(arg.split('=').last);
      if (parsed != null && parsed >= 1 && parsed <= 3) {
        return parsed;
      }
    }
  }
  return 1;
}

Future<Map<String, String>> _loadEnv() async {
  final candidates = [File('.env'), File('../.env')];
  for (final file in candidates) {
    if (await file.exists()) {
      return _parseEnv(await file.readAsString());
    }
  }
  return <String, String>{};
}

Map<String, String> _parseEnv(String raw) {
  final values = <String, String>{};
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    final key = trimmed.substring(0, separatorIndex).trim();
    final value = trimmed.substring(separatorIndex + 1).trim();
    values[key] = _trimWrapped(value);
  }
  return values;
}

String _trimWrapped(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 2) {
    return trimmed;
  }

  final startsWithQuote = trimmed.startsWith('"') || trimmed.startsWith("'");
  final endsWithQuote = trimmed.endsWith('"') || trimmed.endsWith("'");
  if (startsWithQuote && endsWithQuote) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }

  return trimmed;
}

String _extractContent(Map<String, dynamic> body) {
  final choices = body['choices'] as List<dynamic>;
  final message = choices.first as Map<String, dynamic>;
  final content = (message['message'] as Map<String, dynamic>)['content'];

  if (content is String) {
    return content.trim();
  }

  if (content is List) {
    return content
        .whereType<Map<String, dynamic>>()
        .map((item) => item['text'])
        .whereType<String>()
        .join('\n')
        .trim();
  }

  return '';
}

String _extractJsonPayload(String content) {
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

  return cleaned;
}
