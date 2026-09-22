abstract final class AppMessages {
  static const sourceLinkOpenFailed = 'Không thể mở liên kết nguồn.';
  static const sourceUrlMissing = 'Không có URL nguồn';
  static const reviewReasonPrefix = 'Cần xem lại vì:';

  static const validationStatus = <String, String>{
    'VALID': 'Thông tin khớp với nguồn học thuật.',
    'MISMATCH': 'Thông tin khác với nguồn học thuật.',
    'NOT_FOUND': 'Không tìm thấy nguồn học thuật phù hợp.',
    'PARTIAL': 'Bằng chứng chưa đủ để xác minh hoàn toàn.',
    'AMBIGUOUS': 'Có nhiều nguồn gần khớp, cần xem lại.',
  };

  static String validationStatusMessage(String status) =>
      validationStatus[status] ?? 'Máy chủ chưa trả kết luận.';
}
