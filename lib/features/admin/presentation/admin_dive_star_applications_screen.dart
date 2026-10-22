import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/data/dive_star_loi_pdf.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminDiveStarApplicationsScreen extends StatefulWidget {
  const AdminDiveStarApplicationsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminDiveStarApplicationsScreen> createState() =>
      _AdminDiveStarApplicationsScreenState();
}

class _AdminDiveStarApplicationsScreenState
    extends State<AdminDiveStarApplicationsScreen> {
  bool _loading = true;
  Object? _error;
  List<DiveStarApplication> _apps = const [];
  List<PartnerEmailOutboxItem> _outbox = const [];

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
      final apps = await store.listDiveStarApplications();
      final outbox = await store.listPartnerEmailOutbox();
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = apps;
        _outbox = outbox;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _statusLabel(AppLocalizations l10n, DiveStarPipelineStatus s) {
    return switch (s) {
      DiveStarPipelineStatus.guideSent => l10n.pipelineGuideSent,
      DiveStarPipelineStatus.loiReceived => l10n.pipelineLoiReceived,
      DiveStarPipelineStatus.docsSubmitted => l10n.pipelineDocsSubmitted,
      DiveStarPipelineStatus.underReview => l10n.pipelineUnderReview,
      DiveStarPipelineStatus.resultNotified => l10n.pipelineResultNotified,
    };
  }

  Future<void> _advance(DiveStarApplication app) async {
    final next = app.pipelineStatus.next;
    if (next == null) {
      return;
    }
    final store = DiverStoreScope.of(context);
    await store.updateDiveStarApplicationPipeline(
      applicationId: app.id,
      status: next,
      reminderDueAt: DateTime.now().toUtc().add(const Duration(days: 14)),
    );
    await _reload();
  }

  Future<void> _queueReminder(DiveStarApplication app) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (app.contactEmail.trim().isEmpty) {
      return;
    }
    final subject = l10n.pipelineReminderSubject(app.shopName);
    final body = l10n.pipelineReminderBody(app.shopName, app.contactName);
    final item = await store.queuePartnerEmail(
      toEmail: app.contactEmail,
      subject: subject,
      body: body,
      applicationId: app.id,
      shopId: app.shopId,
    );
    await store.updateDiveStarApplicationPipeline(
      applicationId: app.id,
      status: app.pipelineStatus,
      reminderDueAt: DateTime.now().toUtc().add(const Duration(days: 14)),
    );
    if (!mounted) {
      return;
    }
    final uri = Uri.parse(
      'mailto:${Uri.encodeComponent(app.contactEmail)}'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri);
    await store.markPartnerEmailOutboxSent(item.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pipelineReminderQueued)),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final due = _apps.where((a) => a.reminderDue).toList();

    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.adminAppsTitle,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      l10n.adminAppsHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminConsoleTheme.muted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.adminAppsReminderSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.adminAppsEmailServerNote),
                    const SizedBox(height: 8),
                    if (due.isEmpty)
                      Text(l10n.adminAppsReminderEmpty)
                    else
                      for (final app in due)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(app.shopName),
                          subtitle: Text(
                            [
                              app.contactEmail,
                              if (app.reminderDueAt != null)
                                l10n.adminAppsReminderDue(
                                  DateFormat.yMMMd().format(
                                    app.reminderDueAt!.toLocal(),
                                  ),
                                ),
                            ].join(' · '),
                          ),
                          trailing: TextButton(
                            onPressed: () => _queueReminder(app),
                            child: Text(l10n.adminAppsSendReminder),
                          ),
                        ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminAppsListSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_apps.isEmpty)
                      Text(l10n.adminAppsEmpty)
                    else
                      for (final app in _apps) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.shopName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  [
                                    DateFormat.yMMMd()
                                        .format(app.submittedAt.toLocal()),
                                    app.contactName,
                                    _statusLabel(l10n, app.pipelineStatus),
                                    if (app.reminderDueAt != null)
                                      l10n.adminAppsReminderDue(
                                        DateFormat.yMMMd().format(
                                          app.reminderDueAt!.toLocal(),
                                        ),
                                      ),
                                  ].join(' · '),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () async {
                                        final bytes =
                                            await buildDiveStarLoiPdf(app);
                                        await Printing.layoutPdf(
                                          onLayout: (_) async => bytes,
                                        );
                                      },
                                      child: Text(l10n.adminDocActionPrint),
                                    ),
                                    if (app.pipelineStatus.next != null)
                                      FilledButton.tonal(
                                        onPressed: () => _advance(app),
                                        child: Text(
                                          l10n.adminAppsAdvanceTo(
                                            _statusLabel(
                                              l10n,
                                              app.pipelineStatus.next!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (app.contactEmail.isNotEmpty)
                                      TextButton(
                                        onPressed: () => _queueReminder(app),
                                        child: Text(l10n.adminAppsSendReminder),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminAppsOutboxSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_outbox.isEmpty)
                      Text(l10n.adminAppsOutboxEmpty)
                    else
                      for (final mail in _outbox)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(mail.subject),
                          subtitle: Text(
                            '${mail.toEmail} · ${mail.status} · '
                            '${DateFormat.yMMMd().add_Hm().format(mail.createdAt.toLocal())}',
                          ),
                        ),
                  ],
                ),
    );
  }
}
