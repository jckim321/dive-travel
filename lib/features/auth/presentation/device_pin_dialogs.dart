import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Ask the user to create a 4-digit device PIN (enter + confirm).
Future<bool> showDevicePinSetupDialog(
  BuildContext context, {
  required String uid,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DevicePinSetupDialog(uid: uid),
  );
  return ok == true;
}

/// Ask for the existing device PIN.
Future<bool> showDevicePinUnlockDialog(
  BuildContext context, {
  required String uid,
  Future<void> Function()? onLockedOut,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DevicePinUnlockDialog(
      uid: uid,
      onLockedOut: onLockedOut,
    ),
  );
  return ok == true;
}

class _DevicePinSetupDialog extends StatefulWidget {
  const _DevicePinSetupDialog({required this.uid});

  final String uid;

  @override
  State<_DevicePinSetupDialog> createState() => _DevicePinSetupDialogState();
}

class _DevicePinSetupDialogState extends State<_DevicePinSetupDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final pin = _pin.text.trim();
    final confirm = _confirm.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = l10n.devicePinHint);
      return;
    }
    if (pin != confirm) {
      setState(() => _error = l10n.devicePinMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await DevicePinScope.of(context).setPin(
      uid: widget.uid,
      pin: pin,
    );
    if (!mounted) return;
    if (result != DevicePinVerify.ok) {
      setState(() {
        _busy = false;
        _error = l10n.devicePinHint;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.devicePinSetupTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.devicePinSetupBody),
          const SizedBox(height: 12),
          TextField(
            key: const Key('device-pin-set-field'),
            controller: _pin,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: l10n.devicePinHint,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('device-pin-confirm-field'),
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: l10n.devicePinConfirmHint,
              counterText: '',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (!_busy) _submit();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.metalCardDialogClose),
        ),
        FilledButton(
          key: const Key('device-pin-set-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.devicePinSave),
        ),
      ],
    );
  }
}

class _DevicePinUnlockDialog extends StatefulWidget {
  const _DevicePinUnlockDialog({
    required this.uid,
    this.onLockedOut,
  });

  final String uid;
  final Future<void> Function()? onLockedOut;

  @override
  State<_DevicePinUnlockDialog> createState() => _DevicePinUnlockDialogState();
}

class _DevicePinUnlockDialogState extends State<_DevicePinUnlockDialog> {
  final _controller = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final pins = DevicePinScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await pins.verify(
      uid: widget.uid,
      pin: _controller.text.trim(),
    );
    if (!mounted) return;
    switch (result) {
      case DevicePinVerify.ok:
        Navigator.of(context).pop(true);
        return;
      case DevicePinVerify.lockedOut:
        final onLockedOut = widget.onLockedOut;
        if (onLockedOut != null) {
          await onLockedOut();
        }
        if (!mounted) return;
        Navigator.of(context).pop(false);
        return;
      case DevicePinVerify.wrong:
        setState(() {
          _busy = false;
          _error = l10n.devicePinWrong(pins.maxFails - pins.fails);
        });
        return;
      case DevicePinVerify.missing:
      case DevicePinVerify.invalid:
        setState(() {
          _busy = false;
          _error = l10n.adminPinWrong;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.devicePinUnlockTitle),
      content: TextField(
        key: const Key('admin-pin-field'),
        controller: _controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        autofocus: true,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: l10n.devicePinHint,
          counterText: '',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          if (!_busy) _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.metalCardDialogClose),
        ),
        FilledButton(
          key: const Key('admin-pin-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.adminPinConfirm),
        ),
      ],
    );
  }
}

/// Full-screen unlock after cold start when a staff PIN is on this device.
class DevicePinUnlockPage extends StatefulWidget {
  const DevicePinUnlockPage({
    super.key,
    required this.uid,
    required this.onLockedOut,
  });

  final String uid;
  final Future<void> Function() onLockedOut;

  @override
  State<DevicePinUnlockPage> createState() => _DevicePinUnlockPageState();
}

class _DevicePinUnlockPageState extends State<DevicePinUnlockPage> {
  final _controller = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final pins = DevicePinScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await pins.verify(
      uid: widget.uid,
      pin: _controller.text.trim(),
    );
    if (!mounted) return;
    switch (result) {
      case DevicePinVerify.ok:
        setState(() => _busy = false);
        return;
      case DevicePinVerify.lockedOut:
        await widget.onLockedOut();
        return;
      case DevicePinVerify.wrong:
        setState(() {
          _busy = false;
          _controller.clear();
          _error = l10n.devicePinWrong(pins.maxFails - pins.fails);
        });
        return;
      case DevicePinVerify.missing:
      case DevicePinVerify.invalid:
        setState(() {
          _busy = false;
          _error = l10n.adminPinWrong;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('device-pin-unlock-page'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.devicePinUnlockTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.devicePinUnlockBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('device-pin-unlock-field'),
                    controller: _controller,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: l10n.devicePinHint,
                      counterText: '',
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!_busy) _submit();
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('device-pin-unlock-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(l10n.adminPinConfirm),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
