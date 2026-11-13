import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _homeSkyscanner = 'https://www.skyscanner.co.kr';
const _homeNaver = 'https://flight.naver.com';
const _homeGoogle = 'https://www.google.com/travel/flights';

/// Opens the flight-app picker. Without a 3-letter [arrivalAirport] the
/// links stay the three homepages.
Future<void> showFlightLinkSheet(
  BuildContext context, {
  String? arrivalAirport,
  DateTime? depart,
  DateTime? ret,
}) {
  final arrival = normalizeNearestAirport(arrivalAirport ?? '');
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => FlightLinkSheet(
      arrivalAirport: arrival.isEmpty ? null : arrival,
      depart: depart,
      ret: ret,
    ),
  );
}

/// Skyscanner route page. Dates use YYMMDD. Omit both dates for the route only.
Uri skyscannerFlightUri({
  required String from,
  required String to,
  DateTime? depart,
  DateTime? ret,
}) {
  final origin = normalizeNearestAirport(from).toLowerCase();
  final dest = normalizeNearestAirport(to).toLowerCase();
  final segments = <String>['transport', 'flights', origin, dest];
  if (depart != null) {
    segments.add(_yymmdd(depart));
    if (ret != null) {
      segments.add(_yymmdd(ret));
    }
  }
  return Uri.https('www.skyscanner.co.kr', '/${segments.join('/')}/');
}

/// Naver international search. Confirmed path needs a departure date.
Uri naverFlightUri({
  required String from,
  required String to,
  required DateTime depart,
  DateTime? ret,
}) {
  final origin = normalizeNearestAirport(from);
  final dest = normalizeNearestAirport(to);
  final go = '$origin-$dest-${_yyyymmdd(depart)}';
  final back = ret == null ? '' : '/$dest-$origin-${_yyyymmdd(ret)}';
  return Uri.https('flight.naver.com', '/flights/international/$go$back', {
    'adult': '1',
    'fareType': 'Y',
  });
}

/// Google Flights natural-language search. Not the undocumented `tfs` blob.
Uri googleFlightUri({
  required String from,
  required String to,
  required DateTime depart,
  DateTime? ret,
}) {
  final origin = normalizeNearestAirport(from);
  final dest = normalizeNearestAirport(to);
  final start = _isoDay(depart);
  final query = ret == null
      ? 'Flights from $origin to $dest on $start one way'
      : 'Flights from $origin to $dest on $start returning ${_isoDay(ret)}';
  return Uri.https('www.google.com', '/travel/flights', {'q': query});
}

Future<void> openSkyscannerRoute({
  required String from,
  required String to,
  DateTime? depart,
  DateTime? ret,
}) {
  return launchUrl(
    skyscannerFlightUri(from: from, to: to, depart: depart, ret: ret),
    mode: LaunchMode.externalApplication,
  );
}

String _yymmdd(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  final year = (date.year % 100).toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final dateText = date.day.toString().padLeft(2, '0');
  return '$year$month$dateText';
}

String _yyyymmdd(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final dateText = date.day.toString().padLeft(2, '0');
  return '$year$month$dateText';
}

String _isoDay(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final dateText = date.day.toString().padLeft(2, '0');
  return '$year-$month-$dateText';
}

class _OriginAirport {
  const _OriginAirport(this.label, this.code);

  final String label;
  final String code;
}

const _origins = <_OriginAirport>[
  _OriginAirport('인천', 'ICN'),
  _OriginAirport('김포', 'GMP'),
  _OriginAirport('부산', 'PUS'),
  _OriginAirport('제주', 'CJU'),
];

class FlightLinkSheet extends StatefulWidget {
  const FlightLinkSheet({
    super.key,
    this.arrivalAirport,
    this.depart,
    this.ret,
  });

  final String? arrivalAirport;
  final DateTime? depart;
  final DateTime? ret;

  @override
  State<FlightLinkSheet> createState() => _FlightLinkSheetState();
}

class _FlightLinkSheetState extends State<FlightLinkSheet> {
  var _from = 'ICN';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arrival = widget.arrivalAirport;
    final links = arrival == null
        ? <({String label, String url, bool featured})>[
            (
              label: l10n.profileFlightSkyscanner,
              url: _homeSkyscanner,
              featured: true,
            ),
            (
              label: l10n.profileFlightNaver,
              url: _homeNaver,
              featured: false,
            ),
            (
              label: l10n.profileFlightGoogle,
              url: _homeGoogle,
              featured: false,
            ),
          ]
        : _filledLinks(l10n, arrival);

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
            if (arrival != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final origin in _origins)
                    ChoiceChip(
                      key: Key('flight-origin-${origin.code}'),
                      label: Text('${origin.label} ${origin.code}'),
                      selected: _from == origin.code,
                      onSelected: (_) => setState(() => _from = origin.code),
                    ),
                ],
              ),
            ],
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

  List<({String label, String url, bool featured})> _filledLinks(
    AppLocalizations l10n,
    String arrival,
  ) {
    final depart = widget.depart;
    final ret = widget.ret;
    final skyscanner = skyscannerFlightUri(
      from: _from,
      to: arrival,
      depart: depart,
      ret: ret,
    ).toString();
    final naver = depart == null
        ? _homeNaver
        : naverFlightUri(
            from: _from,
            to: arrival,
            depart: depart,
            ret: ret,
          ).toString();
    final google = depart == null
        ? _homeGoogle
        : googleFlightUri(
            from: _from,
            to: arrival,
            depart: depart,
            ret: ret,
          ).toString();
    return [
      (
        label: l10n.profileFlightSkyscanner,
        url: skyscanner,
        featured: true,
      ),
      (label: l10n.profileFlightNaver, url: naver, featured: false),
      (label: l10n.profileFlightGoogle, url: google, featured: false),
    ];
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
