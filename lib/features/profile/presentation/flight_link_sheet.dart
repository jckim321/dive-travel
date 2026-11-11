import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Opens the flight-app picker from the My tab header.
Future<void> showFlightLinkSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => const FlightLinkSheet(),
  );
}

class FlightLinkSheet extends StatelessWidget {
  const FlightLinkSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final links = <({String label, String url, bool featured})>[
      (
        label: l10n.profileFlightSkyscanner,
        url: 'https://www.skyscanner.co.kr',
        featured: true,
      ),
      (
        label: l10n.profileFlightNaver,
        url: 'https://flight.naver.com',
        featured: false,
      ),
      (
        label: l10n.profileFlightGoogle,
        url: 'https://www.google.com/travel/flights',
        featured: false,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileFlightSheetTitle,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.profileFlightSheetBody,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            for (final link in links) ...[
              _FlightLinkRow(
                label: link.label,
                url: link.url,
                featured: link.featured,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.profileFlightDisclaimer,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightLinkRow extends StatelessWidget {
  const _FlightLinkRow({
    required this.label,
    required this.url,
    required this.featured,
  });

  final String label;
  final String url;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: featured ? AppTheme.goldSoft : const Color(0xFFF6F7F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: featured ? AppTheme.gold : const Color(0xFFE4E8EE),
          width: featured ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        key: Key('flight-link-${Uri.parse(url).host}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new,
                size: 16,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
