import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/audit_report.dart';
import '../models/audit_result_item.dart';
import '../models/citation.dart';
import '../models/enums.dart';
import '../repositories/audit_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/backend_audit_service.dart';
import '../services/document_service.dart';
import '../services/export_service.dart';

/// UI state only. PDF parsing, reference lookup and verification run in FastAPI.
class AuditController extends ChangeNotifier {
  final DocumentService documents;
  final BackendAuditService backend;
  final AuditRepository reports;
  final SettingsRepository settingsRepo;
  final ExportService exporter;

  AppSettings settings = const AppSettings();
  AuditReport? report;
  List<AuditResultItem> workingItems = [];
  AuditProgress progress = const AuditProgress(phase: 'idle', done: 0, total: 0);
  String? errorMessage;
  final List<String> uiLogs = [];
  bool busy = false;
  String sourceLabel = '';
  String? lastSavedPath;
  BackendUpload? uploadedDocument;

  /// A completed upload is submitted once. Importing a new PDF clears [report]
  /// and enables analysis again.
  bool get readyToAnalyze => uploadedDocument != null && report == null && !busy;

  bool _cancelled = false;

  AuditController({
    DocumentService? documents,
    BackendAuditService? backend,
    AuditRepository? reports,
    SettingsRepository? settingsRepo,
    ExportService? exporter,
  })  : documents = documents ?? DocumentService(),
        backend = backend ?? BackendAuditService(),
        reports = reports ?? AuditRepository(),
        settingsRepo = settingsRepo ?? SettingsRepository(),
        exporter = exporter ?? ExportService();

  Future<void> init() async {
    settings = await settingsRepo.load();
    _log('Backend: ${backend.baseUri}');
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = next;
    await settingsRepo.save(next);
    notifyListeners();
  }

  Future<void> importPickedFile() async {
    if (busy) return;
    _cancelled = false;
    errorMessage = null;
    _log('Bắt đầu chọn PDF.');
    _setProgress('importing', 'Đang chọn file PDF…');
    _setBusy(true);
    try {
      final picked = await documents.pickDocument();
      if (_cancelled) {
        _finishCancelled();
        return;
      }
      if (picked == null) {
        _log('Người dùng đóng file picker.');
        _finishIdle();
        return;
      }
      final document = await documents.fromPickedFile(picked);
      _log('Đã chọn ${document.fileName} (${document.bytes.length} bytes).');
      if (_cancelled) {
        _finishCancelled();
        return;
      }
      final upload = await backend.upload(
        filename: document.fileName,
        bytes: document.bytes,
        onProgress: _setProgress,
      );
      if (_cancelled) {
        _finishCancelled();
        return;
      }
      uploadedDocument = upload;
      sourceLabel = upload.filename;
      report = null;
      workingItems = [];
      _log('Upload hoàn tất. document_id=${upload.documentId}');
      _setProgress('uploaded', 'Đã upload PDF. Bấm Bắt đầu phân tích để xử lý.');
      _setBusy(false);
    } catch (e, stackTrace) {
      if (_cancelled) {
        _log('Request đã hủy.');
        _finishCancelled();
      } else {
        _log('Lỗi: $e\n$stackTrace');
        _setBusy(false, 'Không thể upload PDF: ${_friendlyServerError(e)}');
      }
    }
  }

  Future<void> startAnalysis() async {
    final upload = uploadedDocument;
    if (busy || upload == null) return;
    _cancelled = false;
    errorMessage = null;
    _setBusy(true);
    try {
      final result = await backend.analyze(
        upload: upload,
        onProgress: _setProgress,
      );
      if (_cancelled) {
        _log('Request đã hủy.');
        _finishCancelled();
        return;
      }
      workingItems = result.items;
      _log('Server trả ${result.items.length} references.');
      report = AuditReport(
        sourceFile: result.sourceLabel,
        summary: AuditReport.recomputeSummary(workingItems),
        results: workingItems,
        warnings: result.warnings,
      );
      try {
        lastSavedPath = await reports.saveReport(report!).timeout(const Duration(milliseconds: 50));
      } catch (_) {
        // Export/copy in the workspace remains available when local save fails.
      }
      _setProgress('done', 'Hoàn tất: ${workingItems.length} references đã được máy chủ xử lý.');
      _setBusy(false);
    } catch (e, stackTrace) {
      if (_cancelled) {
        _log('Request đã hủy.');
        _finishCancelled();
      } else {
        _log('Lỗi: $e\n$stackTrace');
        _setBusy(false, 'Không thể phân tích PDF trên máy chủ: $e');
      }
    }
  }

