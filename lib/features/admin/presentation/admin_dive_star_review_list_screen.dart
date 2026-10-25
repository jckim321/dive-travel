import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_assessment_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dive_star_milestone.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _ReviewListFilter { all, pending, preReview }

/// Dive Star hub «심사·등급»: roster shops, milestone label, open the audit.
class AdminDiveStarReviewListScreen extends StatefulWidget {
  const AdminDiveStarReviewListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminDiveStarReviewListScreen> createState() =>
      _AdminDiveStarReviewListScreenState();
}

class _AdminDiveStarReviewListScreenState
    extends State<AdminDiveStarReviewListScreen> {
  final _query = TextEditingController();
  _ReviewListFilter _filter = _ReviewListFilter.all;
  List<DiveStarApplication> _apps = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApps());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    if (!mounted) {
      return;
    }
    try {
      final apps = await DiverStoreScope.of(context).listDiveStarApplications();
      if (!mounted) {
        return;
      }
      setState(() => _apps = apps);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _apps = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final needle = _query.text.trim().toLowerCase();
        final rows = <_ReviewRow>[];
        for (final shop in store.shops) {
          if (needle.isNotEmpty &&
              !shop.name.toLowerCase().contains(needle) &&
              !shop.hullId.toLowerCase().contains(needle)) {
            continue;
          }
          final live =
              store.liveStatsFor(shop.hullId) ?? store.liveStatsFor(shop.id);
          final latest = PartnerDiveStarMilestone.latestForShop(
            _apps,
            shop.hullId,
          );
          final step = PartnerDiveStarMilestone.resolve(
            diveStarGrade: live?.diveStar ?? 0,
            latestApplication: latest,
          );
          final pending =
              latest?.pipelineStatus == DiveStarPipelineStatus.underReview;
          if (_filter == _ReviewListFilter.pending && !pending) {
            continue;
          }
          if (_filter == _ReviewListFilter.preReview &&
              step != PartnerDiveStarMilestoneStep.preReview) {
            continue;
          }
          rows.add(_ReviewRow(shop: shop, step: step, pending: pending));
        }
        rows.sort((a, b) {
          if (a.pending != b.pending) {
            return a.pending ? -1 : 1;
          }
          final byStep = _stepRank(b.step).compareTo(_stepRank(a.step));
          if (byStep != 0) {
            return byStep;
          }
          return a.shop.name.compareTo(b.shop.name);
        });

        return adminScreenShell(
          embedded: widget.embedded,
          title: l10n.adminDiveStarSubReview,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  key: const Key('admin-dive-star-review-search'),
                  controller: _query,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.adminDiveStarReviewSearch,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in <(_ReviewListFilter, String, Key)>[
                      (
                        _ReviewListFilter.all,
                        l10n.adminPartnerTierAll,
                        const Key('admin-dive-star-review-filter-all'),
                      ),
                      (
                        _ReviewListFilter.pending,
                        l10n.adminDiveStarReviewPending,
                        const Key('admin-dive-star-review-filter-pending'),
                      ),
                      (
                        _ReviewListFilter.preReview,
                        l10n.partnerMilestonePreReview,
                        const Key('admin-dive-star-review-filter-pre'),
                      ),
                    ])
                      FilterChip(
                        key: entry.$3,
                        label: Text(entry.$2),
                        selected: _filter == entry.$1,
                        onSelected: (_) => setState(() => _filter = entry.$1),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          l10n.adminDiveStarReviewEmpty,
                          key: const Key('admin-dive-star-review-empty'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ReviewTile(
                              row: row,
                              stageLabel: _stageLabel(l10n, row.step),
                              pendingLabel: l10n.adminDiveStarReviewPending,
                              onTap: () {
                                final shop = row.shop;
                                unawaited(
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          AdminDiveStarAssessmentScreen(
                                            shopId: shop.hullId,
                                            shopName: shop.name,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewRow {
  const _ReviewRow({
    required this.shop,
    required this.step,
    required this.pending,
  });

  final DiveShop shop;
  final PartnerDiveStarMilestoneStep step;
  final bool pending;
}

int _stepRank(PartnerDiveStarMilestoneStep step) {
  return switch (step) {
    PartnerDiveStarMilestoneStep.threeStar => 4,
    PartnerDiveStarMilestoneStep.twoStar => 3,
    PartnerDiveStarMilestoneStep.oneStar => 2,
    PartnerDiveStarMilestoneStep.preReview => 1,
    PartnerDiveStarMilestoneStep.generalPartner => 0,
  };
}

String _stageLabel(AppLocalizations l10n, PartnerDiveStarMilestoneStep step) {
  return switch (step) {
    PartnerDiveStarMilestoneStep.generalPartner => l10n.partnerMilestoneGeneral,
    PartnerDiveStarMilestoneStep.preReview => l10n.partnerMilestonePreReview,
    PartnerDiveStarMilestoneStep.oneStar => l10n.partnerMilestoneOneStar,
    PartnerDiveStarMilestoneStep.twoStar => l10n.partnerMilestoneTwoStar,
    PartnerDiveStarMilestoneStep.threeStar => l10n.partnerMilestoneThreeStar,
  };
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.row,
    required this.stageLabel,
    required this.pendingLabel,
    required this.onTap,
  });

  final _ReviewRow row;
  final String stageLabel;
  final String pendingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        key: Key('admin-dive-star-review-${row.shop.hullId}'),
        title: Text(row.shop.name),
        subtitle: Text(stageLabel),
        trailing: row.pending
            ? Text(
                pendingLabel,
                key: Key('admin-dive-star-review-pending-${row.shop.hullId}'),
                style: const TextStyle(
                  color: AdminConsoleTheme.amber,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
