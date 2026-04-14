import 'package:flutter/services.dart';

class AppConfig {
  static const _defaultOpenRouterModel = 'openai/gpt-4o-mini';

  static Map<String, String> _env = <String, String>{};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) {
      return;
    }

    try {
      final raw = await rootBundle.loadString('.env');
      _env = _parseEnv(raw);
    } catch (_) {
      _env = <String, String>{};
    }

    _loaded = true;
  }

  static String get openRouterApiKey {
    final defineValue = _trimWrapped(
      const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: ''),
    );
    if (defineValue.isNotEmpty) {
      return defineValue;
    }

    return _trimWrapped(_env['OPENROUTER_API_KEY'] ?? '');
  }

  static String get openRouterModel {
    final defineValue = _trimWrapped(
      const String.fromEnvironment('OPENROUTER_MODEL', defaultValue: ''),
    );
    if (defineValue.isNotEmpty) {
      return defineValue;
    }

    final envValue = _trimWrapped(_env['OPENROUTER_MODEL'] ?? '');
    return envValue.isEmpty ? _defaultOpenRouterModel : envValue;
  }

  static bool get hasOpenRouterApiKey => openRouterApiKey.isNotEmpty;

  static Map<String, String> _parseEnv(String raw) {
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

  static String _trimWrapped(String value) {
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
}