  void cancel() {
    if (!busy) return;
    _cancelled = true;
    _log('Người dùng yêu cầu hủy.');
    backend.cancel();
    _setProgress('cancelling', 'Đang yêu cầu máy chủ hủy tác vụ…');
  }

  void _setProgress(String phase, String message) {
    const steps = <String, (int, int)>{
      'importing': (1, 5),
      'uploading': (2, 5),
      'uploaded': (2, 5),
      'analyzing': (3, 5),
      'building_report': (4, 5),
      'done': (5, 5),
    };
    final step = steps[phase] ?? (0, 0);
    progress = AuditProgress(
      phase: phase,
      done: step.$1,
      total: step.$2,
      message: message,
    );
    if (message.isNotEmpty) _log('[$phase] $message');
    notifyListeners();
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String().substring(11, 19);
    uiLogs.add('$now  $message');
    if (uiLogs.length > 100) uiLogs.removeAt(0);
    debugPrint('[CitationAudit] $message');
  }

  String _friendlyServerError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('ClientException')) {
      return 'Không kết nối được tới ngrok/FastAPI. Kiểm tra server và tunnel đang chạy.';
    }
    return text;
  }

  void _setBusy(bool value, [String? error]) {
    busy = value;
    errorMessage = error;
    notifyListeners();
  }

  void _finishIdle() {
    _setProgress('idle', '');
    _setBusy(false);
  }

  void _finishCancelled() {
    uploadedDocument = null;
    _setProgress('cancelled', 'Đã hủy.');
    _setBusy(false);
  }

  Future<List<Map<String, String>>> history() => reports.history();

  Future<void> openHistory(String path) async {
    _setBusy(true);
    try {
      report = await reports.loadReport(path);
      workingItems = List<AuditResultItem>.from(report!.results);
      sourceLabel = report!.sourceFile;
    } catch (e) {
      _setBusy(false, e.toString());
      return;
    }
    _setBusy(false);
  }

  Future<void> reanalyzeItemWithLlm(AuditResultItem item) async {
    _log('Đang dùng LLM phân tích lại mục [${item.index + 1}]...');
    try {
      final updated = await backend.reanalyzeReferenceWithLlm(item);
      final idx = workingItems.indexWhere((it) => it.index == item.index);
      if (idx != -1) {
        workingItems[idx] = updated;
        if (report != null) {
          report = AuditReport(
            sourceFile: report!.sourceFile,
            summary: AuditReport.recomputeSummary(workingItems),
            results: List.from(workingItems),
            warnings: report!.warnings,
          );
        }
        _log('Mục [${item.index + 1}] đã được LLM phân tích lại.');
        notifyListeners();
      }
    } catch (e) {
      _log('Lỗi khi phân tích LLM mục [${item.index + 1}]: $e');
      rethrow;
    }
  }

  Future<void> reanalyzeAllNeedsReviewWithLlm() async {
    final targets = workingItems.where((it) =>
      it.status == VerificationStatus.needsReview ||
      it.status == VerificationStatus.mismatch ||
      it.status == VerificationStatus.notFound
    ).toList();

    if (targets.isEmpty) {
      _log('Không có mục nào cần phân tích lại.');
      return;
    }

    _log('Bắt đầu phân tích LLM cho ${targets.length} mục...');
    _setBusy(true);
    for (final target in targets) {
      try {
        await reanalyzeItemWithLlm(target);
      } catch (e) {
        _log('Bỏ qua mục [${target.index + 1}] do lỗi: $e');
      }
    }
    _setBusy(false);
  }
}

