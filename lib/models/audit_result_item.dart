import 'citation.dart';
import 'enums.dart';
import 'evidence.dart';

/// Một mục kết quả trong báo cáo (gộp extraction + verification).
class AuditResultItem {
  final int index;
  final String citation;
  final bool? pred; // legacy: true=verified. v2: null khi chưa đánh giá.
  final ProcessingState processingState;
  final VerificationStatus? status;
  final String method;
  final String reason;
  final ExtractionInfo extraction;
  final CitationMetadata metadata;
  final bool? found;
  final bool? match;
  final int? matchedResult;
  final String? matchedEvidenceId;
  final String? checkedAt;
  final List<LookupAttempt> attempts;
  final List<Evidence> evidence;
  final List<FieldComparison> fieldComparisons;
  final String? error;

  const AuditResultItem({
    required this.index,
    required this.citation,
    this.pred,
    this.processingState = ProcessingState.pending,
    this.status,
    this.method = 'none',
    this.reason = '',
    this.extraction = const ExtractionInfo(),
    required this.metadata,
    this.found,
    this.match,
    this.matchedResult,
    this.matchedEvidenceId,
    this.checkedAt,
    this.attempts = const [],
    this.evidence = const [],
    this.fieldComparisons = const [],
    this.error,
  });

  Map<String, dynamic> toV2Json() => {
    'index': index,
    'citation': citation,
    'Pred': pred,
    'processing_state': processingStateToJson(processingState),
    'status': verificationStatusToJson(status),
    'method': method,
    'reason': reason,
    'extraction': extraction.toJson(),
    'verification': {
      'found': found,
      'match': match,
      'matched_result': matchedResult,
      'matched_evidence_id': matchedEvidenceId,
      'checked_at': checkedAt,
      'citation': metadata.toJson(),
      'attempts': [for (final a in attempts) a.toJson()],
      'evidence': [for (final e in evidence) e.toJson()],
      'field_comparisons': [for (final c in fieldComparisons) c.toJson()],
      'error': error,
    },
  };

  AuditResultItem copyWith({
    String? citation,
    bool? pred,
    ProcessingState? processingState,
    VerificationStatus? status,
    bool clearStatus = false,
    String? method,
    String? reason,
    ExtractionInfo? extraction,
    CitationMetadata? metadata,
    bool? found,
    bool? match,
    int? matchedResult,
    String? matchedEvidenceId,
    String? checkedAt,
    List<LookupAttempt>? attempts,
    List<Evidence>? evidence,
    List<FieldComparison>? fieldComparisons,
    String? error,
  }) {
    return AuditResultItem(
      index: index,
      citation: citation ?? this.citation,
      pred: pred ?? this.pred,
      processingState: processingState ?? this.processingState,
      status: clearStatus ? null : (status ?? this.status),
      method: method ?? this.method,
      reason: reason ?? this.reason,
      extraction: extraction ?? this.extraction,
      metadata: metadata ?? this.metadata,
      found: found ?? this.found,
      match: match ?? this.match,
      matchedResult: matchedResult ?? this.matchedResult,
      matchedEvidenceId: matchedEvidenceId ?? this.matchedEvidenceId,
      checkedAt: checkedAt ?? this.checkedAt,
      attempts: attempts ?? this.attempts,
      evidence: evidence ?? this.evidence,
      fieldComparisons: fieldComparisons ?? this.fieldComparisons,
      error: error ?? this.error,
    );
  }
}
