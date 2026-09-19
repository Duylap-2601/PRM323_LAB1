/// Cài đặt app: provider/model, timeout, concurrency, hạn mức.
/// API key do người dùng nhập, lưu qua SettingsRepository (plan §8).
class AppSettings {
  final String llmProvider;
  final String llmModel;
  final String apiKey;
  final int timeoutSeconds;
  final int maxConcurrency;
  final int maxPagesPerRun;
  final String crossrefMailto;

  const AppSettings({
    this.llmProvider = 'gemini',
    this.llmModel = '',
    this.apiKey = '',
    this.timeoutSeconds = 30,
    this.maxConcurrency = 3,
    this.maxPagesPerRun = 200,
    this.crossrefMailto = '',
  });

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    llmProvider: (json['llm_provider'] ?? 'gemini').toString(),
    llmModel: (json['llm_model'] ?? '').toString(),
    apiKey: (json['api_key'] ?? '').toString(),
    timeoutSeconds: (json['timeout_seconds'] as num?)?.toInt() ?? 30,
    maxConcurrency: (json['max_concurrency'] as num?)?.toInt() ?? 3,
    maxPagesPerRun: (json['max_pages_per_run'] as num?)?.toInt() ?? 200,
    crossrefMailto: (json['crossref_mailto'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'llm_provider': llmProvider,
    'llm_model': llmModel,
    'api_key': apiKey,
    'timeout_seconds': timeoutSeconds,
    'max_concurrency': maxConcurrency,
    'max_pages_per_run': maxPagesPerRun,
    'crossref_mailto': crossrefMailto,
  };

  AppSettings copyWith({
    String? llmProvider,
    String? llmModel,
    String? apiKey,
    int? timeoutSeconds,
    int? maxConcurrency,
    int? maxPagesPerRun,
    String? crossrefMailto,
  }) {
    return AppSettings(
      llmProvider: llmProvider ?? this.llmProvider,
      llmModel: llmModel ?? this.llmModel,
      apiKey: apiKey ?? this.apiKey,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
      maxPagesPerRun: maxPagesPerRun ?? this.maxPagesPerRun,
      crossrefMailto: crossrefMailto ?? this.crossrefMailto,
    );
  }
}
