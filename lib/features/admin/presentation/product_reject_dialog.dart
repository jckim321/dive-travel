import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Result of the shared admin reject dialog.
class ProductRejectResult {
  const ProductRejectResult({
    required this.note,
    this.reasonTags = const [],
  });

  final String note;
  final List<String> reasonTags;
}

/// Korean / l10n label for a reject-reason or section code.
String productRejectTagLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case ProductRejectTags.photos:
      return l10n.rejectTagPhotos;
    case ProductRejectTags.price:
      return l10n.rejectTagPrice;
    case ProductRejectTags.copy:
      return l10n.rejectTagCopy;
    case ProductRejectTags.schedule:
      return l10n.rejectTagSchedule;
    case ProductRejectTags.options:
      return l10n.rejectTagOptions;
    case ProductRejectTags.other:
      return l10n.rejectTagOther;
    case 'cancel':
      return l10n.rejectTagCancel;
    default:
      return code;
  }
}

/// Shared reject dialog: optional category chips + required note.
Future<ProductRejectResult?> showProductRejectDialog(BuildContext context) {
  return showDialog<ProductRejectResult>(
    context: context,
    builder: (_) => const ProductRejectDialog(),
  );
}

class ProductRejectDialog extends StatefulWidget {
  const ProductRejectDialog({super.key});

  @override
  State<ProductRejectDialog> createState() => _ProductRejectDialogState();
}

class _ProductRejectDialogState extends State<ProductRejectDialog> {
  final _note = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = _note.text.trim();
    return AlertDialog(
      title: Text(l10n.adminProductRejectNote),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminProductRejectTagsHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in ProductRejectTags.all)
                  FilterChip(
                    key: Key('reject-tag-$code'),
                    label: Text(productRejectTagLabel(l10n, code)),
                    selected: _selected.contains(code),
                    onSelected: (on) {
                      setState(() {
                        if (on) {
                          _selected.add(code);
                        } else {
                          _selected.remove(code);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.adminProductRejectNoteHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.adminHqClose),
        ),
        FilledButton(
          onPressed: note.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    ProductRejectResult(
                      note: note,
                      reasonTags: ProductPublishGuard.normalizeReasonTags(
                        _selected,
                      ),
                    ),
                  ),
          child: Text(l10n.adminReject),
        ),
      ],
    );
  }
}
