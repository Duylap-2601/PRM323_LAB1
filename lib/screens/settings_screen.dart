import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/audit_controller.dart';

/// Hộp thoại thông tin kết nối máy chủ FastAPI (High-End Design).
class SettingsScreen extends StatelessWidget {
  final AuditController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final serverUrl = controller.backend.baseUri.toString();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B101E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF24324D)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF162238),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF243657)),
                ),
                child: const Icon(Icons.dns_outlined, size: 20, color: Color(0xFF60A5FA)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D31),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF24324D)),
                    ),
                    child: const Text(
                      'BACKEND ENDPOINT',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Máy chủ xử lý',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                tooltip: 'Đóng',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Đường dẫn FastAPI API Base URL:',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C16),
              border: Border.all(color: const Color(0xFF24324D)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x8010B981), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    serverUrl,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFE2E8F0)),
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép đường dẫn',
                  icon: const Icon(Icons.content_copy, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: serverUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép Base URL vào Clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10192A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1D2C48)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF60A5FA)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PDF parsing, Crossref queries và khóa dịch vụ LLM được xử lý và quản lý tập trung trên FastAPI server. Flutter chỉ upload file PDF và nhận kết quả phân tích.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5),
                  ),
                ),
              ],
            ),
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
}
