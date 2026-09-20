import 'package:flutter/material.dart';

import '../models/audit_result_item.dart';

/// Panel chi tiết metadata + bằng chứng truy vết (plan §7).
class EvidencePanel extends StatefulWidget {
  final AuditResultItem? item;
  final Future<void> Function(AuditResultItem item)? onReanalyzeLlm;
  const EvidencePanel({super.key, this.item, this.onReanalyzeLlm});

  @override
  State<EvidencePanel> createState() => _EvidencePanelState();
}

class _EvidencePanelState extends State<EvidencePanel> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    if (it == null) return const Center(child: Text('Chọn một citation.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Raw', style: Theme.of(context).textTheme.titleSmall),
              if (widget.onReanalyzeLlm != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          try {
                            await widget.onReanalyzeLlm!(it);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Phân tích LLM thất bại: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  icon: _loading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_loading ? 'Đang phân tích...' : 'Dùng LLM phân tích lại', style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
          SelectableText(it.metadata.raw),
          const SizedBox(height: 8),
          Text(
            'Metadata: ${it.metadata.title ?? '—'} · ${it.metadata.authors ?? '—'} · '
            '${it.metadata.year ?? '—'} · DOI ${it.metadata.doi ?? '—'}',
          ),
          if (it.extraction.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Cảnh báo:', style: Theme.of(context).textTheme.titleSmall),
            for (final w in it.extraction.warnings) Text('• $w'),
          ],
          const SizedBox(height: 8),
          Text('Lý do: ${it.reason}'),
          const Divider(),
          Text(
            'Bằng chứng (${it.evidence.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final e in it.evidence)
            ListTile(
              dense: true,
              title: Text('${e.provider} · ${e.id}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.url ?? 'khong co URL'),
                  if (e.snippet != null && e.snippet!.isNotEmpty)
                    Text(e.snippet!),
                  if (e.metadata.isNotEmpty)
                    Text(
                      [
                        if (e.metadata['status'] != null)
                          "status=${e.metadata['status']}",
                        if (e.metadata['confidence'] != null)
                          "confidence=${e.metadata['confidence']}",
                        if (e.metadata['title_score'] != null)
                          "title=${e.metadata['title_score']}",
                        if (e.metadata['conclusion'] != null)
                          "conclusion=${e.metadata['conclusion']}",
                      ].join(' | '),
                    ),
                ],
              ),
            ),
          if (it.attempts.isNotEmpty) ...[
            const Divider(),
            Text(
              'Lần tra cứu (${it.attempts.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final a in it.attempts)
              Text(
                '• ${a.provider}: ${a.query} → ${a.outcome}${a.errorCode != null ? ' (${a.errorCode})' : ''}',
              ),
          ],
        ],
      ),
    );
  }
}

