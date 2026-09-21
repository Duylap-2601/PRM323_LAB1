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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0B101E),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
              ),
              child: AppBar(
                toolbarHeight: 52,
                backgroundColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 16,
                title: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF162238),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF243657)),
                      ),
                      child: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF60A5FA)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'PDF Citation Audit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: Color(0xFFF8FAFC)),
                    ),
                    const SizedBox(width: 10),
                    const _HeaderLabel('PDF → EVIDENCE'),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF062319),
                      border: Border.all(color: const Color(0xFF0D533A)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Color(0x9934D399), blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'FastAPI server',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF86EFAC)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Cài đặt LLM',
                    onPressed: c.busy ? null : () => _settings(context),
                    icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _ImportBar(controller: c),
                if (c.busy || c.progress.phase == 'uploaded') ...[
                  const SizedBox(height: 8),
                  ProgressPanel(progress: c.progress, busy: c.busy, onCancel: c.cancel),
                ],
                if (c.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(message: c.errorMessage!),
                ],
                if (c.uiLogs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _LogPanel(logs: c.uiLogs),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: c.workingItems.isEmpty
                      ? const _EmptyWorkspace()
                      : AuditResultsScreen(controller: c),
                ),
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
  Widget build(BuildContext context) {
    final hasSource = controller.sourceLabel.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1626),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF202E46)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hasSource ? const Color(0xFF1E2D4A) : const Color(0xFF141C2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: hasSource ? const Color(0xFF3B82F6) : const Color(0xFF223048)),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 18,
              color: hasSource ? const Color(0xFF60A5FA) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasSource ? 'Tài liệu đã chọn:' : 'Tài liệu PDF nguồn:',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.4),
                ),
                const SizedBox(height: 1),
                Text(
                  hasSource ? controller.sourceLabel : 'Chọn một tài liệu PDF để bắt đầu.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: hasSource ? FontWeight.w600 : FontWeight.w400,
                    color: hasSource ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: controller.busy ? null : controller.importPickedFile,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: const Color(0xFFE2E8F0),
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.folder_open_rounded, size: 15),
            label: const Text('Import PDF'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: controller.readyToAnalyze ? controller.startAnalysis : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Bắt đầu phân tích'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF0D1424),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF1E2B42)),
    ),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF131F37),
                border: Border.all(color: const Color(0xFF233659), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332563EB),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_stories_outlined, size: 28, color: Color(0xFF60A5FA)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kiểm tra tài liệu tham khảo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC), letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Import PDF trước, sau đó bấm Bắt đầu phân tích để chạy trên server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _FeaturePill(icon: Icons.search_rounded, text: 'Trích xuất tự động'),
                const SizedBox(width: 8),
                _FeaturePill(icon: Icons.verified_outlined, text: 'Đối soát Crossref'),
                const SizedBox(width: 8),
                _FeaturePill(icon: Icons.auto_awesome, text: 'Đánh giá AI'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF131D31),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF24324D)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF93C5FD)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF131D31),
      border: Border.all(color: const Color(0xFF24324D)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF93C5FD)),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF2D1216),
      border: Border.all(color: const Color(0xFF7F1D1D)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFF87171)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, color: Color(0xFFFECACA), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _LogPanel extends StatelessWidget {
  final List<String> logs;
  const _LogPanel({required this.logs});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF1E2B42)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Material(
      color: const Color(0xFF0B101E),
      borderRadius: BorderRadius.circular(8),
      child: ExpansionTile(
        dense: true,
        iconColor: const Color(0xFF94A3B8),
        collapsedIconColor: const Color(0xFF64748B),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Row(
          children: [
            const Icon(Icons.terminal_rounded, size: 15, color: Color(0xFF60A5FA)),
            const SizedBox(width: 8),
            const Text('Log xử lý', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${logs.length}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
            ),
          ],
        ),
        subtitle: Text(
          logs.last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Color(0xFF070B14),
              border: Border(top: BorderSide(color: Color(0xFF162238))),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              children: [
                for (final log in logs.reversed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      log,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFCBD5E1), height: 1.4),
                    ),
                  ),
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

    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF090D16),
        border: Border(top: BorderSide(color: Color(0xFF1A253A))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: s == null
          ? const Row(
              children: [
                Icon(Icons.radio_button_checked, size: 10, color: Color(0xFF38BDF8)),
                SizedBox(width: 8),
                Text('Sẵn sàng import PDF', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            )
          : Row(
              children: [
                _StatusBadge(label: 'Tổng', count: s['total'] ?? 0, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                _StatusBadge(label: 'Đã xác minh', count: s['verified'] ?? 0, color: const Color(0xFF34D399)),
                const SizedBox(width: 8),
                _StatusBadge(label: 'Sai lệch', count: s['mismatch'] ?? 0, color: const Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                _StatusBadge(label: 'Cần xem lại', count: s['needs_review'] ?? 0, color: const Color(0xFFC084FC)),
              ],
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final dynamic count;
  final Color color;

  const _StatusBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text('$count $label', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, fontFamily: 'monospace')),
      ],
    ),
  );
}
