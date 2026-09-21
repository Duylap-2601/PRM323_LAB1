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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    // Auto select first item if none selected and items not empty
    if (selected == null && items.isNotEmpty) {
      current = items.first;
      selected = items.first.index;
    }

    return LayoutBuilder(builder: (context, size) {
      final narrow = size.maxWidth < 850;
      final list = _CitationList(
        items: items,
        totalCount: c.workingItems.length,
        selected: selected,
        filter: filter,
        query: query,
        searchController: _searchController,
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
      return Row(children: [
        Expanded(flex: 5, child: list),
        const SizedBox(width: 14),
        Expanded(flex: 6, child: detail),
      ]);
    });
  }
}

class _CitationList extends StatelessWidget {
  final List<AuditResultItem> items;
  final int totalCount;
  final int? selected;
  final String filter;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onFilter;
  final ValueChanged<String> onQuery;
  final VoidCallback? onReanalyzeAll;

  const _CitationList({
    required this.items,
    required this.totalCount,
    required this.selected,
    required this.filter,
    required this.query,
    required this.searchController,
    required this.onSelect,
    required this.onFilter,
    required this.onQuery,
    this.onReanalyzeAll,
  });

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        _PanelHeader(
          title: 'Danh sách trích dẫn',
          count: items.length,
          totalCount: totalCount,
          action: onReanalyzeAll != null
              ? Tooltip(
                  message: 'Dùng LLM phân tích lại tất cả mục cần xem lại',
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onReanalyzeAll,
                    icon: const Icon(Icons.auto_awesome, size: 13),
                    label: const Text('Phân tích LLM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                )
              : null,
        ),
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: onQuery,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 15, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            searchController.clear();
                            onQuery('');
                          },
                        )
                      : null,
                  hintText: 'Lọc title, tác giả…',
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'Tất cả', value: 'all', current: filter, onSelect: onFilter),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Đã xác minh', value: 'verified', current: filter, color: const Color(0xFF34D399), onSelect: onFilter),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Sai lệch', value: 'mismatch', current: filter, color: const Color(0xFFFBBF24), onSelect: onFilter),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Cần xem lại', value: 'needs_review', current: filter, color: const Color(0xFFC084FC), onSelect: onFilter),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Lỗi', value: 'error', current: filter, color: const Color(0xFFF87171), onSelect: onFilter),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1E2B42)),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list_off_rounded, size: 36, color: Color(0xFF475569)),
                      const SizedBox(height: 10),
                      const Text(
                        'Không có citation phù hợp.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                      if (query.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            searchController.clear();
                            onQuery('');
                          },
                          child: const Text('Xóa bộ lọc tìm kiếm', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _CitationTile(
                    item: items[i],
                    active: selected == items[i].index,
                    onTap: () => onSelect(items[i].index),
                  ),
                ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Color? color;
  final ValueChanged<String> onSelect;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    final baseColor = color ?? const Color(0xFF3B82F6);

    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? baseColor.withValues(alpha: 0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? baseColor : const Color(0xFF1E2B42),
            width: active ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? (color ?? const Color(0xFF93C5FD)) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _CitationTile extends StatelessWidget {
  final AuditResultItem item;
  final bool active;
  final VoidCallback onTap;
  const _CitationTile({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = verificationStatusToJson(item.status) ??
        (item.processingState == ProcessingState.running ? 'running' : 'pending');
    final color = _statusColor(status);

    return Material(
      color: active ? const Color(0xFF142036) : const Color(0xFF0E1628),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0x1A3B82F6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? const Color(0xFF3B82F6) : const Color(0xFF1E2B42),
              width: active ? 1.2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1E3A8A) : const Color(0xFF131D31),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: active ? const Color(0xFF3B82F6) : const Color(0xFF24324D)),
                ),
                child: Text(
                  '[${(item.index + 1).toString().padLeft(2, '0')}]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: active ? Colors.white : const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.metadata.title ?? item.citation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF1F5F9),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.metadata.authors ?? 'Chưa đọc được tác giả'} · ${item.metadata.year ?? 'không rõ năm'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ),
                        if (item.extraction.sourcePages.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF162032),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'tr.${item.extraction.sourcePages.join(',')}',
                              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(status: status, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final AuditResultItem? item;
  final bool showJson;
  final String? reportJson;
  final ValueChanged<bool> onTabChanged;
  final Future<void> Function()? onSave;
  final Future<void> Function(AuditResultItem item)? onReanalyzeLlm;

  const _DetailPanel({
    required this.item,
    required this.showJson,
    required this.reportJson,
    required this.onTabChanged,
    required this.onSave,
    this.onReanalyzeLlm,
  });

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF0B101E),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: Color(0xFF1E2B42))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF101726),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1E2B42)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TabButton(
                      label: 'Chi tiết bằng chứng',
                      icon: Icons.article_outlined,
                      active: !showJson,
                      onTap: () => onTabChanged(false),
                    ),
                    _TabButton(
                      label: 'Báo cáo JSON',
                      icon: Icons.data_object_rounded,
                      active: showJson,
                      onTap: () => onTabChanged(true),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (showJson && reportJson != null) ...[
                IconButton(
                  tooltip: 'Sao chép JSON',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: reportJson!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép nội dung JSON'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.content_copy, size: 16, color: Color(0xFF94A3B8)),
                ),
                if (onSave != null)
                  IconButton(
                    tooltip: 'Lưu JSON ra file',
                    onPressed: onSave,
                    icon: const Icon(Icons.save_alt_rounded, size: 17, color: Color(0xFF60A5FA)),
                  ),
              ],
            ],
          ),
        ),
        Expanded(
          child: showJson
              ? _JsonView(json: reportJson)
              : EvidencePanel(item: item, onReanalyzeLlm: onReanalyzeLlm),
        ),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? Colors.white : const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ),
  );
}

class _JsonView extends StatelessWidget {
  final String? json;
  const _JsonView({required this.json});

  @override
  Widget build(BuildContext context) => json == null
      ? const Center(
          child: Text(
            'JSON xuất hiện khi lượt xử lý hoàn tất.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        )
      : Container(
          color: const Color(0xFF070B14),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              json!,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                fontFamily: 'monospace',
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        );
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0C1322),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF1E2B42)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final int count;
  final int totalCount;
  final Widget? action;

  const _PanelHeader({
    required this.title,
    required this.count,
    required this.totalCount,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: const BoxDecoration(
      color: Color(0xFF0B101E),
      border: Border(bottom: BorderSide(color: Color(0xFF1E2B42))),
    ),
    child: Row(
      children: [
        const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF60A5FA)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF162238),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF243657)),
          ),
          child: Text(
            '$count mục',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF93C5FD), fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null) ...[const Spacer(), action!],
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.45)),
      borderRadius: BorderRadius.circular(5),
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
        Text(
          _statusLabel(status),
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

Color _statusColor(String status) => switch (status) {
      'verified' => const Color(0xFF34D399),
      'mismatch' => const Color(0xFFFBBF24),
      'error' => const Color(0xFFF87171),
      'needs_review' => const Color(0xFFC084FC),
      'running' => const Color(0xFF60A5FA),
      _ => const Color(0xFF94A3B8),
    };

String _statusLabel(String status) => switch (status) {
      'verified' => 'Đã xác minh',
      'mismatch' => 'Sai lệch',
      'needs_review' => 'Cần xem lại',
      'not_found' => 'Không tìm thấy',
      'error' => 'Lỗi',
      'running' => 'Đang xác minh',
      'pending' => 'Đang chờ',
      _ => status,
    };
