import 'package:flutter/material.dart';

import '../models/audit_result_item.dart';

/// Panel chi tiết metadata + bằng chứng truy vết (plan §7).
class EvidencePanel extends StatelessWidget {
  final AuditResultItem? item;
  const EvidencePanel({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    final it = item;
    if (it == null) return const Center(child: Text('Chọn một citation.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Raw', style: Theme.of(context).textTheme.titleSmall),
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
              subtitle: Text(e.url ?? 'không có URL'),
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
