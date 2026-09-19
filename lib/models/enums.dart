/// Trạng thái trích xuất của một citation (response-schema.md §1).
enum ExtractionStatus { extracted, needsReview, error }

/// Kết luận xác minh v2. `null` nghĩa là chưa đánh giá.
enum VerificationStatus { verified, mismatch, notFound, needsReview, error }

/// Trạng thái xử lý của từng mục (checkpoint).
enum ProcessingState { pending, running, completed, failed, cancelled }

/// Trạng thái của cả lần chạy.
enum RunStatus { running, completed, cancelled, failed }

String extractionStatusToJson(ExtractionStatus s) => switch (s) {
  ExtractionStatus.extracted => 'extracted',
  ExtractionStatus.needsReview => 'needs_review',
  ExtractionStatus.error => 'error',
};

ExtractionStatus extractionStatusFromJson(String? s) => switch (s) {
  'extracted' => ExtractionStatus.extracted,
  'error' => ExtractionStatus.error,
  _ => ExtractionStatus.needsReview,
};

String? verificationStatusToJson(VerificationStatus? s) => switch (s) {
  null => null,
  VerificationStatus.verified => 'verified',
  VerificationStatus.mismatch => 'mismatch',
  VerificationStatus.notFound => 'not_found',
  VerificationStatus.needsReview => 'needs_review',
  VerificationStatus.error => 'error',
};

VerificationStatus? verificationStatusFromJson(String? s) => switch (s) {
  'verified' => VerificationStatus.verified,
  'mismatch' => VerificationStatus.mismatch,
  'not_found' => VerificationStatus.notFound,
  'needs_review' => VerificationStatus.needsReview,
  'error' => VerificationStatus.error,
  _ => null,
};

String processingStateToJson(ProcessingState s) => switch (s) {
  ProcessingState.pending => 'pending',
  ProcessingState.running => 'running',
  ProcessingState.completed => 'completed',
  ProcessingState.failed => 'failed',
  ProcessingState.cancelled => 'cancelled',
};

ProcessingState processingStateFromJson(String? s) => switch (s) {
  'running' => ProcessingState.running,
  'completed' => ProcessingState.completed,
  'failed' => ProcessingState.failed,
  'cancelled' => ProcessingState.cancelled,
  _ => ProcessingState.pending,
};

String runStatusToJson(RunStatus s) => switch (s) {
  RunStatus.running => 'running',
  RunStatus.completed => 'completed',
  RunStatus.cancelled => 'cancelled',
  RunStatus.failed => 'failed',
};

RunStatus runStatusFromJson(String? s) => switch (s) {
  'completed' => RunStatus.completed,
  'cancelled' => RunStatus.cancelled,
  'failed' => RunStatus.failed,
  _ => RunStatus.running,
};
