import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProVerificationCard extends StatefulWidget {
  const ProVerificationCard({super.key});

  @override
  State<ProVerificationCard> createState() => _ProVerificationCardState();
}

class _ProVerificationCardState extends State<ProVerificationCard> {
  static const _agencies = ['PADI', 'SSI', 'NAUI', 'RAID', 'CMAS'];

  String _agency = 'PADI';
  PickedPhoto? _photo;
  bool _saving = false;
  final _picker = const DivePhotoPicker();

  Future<void> _pick() async {
    final photo = await _picker.pick();
    if (photo == null || !mounted) {
      return;
    }
    setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final photo = _photo;
    if (photo == null || _saving) {
      return;
    }
    if (!R2Config.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logbookPhotoMissingConfig)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await DiverStoreScope.of(context).submitProVerification(
        agency: _agency,
        photoBytes: photo.bytes,
        photoFileName: photo.fileName,
        photoContentType: photo.contentType,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.proSubmitDone)),
      );
    } on R2UploadException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.proSubmitFailed} ($error)')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final status = store.stats.proStatus;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.proTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(l10n.proBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                status == ProVerificationStatus.approved
                    ? Icons.verified_outlined
                    : Icons.hourglass_empty_outlined,
                size: 16,
              ),
              label: Text(_statusLabel(l10n, status)),
              backgroundColor: status == ProVerificationStatus.approved
                  ? AppTheme.goldSoft
                  : theme.colorScheme.secondaryContainer,
            ),
            if (status != ProVerificationStatus.approved) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _agency,
                decoration: InputDecoration(
                  labelText: l10n.proAgency,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final agency in _agencies)
                    DropdownMenuItem(value: agency, child: Text(agency)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _agency = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('pro-pick-ccard'),
                onPressed: _saving ? null : _pick,
                icon: const Icon(Icons.badge_outlined),
                label: Text(
                  _photo == null
                      ? l10n.proPickPhoto
                      : l10n.logbookPhotoPicked(_photo!.fileName),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('pro-submit'),
                onPressed: _saving || _photo == null ? null : _submit,
                child: Text(_saving ? l10n.logbookUploading : l10n.proSubmit),
              ),
            ],
          ],
        ),
    );
  }

  String _statusLabel(AppLocalizations l10n, ProVerificationStatus status) {
    switch (status) {
      case ProVerificationStatus.pending:
        return l10n.proStatusPending;
      case ProVerificationStatus.approved:
        return l10n.profileProBadge;
      case ProVerificationStatus.rejected:
        return l10n.proStatusRejected;
      case ProVerificationStatus.none:
        return l10n.proStatusNone;
    }
  }
}
