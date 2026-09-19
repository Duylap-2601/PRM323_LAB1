import 'package:flutter/material.dart';

import '../controllers/audit_controller.dart';

/// Configuration belongs to FastAPI; Flutter only displays the server URL.
class SettingsScreen extends StatelessWidget {
  final AuditController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Máy chủ xử lý', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF162032),
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            controller.backend.baseUri.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PDF parsing, Crossref và khóa dịch vụ được cấu hình trong FastAPI. Flutter chỉ upload PDF và hiển thị report từ server.',
          style: TextStyle(color: Color(0xFF94A3B8), height: 1.5),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ),
      ],
    ),
  );
}
