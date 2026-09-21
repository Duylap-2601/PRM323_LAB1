import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/environment.dart';
import '../models/audit_result_item.dart';
import '../models/citation.dart';
import '../models/enums.dart';
import '../models/evidence.dart';

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

  final Duration pollInterval;
  final Duration pollTimeout;
  final http.Client? customClient;

  BackendAuditService({
    Uri? baseUri,
    this.pollInterval = const Duration(seconds: 2),
    this.pollTimeout = const Duration(minutes: 10),
    this.customClient,
  }) : baseUri = _withTrailingSlash(
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
    _activeClient = customClient ?? http.Client();
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
      if (customClient == null) {
        _activeClient?.close();
      }
      _activeClient = null;
    }
  }

  Future<BackendRunResult> analyze({
    required BackendUpload upload,
    required void Function(String phase, String message) onProgress,
  }) async {
    _activeDocumentId = upload.documentId;
    _activeClient = customClient ?? http.Client();
    final client = _activeClient!;
    try {
      onProgress('analyzing', 'Máy chủ đang đọc PDF và xác minh references…');
      final analyzeResp = await client.post(
        baseUri.resolve('documents/$_activeDocumentId/analyze'),
        headers: _headers,
      );
      final analyzeJson = _decode(analyzeResp.statusCode, analyzeResp.body);

      var status = analyzeJson['status']?.toString() ?? 'processing';
      final startTime = DateTime.now();

      // Poll status if backend returned non-terminal status
      while (status == 'uploaded' || status == 'processing') {
        if (DateTime.now().difference(startTime) > pollTimeout) {
          throw StateError('Thao tác quá thời gian chờ (timeout $pollTimeout).');
        }
        await Future.delayed(pollInterval);
        final statusResp = await client.get(
          baseUri.resolve('documents/$_activeDocumentId/status'),
          headers: _headers,
        );
        final statusJson = _decode(statusResp.statusCode, statusResp.body);
        status = statusJson['status']?.toString() ?? 'processing';

        if (status == 'failed') {
          final err = statusJson['error']?.toString() ?? 'Lỗi không xác định.';
          throw StateError('Máy chủ xử lý thất bại: $err');
        }
        if (status == 'cancelled') {
          throw StateError('Quá trình phân tích document đã bị hủy.');
        }
      }

      onProgress('building_report', 'Đang tải kết quả xác minh…');
      final reportResponse = await client.get(
        baseUri.resolve('documents/$_activeDocumentId/report'),
        headers: _headers,
      );
      final report = _decode(reportResponse.statusCode, reportResponse.body);
      return _mapReport(upload.filename, report);
    } finally {
      if (customClient == null) {
        _activeClient?.close();
      }
      _activeClient = null;
      _activeDocumentId = null;
    }
  }

  void cancel() {
    final documentId = _activeDocumentId;
    if (customClient == null) {
      _activeClient?.close();
    }
    if (documentId != null) {
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
      String msg = 'Máy chủ trả HTTP $statusCode.';
      if (json['message'] is String && (json['message'] as String).isNotEmpty) {
        msg = json['message'] as String;
      } else if (json['detail'] is String && (json['detail'] as String).isNotEmpty) {
        msg = json['detail'] as String;
      } else if (json['detail'] is Map && json['detail']['message'] is String) {
        msg = json['detail']['message'] as String;
      } else if (json['error'] is String && (json['error'] as String).isNotEmpty) {
        msg = json['error'] as String;
      }
      throw StateError(msg);
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
      final evidence = _evidenceFromValidation(
        reference: reference,
        validation: validation,
      );
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
        matchedEvidenceId: evidence.isNotEmpty ? evidence.first.id : null,
        evidence: evidence,
        fieldComparisons: _fieldComparisonsFromValidation(
          reference: reference,
          validation: validation,
        ),
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

  Future<AuditResultItem> reanalyzeReferenceWithLlm(AuditResultItem item) async {
    final uri = baseUri.resolve('documents/reanalyze_reference');
    final payload = jsonEncode({
      'reference_id': 'ref-${item.index + 1}',
      'raw': item.citation,
      'title': item.metadata.title,
      'authors': item.metadata.authors != null ? [item.metadata.authors!] : [],
      'year': int.tryParse(item.metadata.year ?? ''),
      'doi': item.metadata.doi,
    });

    final client = customClient ?? http.Client();
    final res = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    ).timeout(const Duration(seconds: 25));


    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(json['message']?.toString() ?? json['detail']?.toString() ?? 'Lỗi khi gọi LLM re-analyze');
    }

    final val = json['validation'] as Map<String, dynamic>? ?? {};
    final ref = json['reference'] as Map<String, dynamic>? ?? {};
    final llmReasoning = json['llm_reasoning']?.toString();
    final llmConclusion = json['llm_conclusion']?.toString();
    final serverStatus = val['status']?.toString() ?? 'NOT_FOUND';
    final notes = val['notes'] is List
        ? (val['notes'] as List).map((e) => e.toString()).toList()
        : <String>[];
    if (llmReasoning != null && llmReasoning.isNotEmpty) {
      notes.insert(0, llmReasoning);
    }
    if (llmConclusion != null && llmConclusion.isNotEmpty) {
      notes.insert(0, 'LLM: $llmConclusion');
    }

    final status = switch (serverStatus) {
      'VALID' => VerificationStatus.verified,
      'MISMATCH' => VerificationStatus.mismatch,
      'NOT_FOUND' => VerificationStatus.notFound,
      _ => VerificationStatus.needsReview,
    };

    final authors = ref['authors'] is List && (ref['authors'] as List).isNotEmpty
        ? (ref['authors'] as List).join(', ')
        : item.metadata.authors;
    final title = ref['title']?.toString() ?? item.metadata.title;
    final year = ref['year']?.toString() ?? item.metadata.year;
    final doi = ref['doi']?.toString() ?? item.metadata.doi;

    final updatedMetadata = item.metadata.copyWith(
      title: title,
      authors: authors,
      year: year,
      doi: doi,
      metadataMethod: 'llm_reanalysis',
    );
    final evidence = [
      for (final e in (json['llm_evidence'] as List? ?? []))
        if (e is Map) Evidence.fromJson(Map<String, dynamic>.from(e)),
      ..._evidenceFromValidation(reference: ref, validation: val),
    ];
    final reasonParts = [
      if (llmConclusion != null && llmConclusion.isNotEmpty)
        'LLM: $llmConclusion',
      if (llmReasoning != null && llmReasoning.isNotEmpty)
        llmReasoning,
      if (notes.isEmpty) _statusMessage(serverStatus) else notes.join(' · '),
    ];

    assert(reasonParts.isNotEmpty);

    return item.copyWith(
      status: status,
      pred: status == VerificationStatus.verified ? true : false,
      processingState: ProcessingState.completed,
      reason: notes.isEmpty ? _statusMessage(serverStatus) : notes.join(' · '),
      metadata: updatedMetadata,
      found: status != VerificationStatus.notFound,
      match: status == VerificationStatus.verified ? true : (status == VerificationStatus.mismatch ? false : null),
      matchedEvidenceId: evidence.isNotEmpty ? evidence.first.id : null,
      evidence: evidence,
      fieldComparisons: _fieldComparisonsFromValidation(
        reference: ref,
        validation: val,
      ),
    );
  }

  List<Evidence> _evidenceFromValidation({
    required Map<String, dynamic> reference,
    required Map<String, dynamic> validation,
  }) {
    if (validation.isEmpty) return const [];
    final status = validation['status']?.toString() ?? 'UNKNOWN';
    final notes = validation['notes'] is List
        ? (validation['notes'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final doi = reference['doi']?.toString();
    final refUrl = reference['url']?.toString();
    final provider = notes.any((note) => note.toLowerCase().contains('openalex'))
        ? 'openalex'
        : notes.any((note) => note.toLowerCase().contains('url'))
            ? 'url'
            : 'crossref';
    final id = doi != null && doi.isNotEmpty
        ? doi
        : '${reference['id']?.toString() ?? 'reference'}-$provider-$status';
    final url = doi != null && doi.isNotEmpty
        ? 'https://doi.org/$doi'
        : refUrl;

    return [
      Evidence(
        id: id,
        provider: provider,
        url: url,
        metadata: {
          'status': status,
          'confidence': validation['confidence'],
          'title_score': validation['title_score'],
          'author_score': validation['author_score'],
          'year_match': validation['year_match'],
          'doi_valid': validation['doi_valid'],
          'title': reference['title'],
          'authors': reference['authors'],
          'year': reference['year'],
          'notes': notes,
        },
        snippet: notes.isEmpty ? _statusMessage(status) : notes.join(' · '),
      ),
    ];
  }

  List<FieldComparison> _fieldComparisonsFromValidation({
    required Map<String, dynamic> reference,
    required Map<String, dynamic> validation,
  }) {
    if (validation.isEmpty) return const [];

    String scoreResult(dynamic score) {
      final value = score is num
          ? score.toDouble()
          : double.tryParse(score?.toString() ?? '');
      if (value == null) return 'unknown';
      if (value >= 80) return 'match';
      if (value < 60) return 'mismatch';
      return 'unknown';
    }

    String boolResult(dynamic value) {
      if (value is bool) return value ? 'match' : 'mismatch';
      return 'unknown';
    }

    return [
      FieldComparison(
        field: 'title',
        citationValue: reference['title']?.toString(),
        candidateValue: validation['title_score']?.toString(),
        result: scoreResult(validation['title_score']),
        reason: 'Crossref/OpenAlex title similarity',
      ),
      FieldComparison(
        field: 'author',
        citationValue: reference['authors']?.toString(),
        candidateValue: validation['author_score']?.toString(),
        result: scoreResult(validation['author_score']),
        reason: 'Author similarity',
      ),
      FieldComparison(
        field: 'year',
        citationValue: reference['year']?.toString(),
        candidateValue: validation['year_match']?.toString(),
        result: boolResult(validation['year_match']),
        reason: 'Publication year comparison',
      ),
      FieldComparison(
        field: 'doi',
        citationValue: reference['doi']?.toString(),
        candidateValue: validation['doi_valid']?.toString(),
        result: boolResult(validation['doi_valid']),
        reason: 'DOI resolution',
      ),
    ];
  }
}

