import 'package:flutter/material.dart';

import '../models/citation.dart';

/// Panel tiến độ + hủy + lỗi thử lại (plan §7).
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_phaseLabel(progress.phase)}${progress.total > 0 ? ' • Bước ${progress.done}/${progress.total}' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress.total == 0 ? null : progress.fraction,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              ElevatedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.stop),
                label: const Text('Hủy'),
              ),
          ],
        ),
      ),
    );
  }
}

String _phaseLabel(String phase) => switch (phase) {
      'importing' => 'Đang chọn PDF',
      'uploading' => 'Đang upload PDF',
      'uploaded' => 'Đã upload',
      'analyzing' => 'Đang phân tích',
      'building_report' => 'Đang nhận kết quả',
      'done' => 'Hoàn tất',
      'cancelling' => 'Đang hủy',
      'cancelled' => 'Đã hủy',
      _ => 'Đang xử lý',
    };
