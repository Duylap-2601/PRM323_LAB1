import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';

/// Lưu API key/cấu hình local. MVP dùng file JSON trong app support dir.
/// Không nhúng key dùng chung trong build, không log key (plan §8).
class SettingsRepository {
  static const _fileName = 'settings.json';

  Future<String> _path() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}${Platform.pathSeparator}$_fileName';
  }

  Future<AppSettings> load() async {
    try {
      final f = File(await _path());
      if (!await f.exists()) return const AppSettings();
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final f = File(await _path());
    await f.create(recursive: true);
    await f.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}
