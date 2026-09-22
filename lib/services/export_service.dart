import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/audit_report.dart';
import '../utils/file_io.dart';

/// Xuất JSON v2/legacy + mở file báo cáo có sẵn (plan §2.7, §8).
class ExportService {
  Future<Uri?> exportV2(AuditReport report) async {
    final json = const JsonEncoder.withIndent('  ').convert(report.toV2Json());
    return FilePicker.saveFile(
      fileName: 'audit_report_v2.json',
      bytes: Uint8List.fromList(utf8.encode(json)),
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  }

  Future<Uri?> exportLegacy(AuditReport report) async {
    final legacy = report.toLegacyJson(); // ném nếu chưa hoàn tất
    return FilePicker.saveFile(
      fileName: 'audit.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(legacy))),
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  }

  Future<void> saveToPath(String path, AuditReport report) async {
    await writeFileAtomically(path, jsonEncode(report.toV2Json()));
  }
}
