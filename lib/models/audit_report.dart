import 'audit_result_item.dart';
import 'citation.dart';
import 'enums.dart';
import 'evidence.dart';

/// Báo cáo kiểm tra. Hỗ trợ đọc legacy `audit.json` và schema v2.
class AuditReport {
  final String schemaVersion;
  final String sourceFile;
  final RunStatus runStatus;
  final Map<String, int> summary;
  final List<AuditResultItem> results;
  final List<String> warnings;

  const AuditReport({
    this.schemaVersion = '2.0',
    this.sourceFile = '',
    this.runStatus = RunStatus.completed,
    this.summary = const {},
    this.results = const [],
    this.warnings = const [],
  });

  bool get isLegacy => schemaVersion == 'legacy';

  /// Import file legacy: không suy đoán status v2 từ `Pred` (schema §4).
  factory AuditReport.fromLegacyJson(Map<String, dynamic> json) {
    final warnings = <String>[];
    final rawResults = json['results'];
    if (rawResults is! List) {
      throw const FormatException('Legacy audit.json thiếu mảng results');
    }
    final items = <AuditResultItem>[];
    final seen = <int>{};
    for (var i = 0; i < rawResults.length; i++) {
      final e = rawResults[i];
      if (e is! Map) {
        warnings.add('Bỏ qua mục #$i vì sai kiểu dữ liệu.');
        continue;
      }
      final m = Map<String, dynamic>.from(e);
      final idx = (m['index'] as num?)?.toInt() ?? i;
      if (!seen.add(idx)) {
        warnings.add('Trùng index $idx.');
      }
      final ver = m['verification'] is Map
          ? Map<String, dynamic>.from(m['verification'] as Map)
          : <String, dynamic>{};
      final cite = ver['citation'] is Map
          ? Map<String, dynamic>.from(ver['citation'] as Map)
          : <String, dynamic>{};
      final raw = (cite['raw'] ?? m['citation'] ?? '').toString();
      items.add(
        AuditResultItem(
          index: idx,
          citation: m['citation']?.toString() ?? raw,
          pred: m['Pred'] as bool?,
          processingState: ProcessingState.completed,
          // Giữ nhãn legacy, chưa đánh giá theo quy tắc v2.
          status: null,
          method: (m['method'] ?? ver['method'] ?? 'legacy').toString(),
          reason:
              'Nhãn legacy chưa kiểm chứng độc lập; cần chạy lại để có kết quả v2. ${m['reason'] ?? ver['reason'] ?? ''}'
                  .trim(),
          extraction: ExtractionInfo(
            metadataMethod: (cite['metadata_method'] ?? 'legacy_import')
                .toString(),
            warnings: const ['Dữ liệu legacy, chưa truy về raw/trang gốc.'],
          ),
          metadata: CitationMetadata.fromJson({...cite, 'raw': raw}, idx),
          found: ver['found'] as bool?,
          match: ver['match'] as bool?,
          matchedResult: (ver['matched_result'] as num?)?.toInt(),
        ),
      );
    }
    final sourceSummary = json['summary'] is Map
        ? Map<String, int>.from(
            (json['summary'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            ),
          )
        : <String, int>{};
    return AuditReport(
      schemaVersion: 'legacy',
      sourceFile: (json['source_file'] ?? '').toString(),
      runStatus: RunStatus.completed,
      summary: sourceSummary,
      results: items..sort((a, b) => a.index.compareTo(b.index)),
      warnings: [
        'File legacy: 33 citation mẫu gồm nhãn real/suspect_fake chưa kiểm chứng, không dùng làm ground truth.',
        ...warnings,
      ],
    );
  }

  factory AuditReport.fromV2Json(Map<String, dynamic> json) {
    final rawResults = json['results'];
    if (rawResults is! List) {
      throw const FormatException('Báo cáo v2 thiếu mảng results');
    }
    final items = <AuditResultItem>[];
    for (var i = 0; i < rawResults.length; i++) {
      final m = Map<String, dynamic>.from(rawResults[i] as Map);
      final ver = m['verification'] is Map
          ? Map<String, dynamic>.from(m['verification'] as Map)
          : <String, dynamic>{};
      final cite = ver['citation'] is Map
          ? Map<String, dynamic>.from(ver['citation'] as Map)
          : <String, dynamic>{};
      items.add(
        AuditResultItem(
          index: (m['index'] as num?)?.toInt() ?? i,
          citation: (m['citation'] ?? cite['raw'] ?? '').toString(),
          pred: m['Pred'] as bool?,
          processingState: processingStateFromJson(
            m['processing_state'] as String?,
          ),
          status: verificationStatusFromJson(m['status'] as String?),
          method: (m['method'] ?? 'none').toString(),
          reason: (m['reason'] ?? '').toString(),
          extraction: ver.isEmpty && m['extraction'] is Map
              ? ExtractionInfo.fromJson(
                  Map<String, dynamic>.from(m['extraction'] as Map),
                )
              : ExtractionInfo.fromJson(
                  m['extraction'] is Map
                      ? Map<String, dynamic>.from(m['extraction'] as Map)
                      : ver,
                ),
          metadata: CitationMetadata.fromJson(
            cite.isEmpty ? {'raw': m['citation']} : cite,
            (m['index'] as num?)?.toInt() ?? i,
          ),
          found: ver['found'] as bool?,
          match: ver['match'] as bool?,
          matchedResult: (ver['matched_result'] as num?)?.toInt(),
          matchedEvidenceId: ver['matched_evidence_id']?.toString(),
          checkedAt: ver['checked_at']?.toString(),
          attempts: [
            for (final a in (ver['attempts'] as List? ?? []))
              if (a is Map)
                LookupAttempt.fromJson(Map<String, dynamic>.from(a)),
          ],
          evidence: [
            for (final e in (ver['evidence'] as List? ?? []))
              if (e is Map) Evidence.fromJson(Map<String, dynamic>.from(e)),
          ],
          fieldComparisons: [
            for (final c in (ver['field_comparisons'] as List? ?? []))
              if (c is Map)
                FieldComparison.fromJson(Map<String, dynamic>.from(c)),
          ],
          error: ver['error']?.toString(),
        ),
      );
    }
    return AuditReport(
      schemaVersion: (json['schema_version'] ?? '2.0').toString(),
      sourceFile: (json['source_file'] ?? '').toString(),
      runStatus: runStatusFromJson(json['run_status'] as String?),
      summary: json['summary'] is Map
          ? Map<String, int>.from(
              (json['summary'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              ),
            )
          : recomputeSummary(items),
      results: items..sort((a, b) => a.index.compareTo(b.index)),
    );
  }

  static Map<String, int> recomputeSummary(List<AuditResultItem> items) {
    var processed = 0, verified = 0, mismatch = 0, notFound = 0;
    var needsReview = 0, error = 0, pending = 0, running = 0, cancelled = 0;
    for (final it in items) {
      switch (it.processingState) {
        case ProcessingState.pending:
          pending++;
          break;
        case ProcessingState.running:
          running++;
          break;
        case ProcessingState.cancelled:
          cancelled++;
          break;
        case ProcessingState.completed:
        case ProcessingState.failed:
          processed++;
          switch (it.status) {
            case VerificationStatus.verified:
              verified++;
              break;
            case VerificationStatus.mismatch:
              mismatch++;
              break;
            case VerificationStatus.notFound:
              notFound++;
              break;
            case VerificationStatus.error:
              error++;
              break;
            default:
              needsReview++;
          }
      }
    }
    return {
      'total': items.length,
      'processed': processed,
      'pending': pending,
      'running': running,
      'cancelled': cancelled,
      'verified': verified,
      'mismatch': mismatch,
      'not_found': notFound,
      'needs_review': needsReview,
      'error': error,
      'real': verified,
      'suspect_fake': processed - verified,
    };
  }

  Map<String, dynamic> toV2Json() => {
    'schema_version': '2.0',
    'source_file': sourceFile,
    'run_status': runStatusToJson(runStatus),
    'summary': recomputeSummary(results),
    'results': [for (final r in results) r.toV2Json()],
  };

  /// Chỉ export legacy khi run hoàn tất và mọi mục có kết quả cuối.
  Map<String, dynamic> toLegacyJson() {
    if (runStatus != RunStatus.completed) {
      throw StateError('Không xuất legacy cho báo cáo chưa hoàn tất.');
    }
    for (final r in results) {
      if (r.pred == null) {
        throw StateError('Mục #${r.index} chưa có Pred, không xuất legacy.');
      }
    }
    final s = recomputeSummary(results);
    return {
      'source_file': sourceFile,
      'summary': {
        'total': s['total'],
        'real': s['real'],
        'suspect_fake': s['suspect_fake'],
      },
      'results': [
        for (final r in results)
          {
            'index': r.index,
            'citation': r.citation,
            'Pred': r.pred,
            'method': r.method,
            'reason': r.reason,
            'verification': {
              'match': r.match,
              'matched_result': r.matchedResult,
              'note': r.reason,
              'method': r.method,
              'found': r.found,
              'reason': r.reason,
              'citation': r.metadata.toJson(),
            },
          },
      ],
    };
  }
}
