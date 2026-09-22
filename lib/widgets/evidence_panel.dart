import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_messages.dart';
import '../models/audit_result_item.dart';
import '../models/enums.dart';

/// Panel chi tiết metadata + bằng chứng truy vết theo phong cách Bento Grid (High-End Design System).
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
    if (it == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF131D31),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF24324D)),
              ),
              child: const Icon(
                Icons.touch_app_outlined,
                size: 28,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chọn một citation bên trái để xem bằng chứng',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final statusStr =
        verificationStatusToJson(it.status) ??
        (it.processingState == ProcessingState.running ? 'running' : 'pending');
    final statusColor = _statusColor(statusStr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Card với số thứ tự và nút LLM
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1628),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF22314E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162238),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFF2E4369)),
                      ),
                      child: Text(
                        'CITATION #${it.index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF93C5FD),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: statusStr, color: statusColor),
                    const Spacer(),
                    if (widget.onReanalyzeLlm != null)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6D28D9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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
                                      SnackBar(
                                        content: Text(
                                          'Phân tích LLM thất bại: $e',
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                        icon: _loading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 14),
                        label: Text(
                          _loading ? 'Đang phân tích…' : 'Phân tích lại LLM',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  it.metadata.title ?? it.citation,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF8FAFC),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                // Raw Citation Block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1E2B42)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          it.metadata.raw,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Color(0xFFCBD5E1),
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sao chép raw citation',
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: it.metadata.raw),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép chuỗi trích dẫn'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Metadata Grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1628),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF22314E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.info_outline,
                  title: 'Thông tin trích xuất (Metadata)',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _MetaItem(
                      label: 'Tác giả',
                      value: it.metadata.authors ?? 'Chưa xác định',
                    ),
                    _MetaItem(
                      label: 'Năm xuất bản',
                      value: it.metadata.year ?? '—',
                    ),
                    _MetaItem(
                      label: 'DOI',
                      value: it.metadata.doi ?? 'Không có',
                    ),
                    _MetaItem(
                      label: 'Trang nguồn',
                      value: it.extraction.sourcePages.isEmpty
                          ? '—'
                          : 'Trang ${it.extraction.sourcePages.join(', ')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Status Callout & Reason
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'Đánh giá đối soát: ${_statusLabel(statusStr)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  it.reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),
                if (it.extraction.warnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Color(0x22FFFFFF), height: 1),
                  const SizedBox(height: 8),
                  const Text(
                    'Cảnh báo trích xuất:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final w in it.extraction.warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: Color(0xFFFBBF24)),
                          ),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFFDE68A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Evidence Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1628),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF22314E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _SectionTitle(
                      icon: Icons.find_in_page_outlined,
                      title: 'Nguồn chứng cứ đối chiếu',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${it.evidence.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (it.evidence.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Không có bằng chứng đối chiếu trực tiếp từ API.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  )
                else
                  for (int idx = 0; idx < it.evidence.length; idx++) ...[
                    if (idx > 0) const SizedBox(height: 10),
                    _EvidenceCard(evidence: it.evidence[idx]),
                  ],
              ],
            ),
          ),

          // 5. Query Attempts Section
          if (it.attempts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1628),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF22314E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _SectionTitle(
                        icon: Icons.history_rounded,
                        title: 'Lịch sử truy vấn API',
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${it.attempts.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final a in it.attempts)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E1A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1B273F)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2B42),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              a.provider.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF93C5FD),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.query,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kết quả: ${a.outcome}${a.errorCode != null ? ' (Mã: ${a.errorCode})' : ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        a.outcome.contains('found') ||
                                            a.outcome.contains('ok') ||
                                            a.outcome.contains('success')
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: const Color(0xFF60A5FA)),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF1F5F9),
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF080D18),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF1B273F)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFF1F5F9),
          ),
        ),
      ],
    ),
  );
}

class _EvidenceCard extends StatelessWidget {
  final dynamic evidence;
  const _EvidenceCard({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final e = evidence;
    final url = e.url as String?;
    final snippet = e.snippet as String?;
    final meta = e.metadata as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF080D18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2B42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF162238),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2E4369)),
                ),
                child: Text(
                  '${e.provider}'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF93C5FD),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${e.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (url != null && url.isNotEmpty)
                IconButton(
                  tooltip: 'Mở nguồn',
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 17,
                    color: Color(0xFF60A5FA),
                  ),
                  onPressed: () async {
                    final uri = Uri.tryParse(url);
                    if (uri == null ||
                        !await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppMessages.sourceLinkOpenFailed),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          if (meta['title'] != null) ...[
            const SizedBox(height: 6),
            Text(
              meta['title'].toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF1F5F9),
              ),
            ),
          ],
          if (url != null && url.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.link, size: 13, color: Color(0xFF60A5FA)),
                const SizedBox(width: 6),
                Expanded(
                  child: SelectableText(
                    url,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF60A5FA),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (meta['review_reason'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '${AppMessages.reviewReasonPrefix} ${meta['review_reason']}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFBBF24),
                height: 1.35,
              ),
            ),
          ],
          if (snippet != null && snippet.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF050810),
                borderRadius: BorderRadius.all(Radius.circular(4)),
                border: Border(
                  left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                ),
              ),
              child: Text(
                snippet,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFCBD5E1),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (meta['status'] != null)
                  _TagPill(label: 'status', value: '${meta['status']}'),
                if (meta['confidence'] != null)
                  _TagPill(label: 'confidence', value: '${meta['confidence']}'),
                if (meta['title_score'] != null)
                  _TagPill(
                    label: 'title_score',
                    value: '${meta['title_score']}',
                  ),
                if (meta['conclusion'] != null)
                  _TagPill(label: 'conclusion', value: '${meta['conclusion']}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final String value;
  const _TagPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF131D31),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFF24324D)),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(
        fontSize: 10,
        fontFamily: 'monospace',
        color: Color(0xFF93C5FD),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.45)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      _statusLabel(status),
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
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
