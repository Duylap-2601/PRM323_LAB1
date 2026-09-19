import 'enums.dart';

/// Metadata của một citation. Raw luôn giữ nguyên, các trường
/// null nghĩa là không đọc được — không tự bịa (plan §5.4).
class CitationMetadata {
  final int index;
  final String raw;
  final String? title;
  final String? authors;
  final String? venue;
  final String? year;
  final String? doi;
  final String? url;
  final String metadataMethod;

  const CitationMetadata({
    required this.index,
    required this.raw,
    this.title,
    this.authors,
    this.venue,
    this.year,
    this.doi,
    this.url,
    this.metadataMethod = 'dart_parser',
  });

  static String? _norm(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s == 'N/A') return null;
    return s;
  }

  factory CitationMetadata.fromJson(
    Map<String, dynamic> json,
    int fallbackIndex,
  ) {
    return CitationMetadata(
      index: (json['index'] as num?)?.toInt() ?? fallbackIndex,
      raw: (json['raw'] ?? '').toString(),
      title: _norm(json['title']),
      authors: _norm(json['authors']),
      venue: _norm(json['venue']),
      year: _norm(json['year']),
      doi: _norm(json['doi']),
      url: _norm(json['url']),
      metadataMethod: (json['metadata_method'] ?? 'dart_parser').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'raw': raw,
    'title': title,
    'authors': authors,
    'venue': venue,
    'year': year,
    'doi': doi,
    'url': url,
    'metadata_method': metadataMethod,
  };

  CitationMetadata copyWith({
    String? title,
    String? authors,
    String? venue,
    String? year,
    String? doi,
    String? url,
    String? metadataMethod,
    bool clearTitle = false,
    bool clearDoi = false,
    bool clearUrl = false,
  }) {
    return CitationMetadata(
      index: index,
      raw: raw,
      title: clearTitle ? null : (title ?? this.title),
      authors: authors ?? this.authors,
      venue: venue ?? this.venue,
      year: year ?? this.year,
      doi: clearDoi ? null : (doi ?? this.doi),
      url: clearUrl ? null : (url ?? this.url),
      metadataMethod: metadataMethod ?? this.metadataMethod,
    );
  }
}

/// Thông tin trích xuất gắn với citation (plan §5.5).
class ExtractionInfo {
  /// Số trang theo file gốc, bắt đầu từ 1. Rỗng nếu đầu vào không có trang.
  final List<int> sourcePages;
  final ExtractionStatus status;
  final String metadataMethod;
  final List<String> warnings;
  final bool userEdited;

  const ExtractionInfo({
    this.sourcePages = const [],
    this.status = ExtractionStatus.extracted,
    this.metadataMethod = 'dart_parser',
    this.warnings = const [],
    this.userEdited = false,
  });

  factory ExtractionInfo.fromJson(Map<String, dynamic> json) {
    final pages = json['source_pages'];
    return ExtractionInfo(
      sourcePages: pages is List
          ? [for (final p in pages) (p as num).toInt()]
          : const [],
      status: extractionStatusFromJson(json['extraction_status'] as String?),
      metadataMethod: (json['metadata_method'] ?? 'dart_parser').toString(),
      warnings: switch (json['warnings']) {
        List l => [for (final w in l) w.toString()],
        _ => const [],
      },
      userEdited: json['user_edited'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'source_pages': sourcePages,
    'extraction_status': extractionStatusToJson(status),
    'metadata_method': metadataMethod,
    'warnings': warnings,
    'user_edited': userEdited,
  };

  ExtractionInfo copyWith({
    List<int>? sourcePages,
    ExtractionStatus? status,
    String? metadataMethod,
    List<String>? warnings,
    bool? userEdited,
  }) {
    return ExtractionInfo(
      sourcePages: sourcePages ?? this.sourcePages,
      status: status ?? this.status,
      metadataMethod: metadataMethod ?? this.metadataMethod,
      warnings: warnings ?? this.warnings,
      userEdited: userEdited ?? this.userEdited,
    );
  }
}

/// Tiến độ pipeline để UI hiển thị và hỗ trợ hủy (plan §4).
class AuditProgress {
  final String phase; // import | extract | verify | export | done
  final int done;
  final int total;
  final String message;
  final int? currentIndex;

  const AuditProgress({
    required this.phase,
    required this.done,
    required this.total,
    this.message = '',
    this.currentIndex,
  });

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0, 1);
}
