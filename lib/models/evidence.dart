/// Bằng chứng tra cứu do app thu thập (không nhận URL do model tự bịa).
class Evidence {
  final String id;
  final String provider;
  final String? url;
  final String? retrievedAt;
  final Map<String, dynamic> metadata;
  final String? snippet;

  const Evidence({
    required this.id,
    required this.provider,
    this.url,
    this.retrievedAt,
    this.metadata = const {},
    this.snippet,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: (json['id'] ?? '').toString(),
    provider: (json['provider'] ?? 'unknown').toString(),
    url: json['url']?.toString(),
    retrievedAt: json['retrieved_at']?.toString(),
    metadata: switch (json['metadata']) {
      Map m => Map<String, dynamic>.from(m),
      _ => const {},
    },
    snippet: json['snippet']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'url': url,
    'retrieved_at': retrievedAt,
    'metadata': metadata,
    'snippet': snippet,
  };
}

/// Một lần thử tra cứu (để phân biệt not_found thật vs lỗi kỹ thuật).
class LookupAttempt {
  final String provider;
  final String query;
  final String outcome; // found | not_found | error | skipped
  final String? errorCode;
  final String? checkedAt;

  const LookupAttempt({
    required this.provider,
    required this.query,
    required this.outcome,
    this.errorCode,
    this.checkedAt,
  });

  factory LookupAttempt.fromJson(Map<String, dynamic> json) => LookupAttempt(
    provider: (json['provider'] ?? '').toString(),
    query: (json['query'] ?? json['identifier'] ?? '').toString(),
    outcome: (json['outcome'] ?? 'error').toString(),
    errorCode: json['error_code']?.toString() ?? json['error']?.toString(),
    checkedAt: json['checked_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'query': query,
    'outcome': outcome,
    'error_code': errorCode,
    'checked_at': checkedAt,
  };
}

/// So sánh từng trường citation vs ứng viên.
class FieldComparison {
  final String field;
  final String? citationValue;
  final String? candidateValue;
  final String result; // match | mismatch | unknown
  final String? reason;

  const FieldComparison({
    required this.field,
    this.citationValue,
    this.candidateValue,
    required this.result,
    this.reason,
  });

  factory FieldComparison.fromJson(Map<String, dynamic> json) =>
      FieldComparison(
        field: (json['field'] ?? '').toString(),
        citationValue: json['citation_value']?.toString(),
        candidateValue: json['candidate_value']?.toString(),
        result: (json['result'] ?? 'unknown').toString(),
        reason: json['reason']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'field': field,
    'citation_value': citationValue,
    'candidate_value': candidateValue,
    'result': result,
    'reason': reason,
  };
}
