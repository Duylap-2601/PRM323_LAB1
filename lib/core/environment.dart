import 'package:flutter/services.dart';

/// Small bundled `.env` reader. Do not place secrets here: Flutter assets ship
/// inside the application binary.
class Environment {
  static final Map<String, String> _values = {};

  static Future<void> load() async {
    try {
      final text = await rootBundle.loadString('.env');
      for (final rawLine in text.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final split = line.indexOf('=');
        if (split < 1) continue;
        _values[line.substring(0, split).trim()] =
            line.substring(split + 1).trim();
      }
    } catch (_) {
      // Development fallback below keeps tests and local setup usable.
    }
  }

  static String get backendBaseUrl =>
      _values['BACKEND_BASE_URL'] ?? 'http://127.0.0.1:8000/api/v1/';
}
