import 'package:flutter/material.dart';

import '../controllers/audit_controller.dart';

/// Danh sách lịch sử các báo cáo đã lưu (High-End Design System).
class HistoryScreen extends StatefulWidget {
  final AuditController controller;
  final VoidCallback? onOpened;
  const HistoryScreen({super.key, required this.controller, this.onOpened});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await widget.controller.history();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF131D31),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF24324D)),
              ),
              child: const Icon(Icons.history_rounded, size: 30, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có lịch sử',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Báo cáo sẽ xuất hiện tại đây sau khi lưu',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              const Icon(Icons.folder_copy_outlined, size: 16, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Text(
                'Lịch sử báo cáo (${_items.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9)),
              ),
              const Spacer(),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF94A3B8)),
                tooltip: 'Tải lại',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1E2B42)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final h = _items[i];
              final path = h['path'] ?? '';
              final source = h['source'] ?? path.split(RegExp(r'[/\\]')).last;
              final savedAt = h['saved_at'] ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1628),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2B42)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF162238),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2E4369)),
                    ),
                    child: const Icon(Icons.article_rounded, size: 18, color: Color(0xFF60A5FA)),
                  ),
                  title: Text(
                    source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
                  ),
                  subtitle: Text(
                    savedAt,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF94A3B8)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF64748B)),
                  onTap: widget.controller.busy
                      ? null
                      : () async {
                          await widget.controller.openHistory(path);
                          if (mounted && widget.controller.errorMessage == null) {
                            widget.onOpened?.call();
                          }
                        },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
