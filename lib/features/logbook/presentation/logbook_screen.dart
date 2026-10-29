import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/tank_rack.dart';
import 'package:dive_travel_app/features/logbook/presentation/add_log_screen.dart';
import 'package:dive_travel_app/features/logbook/presentation/checklist_screen.dart';
import 'package:dive_travel_app/features/logbook/presentation/travel_log_card.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureLogsLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final logs = store.logs;
        final totalMinutes = logs.fold<int>(
          0,
          (sum, log) => sum + (log.profile?.minutes ?? 0),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.logbookTitle),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChecklistScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.checklist_outlined, size: 20),
                label: Text(l10n.logbookChecklist),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'logbook-fab',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddLogScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.logbookAdd),
          ),
          body: RefreshIndicator(
            onRefresh: store.refreshLogs,
            child: ListView(
              key: const Key('logbook-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                TankRack(totalLogs: store.stats.totalLogCount),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E1D4)),
                  ),
                  child: Row(
                    children: [
                      _DashStat(
                        label: l10n.logbookStatDives,
                        value: '${store.stats.totalLogCount}',
                        unit: l10n.logbookStatDiveUnit,
                      ),
                      _DashStat(
                        label: l10n.logbookStatTime,
                        value: '$totalMinutes',
                        unit: l10n.logbookMinUnit,
                      ),
                      _DashStat(
                        label: l10n.logbookStatRegions,
                        value: '${store.stats.uniqueRegionsCount}',
                        unit: l10n.logbookStatRegionUnit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(
                      l10n.logbookEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else ...[
                  Text(
                    l10n.logbookJournalTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < logs.length; i++) ...[
                    TravelLogCard(
                      log: logs[i],
                      logNumber: logs.length - i,
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AddLogScreen(existing: logs[i]),
                          ),
                        );
                      },
                      onReview: () {
                        final matched = shopForSite(
                          logs[i].siteName,
                          store.shops,
                        );
                        openOperationReview(
                          context,
                          shopId: matched?.id,
                          logId: logs[i].id,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (store.logsHasMore) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: () => unawaited(store.loadMoreLogs()),
                        child: const Text('Load more'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashStat extends StatelessWidget {
  const _DashStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
