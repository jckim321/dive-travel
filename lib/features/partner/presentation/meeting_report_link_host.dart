import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_preview.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Opens `#report={id}` after sign-in. Guests and denied reads see one line.
class MeetingReportLinkHost extends StatefulWidget {
  const MeetingReportLinkHost({
    super.key,
    required this.reportId,
    required this.child,
  });

  final String? reportId;
  final Widget child;

  @override
  State<MeetingReportLinkHost> createState() => _MeetingReportLinkHostState();
}

class _MeetingReportLinkHostState extends State<MeetingReportLinkHost> {
  SessionController? _session;
  DiverStore? _store;
  DevicePinController? _pins;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (!identical(_session, session)) {
      _session?.removeListener(_schedule);
      _session = session;
      _session!.addListener(_schedule);
    }
    final store = DiverStoreScope.of(context);
    if (!identical(_store, store)) {
      _store?.removeListener(_schedule);
      _store = store;
      _store!.addListener(_schedule);
    }
    final pins = DevicePinScope.of(context);
    if (!identical(_pins, pins)) {
      _pins?.removeListener(_schedule);
      _pins = pins;
      _pins!.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void dispose() {
    _session?.removeListener(_schedule);
    _store?.removeListener(_schedule);
    _pins?.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    final id = widget.reportId?.trim() ?? '';
    if (id.isEmpty || _started) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_open());
      });
    });
  }

  Future<void> _open() async {
    if (!mounted || _started) {
      return;
    }
    final id = widget.reportId?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }
    final session = _session;
    final store = _store;
    final pins = _pins;
    if (session == null || store == null || pins == null || !session.ready) {
      return;
    }
    if (!session.isSignedIn) {
      _started = true;
      _showDenied();
      return;
    }
    if (store.loading || !pins.ready) {
      return;
    }
    final staff = store.stats.isAdmin || store.stats.isBusiness;
    if (pins.needsUnlock(uid: store.uid, isStaff: staff)) {
      return;
    }
    _started = true;
    try {
      final report = await store.getMeetingReport(id);
      if (!mounted) {
        return;
      }
      if (report == null) {
        _showDenied();
        return;
      }
      try {
        await store.ensureShopStatsLoaded();
      } catch (error, stackTrace) {
        debugPrint('meeting report shop failed $error');
        debugPrint('$stackTrace');
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminPartnerMeetingPreview(
            report: report,
            shopName: _shopName(store, report.recipe.hullId),
            periodLabel: meetingReportPeriodLabel(report.recipe),
            readOnly: true,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('meeting report link failed $error');
      debugPrint('$stackTrace');
      if (mounted) {
        _showDenied();
      }
    }
  }

  void _showDenied() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MeetingReportDeniedPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MeetingReportDeniedPage extends StatelessWidget {
  const MeetingReportDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).partnerMeetingDenied,
          key: const Key('partner-meeting-link-denied'),
        ),
      ),
    );
  }
}

String _shopName(DiverStore store, String hull) {
  for (final stats in store.shopStats) {
    if (partnerShopHull(stats.shopId) != hull) {
      continue;
    }
    final name = (stats.name ?? '').trim();
    if (name.isNotEmpty) {
      return name;
    }
  }
  return hull;
}
