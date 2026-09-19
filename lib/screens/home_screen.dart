import 'package:flutter/material.dart';

import '../controllers/audit_controller.dart';
import '../widgets/progress_panel.dart';
import 'audit_results_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuditController controller;
  const HomeScreen({super.key, required this.controller});

  Future<void> _settings(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: SizedBox(
        width: 620,
        height: 680,
        child: SettingsScreen(controller: controller),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 52,
            backgroundColor: const Color(0xFF1E293B),
            titleSpacing: 20,
            title: const Row(
              children: [
                Icon(Icons.description_outlined, size: 20),
                SizedBox(width: 10),
                Text('PDF Citation Audit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(width: 10),
                _HeaderLabel('PDF → evidence'),
              ],
            ),
            actions: [
              Text(
                'FastAPI server',
                style: const TextStyle(fontSize: 11, color: Color(0xFF86EFAC)),
              ),
              IconButton(
                tooltip: 'Cài đặt LLM',
                onPressed: c.busy ? null : () => _settings(context),
                icon: const Icon(Icons.settings_outlined, size: 19),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ImportBar(controller: c),
                if (c.busy || c.progress.phase == 'uploaded') ...[
                  const SizedBox(height: 10),
                  ProgressPanel(progress: c.progress, busy: c.busy, onCancel: c.cancel),
                ],
                if (c.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: c.errorMessage!),
                ],
                if (c.uiLogs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _LogPanel(logs: c.uiLogs),
                ],
                const SizedBox(height: 12),
                Expanded(child: c.workingItems.isEmpty ? const _EmptyWorkspace() : AuditResultsScreen(controller: c)),
              ],
            ),
          ),
          bottomNavigationBar: _StatusBar(controller: c),
        );
      },
    );
  }
}

class _ImportBar extends StatelessWidget {
  final AuditController controller;
  const _ImportBar({required this.controller});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF334155))),
    child: Row(children: [
      const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF94A3B8)),
      const SizedBox(width: 10),
      Expanded(child: Text(controller.sourceLabel.isEmpty ? 'Chọn một tài liệu PDF để bắt đầu.' : controller.sourceLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
      const SizedBox(width: 10),
      FilledButton.icon(onPressed: controller.busy ? null : controller.importPickedFile, icon: const Icon(Icons.folder_open, size: 17), label: const Text('Import PDF')),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: controller.readyToAnalyze ? controller.startAnalysis : null,
        icon: const Icon(Icons.play_arrow, size: 17),
        label: const Text('Bắt đầu phân tích'),
      ),
    ]),
  );
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF334155))),
    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.find_in_page_outlined, size: 48, color: Color(0xFF64748B)),
      SizedBox(height: 14),
      Text('Kiểm tra tài liệu tham khảo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      SizedBox(height: 6),
      Text('Import PDF trước, sau đó bấm Bắt đầu phân tích để chạy trên server.', style: TextStyle(color: Color(0xFF94A3B8))),
    ]),
  );
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: const Color(0xFF162032), border: Border.all(color: const Color(0xFF334155)), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFF7F1D1D), border: Border.all(color: const Color(0xFFF87171)), borderRadius: BorderRadius.circular(6)),
    child: Text(message, style: const TextStyle(fontSize: 12)),
  );
}

class _LogPanel extends StatelessWidget {
  final List<String> logs;
  const _LogPanel({required this.logs});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF334155)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Material(
      color: const Color(0xFF162032),
      borderRadius: BorderRadius.circular(6),
      child: ExpansionTile(
        dense: true,
        title: const Text('Log xử lý', style: TextStyle(fontSize: 12)),
        subtitle: Text(logs.last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF94A3B8))),
        children: [
          SizedBox(
            height: 150,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final log in logs.reversed)
                  SelectableText(log, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFFCBD5E1))),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusBar extends StatelessWidget {
  final AuditController controller;
  const _StatusBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    final s = controller.report?.summary;
    return Container(height: 28, color: const Color(0xFF1E293B), padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
      child: Text(s == null ? 'Sẵn sàng import PDF' : '${s['total']} mục · ${s['verified']} đã xác minh · ${s['mismatch']} sai lệch · ${s['needs_review']} cần xem lại', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
    );
  }
}
