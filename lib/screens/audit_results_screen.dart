import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/audit_controller.dart';
import '../models/audit_result_item.dart';
import '../models/enums.dart';
import '../widgets/evidence_panel.dart';

class AuditResultsScreen extends StatefulWidget {
  final AuditController controller;
  const AuditResultsScreen({super.key, required this.controller});
  @override
  State<AuditResultsScreen> createState() => _AuditResultsScreenState();
}

class _AuditResultsScreenState extends State<AuditResultsScreen> {
  String query = '';
  String filter = 'all';
  int? selected;
  bool showJson = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final items = c.workingItems.where((item) {
      final matchesStatus = filter == 'all' || verificationStatusToJson(item.status) == filter;
      final haystack = '${item.citation} ${item.metadata.title ?? ''} ${item.metadata.authors ?? ''}'.toLowerCase();
      return matchesStatus && haystack.contains(query.toLowerCase());
    }).toList();
    AuditResultItem? current;
    for (final item in c.workingItems) {
      if (item.index == selected) {
        current = item;
        break;
      }
    }
    return LayoutBuilder(builder: (context, size) {
      final narrow = size.maxWidth < 850;
      final list = _CitationList(
        items: items,
        selected: selected,
        filter: filter,
        query: query,
        onSelect: (index) => setState(() => selected = index),
        onFilter: (value) => setState(() => filter = value),
        onQuery: (value) => setState(() => query = value),
        onReanalyzeAll: c.busy ? null : () => c.reanalyzeAllNeedsReviewWithLlm(),
      );
      final detail = _DetailPanel(
        item: current,
        showJson: showJson,
        reportJson: c.report == null
            ? null
            : const JsonEncoder.withIndent('  ').convert(c.report!.toLegacyJson()),
        onTabChanged: (json) => setState(() => showJson = json),
        onSave: c.report == null
            ? null
            : () async {
                await c.exporter.exportLegacy(c.report!);
              },
        onReanalyzeLlm: (item) => c.reanalyzeItemWithLlm(item),
      );
      if (narrow) return list;
      return Row(children: [Expanded(child: list), const SizedBox(width: 12), Expanded(child: detail)]);
    });
  }
}

class _CitationList extends StatelessWidget {
  final List<AuditResultItem> items;
  final int? selected;
  final String filter;
  final String query;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onFilter;
  final ValueChanged<String> onQuery;
  final VoidCallback? onReanalyzeAll;
  const _CitationList({
    required this.items,
    required this.selected,
    required this.filter,
    required this.query,
    required this.onSelect,
    required this.onFilter,
    required this.onQuery,
    this.onReanalyzeAll,
  });
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(children: [
      _PanelHeader(
        title: 'Danh sách trích dẫn',
        count: items.length,
        action: onReanalyzeAll != null
            ? Tooltip(
                message: 'Dùng LLM phân tích lại tất cả mục cần xem lại',
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC4B5FD),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: onReanalyzeAll,
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text('Phân tích LLM', style: TextStyle(fontSize: 11)),
                ),
              )
            : null,
      ),
      Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(onChanged: onQuery, decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Lọc title, tác giả…', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        DropdownButton<String>(value: filter, underline: const SizedBox(), items: const [
          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
          DropdownMenuItem(value: 'verified', child: Text('Đã xác minh')),
          DropdownMenuItem(value: 'mismatch', child: Text('Sai lệch')),
          DropdownMenuItem(value: 'needs_review', child: Text('Cần xem lại')),
          DropdownMenuItem(value: 'error', child: Text('Lỗi')),
        ], onChanged: (value) { if (value != null) onFilter(value); }),
      ])),
      const Divider(height: 1),
      Expanded(child: items.isEmpty ? const Center(child: Text('Không có citation phù hợp.')) : ListView.separated(
        padding: const EdgeInsets.all(8), itemCount: items.length, separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) => _CitationTile(item: items[i], active: selected == items[i].index, onTap: () => onSelect(items[i].index)),
      )),
    ]),
  );
}

