import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/audit_report.dart';
import '../utils/file_io.dart';

/// Lưu báo cáo JSON + chỉ mục lịch sử local (plan §4).
class AuditRepository {
  static const _historyFile = 'history_index.json';

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}${Platform.pathSeparator}reports');
    await d.create(recursive: true);
    return d;
  }

  Future<String> saveReport(AuditReport report, {String? fileName}) async {
    final dir = await _dir();
    final name =
        fileName ??
        'report_${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.json';
    final path = '${dir.path}${Platform.pathSeparator}$name';
    await writeFileAtomically(path, jsonEncode(report.toV2Json()));
    await _addHistory(path, report.sourceFile);
    return path;
  }

  Future<AuditReport> loadReport(String path) async {
    final json = jsonDecode(await File(path).readAsString());
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Báo cáo không phải object JSON');
    }
    if (json.containsKey('schema_version')) {
      return AuditReport.fromV2Json(json);
    }
    return AuditReport.fromLegacyJson(json);
  }

  Future<List<Map<String, String>>> history() async {
    try {
      final base = await getApplicationSupportDirectory();
      final f = File('${base.path}${Platform.pathSeparator}$_historyFile');
      if (!await f.exists()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return [for (final e in list) Map<String, String>.from(e as Map)];
    } catch (_) {
      return [];
    }
  }

  Future<void> _addHistory(String path, String source) async {
    final base = await getApplicationSupportDirectory();
    final f = File('${base.path}${Platform.pathSeparator}$_historyFile');
    final cur = await history();
    cur.insert(0, {
      'path': path,
      'source': source,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    });
    await f.create(recursive: true);
    await f.writeAsString(jsonEncode(cur.take(100).toList()), flush: true);
  }
}
