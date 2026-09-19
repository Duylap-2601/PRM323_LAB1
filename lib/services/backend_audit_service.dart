import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/environment.dart';
import '../models/audit_result_item.dart';
import '../models/citation.dart';
import '../models/enums.dart';

class BackendRunResult {
  final String sourceLabel;
  final List<AuditResultItem> items;
  final List<String> warnings;

  const BackendRunResult({
    required this.sourceLabel,
    required this.items,
    this.warnings = const [],
  });
}

class BackendUpload {
  final String documentId;
  final String filename;

  const BackendUpload({required this.documentId, required this.filename});
}

class BackendAuditService {
  final Uri baseUri;
  http.Client? _activeClient;
  String? _activeDocumentId;

  BackendAuditService({Uri? baseUri})
      : baseUri = _withTrailingSlash(
          baseUri ?? Uri.parse(Environment.backendBaseUrl),
        );

  static Uri _withTrailingSlash(Uri uri) =>
      uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');

  static const _headers = {'ngrok-skip-browser-warning': 'true'};

  Uri get _healthUri => baseUri.replace(path: '/health', query: null);

  Future<BackendUpload> upload({
    required String filename,
    required Uint8List bytes,
    required void Function(String phase, String message) onProgress,
  }) async {
    _activeClient = http.Client();
    try {
      final health = await _activeClient!.get(_healthUri, headers: _headers);
      _decodeHealth(health.statusCode, health.body);
      onProgress('uploading', 'Đang gửi PDF tới máy chủ…');
      final upload = http.MultipartRequest(
          'POST', baseUri.resolve('documents/upload'))
        ..headers.addAll(_headers)
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await _activeClient!.send(upload);
      final uploadBody = await streamed.stream.bytesToString();
      final uploadJson = _decode(streamed.statusCode, uploadBody);
      _activeDocumentId = uploadJson['document_id']?.toString();
      if (_activeDocumentId == null || _activeDocumentId!.isEmpty) {
        throw const FormatException('Máy chủ không trả document_id.');
      }
      return BackendUpload(documentId: _activeDocumentId!, filename: filename);
    } finally {
      _activeClient?.close();
      _activeClient = null;
    }
  }

  Future<BackendRunResult> analyze({
    required BackendUpload upload,
    required void Function(String phase, String message) onProgress,
  }) async {
    _activeDocumentId = upload.documentId;
    _activeClient = http.Client();
    try {
      onProgress('analyzing', 'Máy chủ đang đọc PDF và xác minh references…');
      final analyze = await _activeClient!.post(
        baseUri.resolve('documents/$_activeDocumentId/analyze'),
        headers: _headers,
      );
      _decode(analyze.statusCode, analyze.body);

      onProgress('building_report', 'Đang tải kết quả xác minh…');
      final reportResponse = await _activeClient!.get(
        baseUri.resolve('documents/$_activeDocumentId/report'),
        headers: _headers,
      );
      final report = _decode(reportResponse.statusCode, reportResponse.body);
      return _mapReport(upload.filename, report);
    } finally {
      _activeClient?.close();
      _activeClient = null;
      _activeDocumentId = null;
    }
  }

  void cancel() {
    final documentId = _activeDocumentId;
    _activeClient?.close();
    if (documentId != null) {
      // Best effort: the client is already closed, so cancellation must use a new request.
      unawaited(
        http.post(
          baseUri.resolve('documents/$documentId/cancel'),
          headers: _headers,
        ),
      );
    }
  }

  Map<String, dynamic> _decode(int statusCode, String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        throw StateError(
          'Ngrok không kết nối được tới FastAPI (HTTP $statusCode). Hãy chạy lại FastAPI và tunnel ngrok.',
        );
      }
      throw StateError('Máy chủ trả dữ liệu không hợp lệ (HTTP $statusCode).');
    }
    final json = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError(json['message'] ?? 'Máy chủ trả HTTP $statusCode.');
    }
    return json;
  }

  void _decodeHealth(int statusCode, String body) {
    if (statusCode == 200) return;
    // Health may be a small non-JSON proxy response, so retain the useful status.
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      throw StateError(
        'Ngrok không kết nối được tới FastAPI (HTTP $statusCode). Hãy chạy lại FastAPI và tunnel ngrok.',
      );
    }
    throw StateError('Health check thất bại (HTTP $statusCode): $body');
  }

  BackendRunResult _mapReport(String filename, Map<String, dynamic> report) {
    final refs = report['references'] is List ? report['references'] as List : const [];
    final validations = report['validations'] is List ? report['validations'] as List : const [];
    final validationById = <String, Map<String, dynamic>>{
      for (final item in validations)
        if (item is Map) item['reference_id']?.toString() ?? '': Map<String, dynamic>.from(item),
    };
    final items = <AuditResultItem>[];
    for (var index = 0; index < refs.length; index++) {
      if (refs[index] is! Map) continue;
      final reference = Map<String, dynamic>.from(refs[index] as Map);
      final validation = validationById[reference['id']?.toString()] ?? const {};
      final serverStatus = validation['status']?.toString() ?? 'NOT_FOUND';
      final status = switch (serverStatus) {
        'VALID' => VerificationStatus.verified,
        'MISMATCH' => VerificationStatus.mismatch,
        'NOT_FOUND' => VerificationStatus.notFound,
        _ => VerificationStatus.needsReview,
      };
      final notes = validation['notes'] is List
          ? (validation['notes'] as List).map((e) => e.toString()).toList()
          : <String>[];
      final authors = reference['authors'] is List
          ? (reference['authors'] as List).join(', ')
          : null;
      final doi = reference['doi']?.toString();
      final url = reference['url']?.toString();
      final metadata = CitationMetadata(
        index: index,
        raw: reference['raw']?.toString() ?? '',
        title: reference['title']?.toString(),
        authors: authors,
        venue: reference['journal']?.toString(),
        year: reference['year']?.toString(),
        doi: doi,
        url: url ?? (doi == null ? null : 'https://doi.org/$doi'),
        metadataMethod: 'fastapi',
      );
      items.add(AuditResultItem(
        index: index,
        citation: metadata.raw,
        pred: status == VerificationStatus.verified ? true : false,
        processingState: ProcessingState.completed,
        status: status,
        method: 'fastapi_crossref',
        reason: notes.isEmpty ? _statusMessage(serverStatus) : notes.join(' · '),
        extraction: ExtractionInfo(
          sourcePages: reference['page'] is num ? [(reference['page'] as num).toInt()] : const [],
          metadataMethod: 'fastapi',
        ),
        metadata: metadata,
        found: status != VerificationStatus.notFound,
        match: status == VerificationStatus.verified
            ? true
            : status == VerificationStatus.mismatch
                ? false
                : null,
      ));
    }
    final issues = report['issues'] is List
        ? [for (final issue in report['issues'] as List) if (issue is Map) issue['message']?.toString() ?? '']
        : <String>[];
    return BackendRunResult(sourceLabel: filename, items: items, warnings: issues.where((e) => e.isNotEmpty).toList());
  }

  String _statusMessage(String status) => switch (status) {
        'VALID' => 'Thông tin khớp với nguồn Crossref.',
        'MISMATCH' => 'Thông tin khác với nguồn Crossref.',
        'NOT_FOUND' => 'Không tìm thấy nguồn phù hợp trên Crossref.',
        'PARTIAL' => 'Bằng chứng chưa đủ để xác minh hoàn toàn.',
        'AMBIGUOUS' => 'Có nhiều nguồn gần khớp, cần xem lại.',
        _ => 'Máy chủ chưa trả kết luận.',
      };
}