class _CitationTile extends StatelessWidget {
  final AuditResultItem item;
  final bool active;
  final VoidCallback onTap;
  const _CitationTile({required this.item, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final status = verificationStatusToJson(item.status) ?? (item.processingState == ProcessingState.running ? 'running' : 'pending');
    final color = _statusColor(status);
    return Material(color: active ? const Color(0xFF26354A) : const Color(0xFF162032), borderRadius: BorderRadius.circular(5), child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(5), child: Container(
        padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: active ? const Color(0xFF64748B) : const Color(0xFF334155)), borderRadius: BorderRadius.circular(5)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('[${item.index + 1}]', style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF60A5FA), fontWeight: FontWeight.w600)),
          const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.metadata.title ?? item.citation, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5), Text('${item.metadata.authors ?? 'Chưa đọc được tác giả'} · ${item.metadata.year ?? 'không rõ năm'} · tr.${item.extraction.sourcePages.join(',')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ])), const SizedBox(width: 8), _StatusChip(status: status, color: color),
        ]),
      ),
    ));
  }
}

class _DetailPanel extends StatelessWidget {
  final AuditResultItem? item;
  final bool showJson;
  final String? reportJson;
  final ValueChanged<bool> onTabChanged;
  final Future<void> Function()? onSave;
  final Future<void> Function(AuditResultItem item)? onReanalyzeLlm;
  const _DetailPanel({required this.item, required this.showJson, required this.reportJson, required this.onTabChanged, required this.onSave, this.onReanalyzeLlm});
  @override
  Widget build(BuildContext context) => _Panel(child: Column(children: [
    Row(children: [
      Expanded(child: _Tab(label: 'Chi tiết', active: !showJson, onTap: () => onTabChanged(false))),
      Expanded(child: _Tab(label: 'JSON', active: showJson, onTap: () => onTabChanged(true))),
      if (showJson && reportJson != null) IconButton(tooltip: 'Sao chép JSON', onPressed: () => Clipboard.setData(ClipboardData(text: reportJson!)), icon: const Icon(Icons.content_copy, size: 18)),
      if (showJson && onSave != null) IconButton(tooltip: 'Lưu JSON', onPressed: onSave, icon: const Icon(Icons.save_alt, size: 18)),
    ]), const Divider(height: 1),
    Expanded(child: showJson ? _JsonView(json: reportJson) : EvidencePanel(item: item, onReanalyzeLlm: onReanalyzeLlm)),
  ]));
}

class _JsonView extends StatelessWidget {
  final String? json;
  const _JsonView({required this.json});
  @override
  Widget build(BuildContext context) => json == null ? const Center(child: Text('JSON xuất hiện khi lượt xử lý hoàn tất.')) : SingleChildScrollView(padding: const EdgeInsets.all(12), child: SelectableText(json!, style: const TextStyle(fontSize: 11, height: 1.5, fontFamily: 'monospace', color: Color(0xFFCBD5E1))));
}

class _Panel extends StatelessWidget { final Widget child; const _Panel({required this.child}); @override Widget build(BuildContext context) => Material(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6), child: Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFF334155)), borderRadius: BorderRadius.circular(6)), child: child)); }
class _PanelHeader extends StatelessWidget {
  final String title;
  final int count;
  final Widget? action;
  const _PanelHeader({required this.title, required this.count, this.action});
  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.centerLeft,
    color: const Color(0xFF162032),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      _StatusChip(status: '$count mục', color: const Color(0xFF94A3B8)),
      if (action != null) ...[const Spacer(), action!],
    ]),
  );
}
class _Tab extends StatelessWidget { final String label; final bool active; final VoidCallback onTap; const _Tab({required this.label, required this.active, required this.onTap}); @override Widget build(BuildContext context) => TextButton(onPressed: onTap, style: TextButton.styleFrom(foregroundColor: active ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8)), child: Text(label)); }
class _StatusChip extends StatelessWidget { final String status; final Color color; const _StatusChip({required this.status, required this.color}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .12), border: Border.all(color: color.withValues(alpha: .45)), borderRadius: BorderRadius.circular(4)), child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))); }
Color _statusColor(String status) => switch (status) { 'verified' => const Color(0xFF4ADE80), 'mismatch' => const Color(0xFFFBBF24), 'error' => const Color(0xFFF87171), 'needs_review' => const Color(0xFFC4B5FD), 'running' => const Color(0xFF60A5FA), _ => const Color(0xFF94A3B8) };
String _statusLabel(String status) => switch (status) { 'verified' => 'Đã xác minh', 'mismatch' => 'Sai lệch', 'needs_review' => 'Cần xem lại', 'not_found' => 'Không tìm thấy', 'error' => 'Lỗi', 'running' => 'Đang xác minh', 'pending' => 'Đang chờ', _ => status };
