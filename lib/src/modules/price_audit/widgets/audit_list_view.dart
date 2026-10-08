import 'package:flutter/material.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/core/theme/theme.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/widgets/failure_view.dart';

/// Saves a shelf price. Completes normally on success, throws a [Failure].
typedef RecordShelfPrice = Future<void> Function(
  String barcode,
  Price shelfPrice,
);

/// The entries of one aisle. Knows nothing about where they came from or how
/// they are saved, which is why both lessons can reuse it unchanged.
class AuditListView extends StatefulWidget {
  const AuditListView({
    super.key,
    required this.entries,
    required this.onRecord,
  });

  final List<AuditEntry> entries;
  final RecordShelfPrice onRecord;

  @override
  State<AuditListView> createState() => _AuditListViewState();
}

class _AuditListViewState extends State<AuditListView> {
  final _saving = <String>{};

  Future<void> _record(AuditEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final shelfPrice = await showDialog<Price>(
      context: context,
      builder: (context) => _ShelfPriceDialog(entry: entry),
    );
    if (shelfPrice == null || !mounted) return;

    setState(() => _saving.add(entry.barcode));
    try {
      await widget.onRecord(entry.barcode, shelfPrice);
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text('Not saved. ${failureMessage(failure)}')),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(entry.barcode));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        final saving = _saving.contains(entry.barcode);
        return ListTile(
          title: Text(entry.name),
          subtitle: Text(
            '${entry.barcode} · system ${entry.systemPrice.format()}',
          ),
          trailing: saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _StatusChip(status: entry.status),
          onTap: saving ? null : () => _record(entry),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AuditStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      Pending() => ('Not checked', colors.outline),
      Match() => ('Match', LabColors.of(context).success),
      Mismatch(:final difference) => (
        'Label ${difference.minorUnits > 0 ? '+' : ''}${difference.format()}',
        colors.error,
      ),
    };
    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ShelfPriceDialog extends StatefulWidget {
  const _ShelfPriceDialog({required this.entry});

  final AuditEntry entry;

  @override
  State<_ShelfPriceDialog> createState() => _ShelfPriceDialogState();
}

class _ShelfPriceDialogState extends State<_ShelfPriceDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final price = Price.tryParse(_controller.text);
    if (price == null) {
      setState(() => _invalid = true);
    } else {
      Navigator.of(context).pop(price);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return AlertDialog(
      title: Text(entry.name),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Price on the shelf label',
          hintText: entry.systemPrice.format(),
          errorText: _invalid ? 'Enter a price like 12.50' : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(entry.systemPrice),
          child: const Text('Same as system'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
