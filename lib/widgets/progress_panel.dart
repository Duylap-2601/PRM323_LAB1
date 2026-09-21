import 'package:flutter/material.dart';

import '../models/citation.dart';

/// Panel tiến độ + hủy + trạng thái bước xử lý (High-End Design System).
class ProgressPanel extends StatelessWidget {
  final AuditProgress progress;
  final bool busy;
  final VoidCallback onCancel;

  const ProgressPanel({
    super.key,
    required this.progress,
    required this.busy,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final hasTotal = progress.total > 0;
    final percent = hasTotal ? (progress.fraction * 100).toInt() : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11192C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF24324D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1D283A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2E4061)),
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF60A5FA),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF34D399)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        _phaseLabel(progress.phase).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                    if (hasTotal) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Bước ${progress.done}/${progress.total} ($percent%)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: hasTotal ? progress.fraction : null,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  progress.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          if (busy) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFCA5A5),
                side: const BorderSide(color: Color(0xFF7F1D1D)),
                backgroundColor: const Color(0x33450A0A),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.stop_circle_outlined, size: 14),
              label: const Text('Hủy'),
            ),
          ],
        ],
      ),
    );
  }
}

String _phaseLabel(String phase) => switch (phase) {
      'importing' => 'Đang chọn PDF',
      'uploading' => 'Đang tải lên',
      'uploaded' => 'Đã tải lên',
      'analyzing' => 'Đang phân tích',
      'building_report' => 'Đang nhận kết quả',
      'done' => 'Hoàn tất',
      'cancelling' => 'Đang hủy',
      'cancelled' => 'Đã hủy',
      _ => 'Đang xử lý',
    };
