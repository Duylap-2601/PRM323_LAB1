import 'package:flutter/material.dart';

import '../controllers/audit_controller.dart';

/// History: card-based list of saved reports.
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Chua co lich su',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Bao cao se xuat hien tai day sau khi luu',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Text(
                'Lich su (${_items.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Tai lai',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final h = _items[i];
              final path = h['path'] ?? '';
              final source = h['source'] ?? path.split(RegExp(r'[/\\]')).last;
              final savedAt = h['saved_at'] ?? '';
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.description, size: 20),
                  ),
                  title: Text(
                    source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    savedAt,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.controller.busy
                      ? null
                      : () async {
                          await widget.controller.openHistory(path);
                          if (mounted &&
                              widget.controller.errorMessage == null) {
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
