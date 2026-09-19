import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> openAdminMode(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  if (!store.stats.isAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminAccessDenied)),
    );
    return;
  }
  final unlocked = await showDialog<bool>(
    context: context,
    builder: (_) => const _AdminPinDialog(),
  );
  if (unlocked == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminDashboardScreen(),
      ),
    );
  }
}

class _AdminPinDialog extends StatefulWidget {
  const _AdminPinDialog();

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim() == AppConstants.adminPin) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = AppLocalizations.of(context).adminPinWrong);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminPinTitle),
      content: TextField(
        key: const Key('admin-pin-field'),
        controller: _controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        autofocus: true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: l10n.adminPinHint,
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.metalCardDialogClose),
        ),
        FilledButton(
          key: const Key('admin-pin-submit'),
          onPressed: _submit,
          child: Text(l10n.adminPinConfirm),
        ),
      ],
    );
  }
}
