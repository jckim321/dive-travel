import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/profile/presentation/partner_application_link_line.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminPartnerApplicationsScreen extends StatefulWidget {
  const AdminPartnerApplicationsScreen({
    super.key,
    this.embedded = false,
    required this.onOpenMember,
  });

  final bool embedded;
  final ValueChanged<String> onOpenMember;

  @override
  State<AdminPartnerApplicationsScreen> createState() =>
      _AdminPartnerApplicationsScreenState();
}

class _AdminPartnerApplicationsScreenState
    extends State<AdminPartnerApplicationsScreen> {
  var _loading = true;
  String? _error;
  List<PartnerApplication> _rows = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = sortPartnerApplicationsNewestFirst(
        await store.loadPartnerApplications(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _handle(PartnerApplication row) async {
    if (_busyId != null || row.status != PartnerApplicationStatus.incoming) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() => _busyId = row.applicantUid);
    try {
      await store.markPartnerApplicationHandled(row.applicantUid);
      await _reload();
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = DateFormat('yyyy-MM-dd HH:mm');
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              key: const Key('admin-apply-inbox'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AdminConsoleTheme.danger),
                  ),
                if (_rows.isEmpty)
                  Text(
                    l10n.adminApplyEmpty,
                    key: const Key('admin-apply-empty'),
                    style: const TextStyle(color: AdminConsoleTheme.muted),
                  ),
                for (final row in _rows)
                  Card(
                    key: Key('admin-apply-card-${row.applicantUid}'),
                    color: AdminConsoleTheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.loginId,
                            style: const TextStyle(
                              color: AdminConsoleTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row.status == PartnerApplicationStatus.incoming
                                ? l10n.adminApplyNew
                                : l10n.adminApplyHandled,
                            style: TextStyle(
                              color: row.status ==
                                      PartnerApplicationStatus.incoming
                                  ? AdminConsoleTheme.aqua
                                  : AdminConsoleTheme.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(row.shopName),
                          Text(row.contactName),
                          Text(row.phone),
                          Text(row.region),
                          Text(row.intro),
                          if (row.link.trim().isNotEmpty)
                            PartnerApplicationLinkLine(link: row.link),
                          const SizedBox(height: 6),
                          Text(
                            day.format(row.createdAt.toLocal()),
                            style: const TextStyle(
                              color: AdminConsoleTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                key: Key(
                                  'admin-apply-open-${row.applicantUid}',
                                ),
                                onPressed: () =>
                                    widget.onOpenMember(row.applicantUid),
                                child: Text(l10n.adminApplyOpenMember),
                              ),
                              if (row.status ==
                                  PartnerApplicationStatus.incoming)
                                FilledButton(
                                  key: Key(
                                    'admin-apply-handle-${row.applicantUid}',
                                  ),
                                  onPressed: _busyId == row.applicantUid
                                      ? null
                                      : () => _handle(row),
                                  child: Text(l10n.adminApplyMark),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: AdminConsoleTheme.bg,
      appBar: AppBar(title: Text(l10n.partnerApplyTitle)),
      body: body,
    );
  }
}
