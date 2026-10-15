import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/century_tank_colors.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/features/profile/presentation/departure_desk_header.dart';
import 'package:dive_travel_app/features/profile/presentation/my_crafted_trips_section.dart';
import 'package:dive_travel_app/features/profile/presentation/pro_verification_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final session = SessionScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.seaMist,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final stats = store.stats;
          final theme = Theme.of(context);
          final nextTrip = TravelStyleAnalyzer.nextTrip(store.bookings);
          final nextLabel = nextTrip == null
              ? null
              : l10n.exploreDepartureBanner(
                  TravelStyleAnalyzer.daysUntil(nextTrip.scheduledFor),
                  nextTrip.shopName,
                );
          final crafted = store.craftedProductsFor(store.uid ?? '');

          return ListView(
            key: const Key('profile-departure-desk'),
            padding: EdgeInsets.zero,
            children: [
              SafeArea(
                bottom: false,
                child: DepartureDeskHeader(
                  displayName: stats.displayName,
                  regionsCount: stats.uniqueRegionsCount,
                  nextDepartureLabel: nextLabel,
                ),
              ),
              if (store.loading)
                const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (store.bookings.isNotEmpty) ...[
                      MyBookingsSection(bookings: store.bookings),
                      const SizedBox(height: 28),
                    ],
                    MyCraftedTripsSection(products: crafted),
                    const SizedBox(height: 28),
                    AppSectionHeader(title: l10n.profileRadarTitle),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profilePassportHint,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    PassportStamps(
                      stamped: {
                        for (final region in store.regions)
                          RegionCatalog.countryOf(region),
                      },
                    ),
                    const SizedBox(height: 28),
                    AppSectionHeader(title: l10n.profileMasterChallenge),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Center(
                        child: TankGauge(
                          progress: stats.centuryProgress,
                          label: l10n.profileLogsProgress(
                            stats.totalLogCount,
                            stats.currentCenturyTarget,
                          ),
                          isComplete: stats.centuryProgress >= 1 &&
                              stats.totalLogCount > 0,
                          fillColor:
                              CenturyTankColors.ofLogs(stats.totalLogCount),
                          borderColor:
                              CenturyTankColors.ofLogs(stats.totalLogCount),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (stats.hasReachedMaster) ...[
                      FilledButton.icon(
                        onPressed: () => _showMetalCardDialog(context, l10n),
                        icon: const Icon(
                          Icons.workspace_premium_outlined,
                          size: 20,
                        ),
                        label: Text(l10n.profileMetalCard),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.navy,
                        ),
                      ),
                      if (!stats.hasReachedLegend) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.logbookCenturyHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ] else
                      Text(
                        l10n.profileMetalCardHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 32),
                    AppSectionHeader(title: l10n.profileDeskToolsTitle),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profileDeskToolsHint,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    if (stats.isAdmin) ...[
                      FilledButton.icon(
                        key: const Key('open-admin-mode'),
                        onPressed: () => openAdminMode(context),
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 20,
                        ),
                        label: Text(l10n.adminMode),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (stats.isBusiness) ...[
                      FilledButton.tonalIcon(
                        key: const Key('open-partner-mode'),
                        onPressed: () => openPartnerMode(context),
                        icon: const Icon(Icons.storefront_outlined, size: 20),
                        label: Text(l10n.partnerTitle),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Chip(
                      label: Text(_gradeLabel(l10n, stats.memberGrade)),
                    ),
                    if (stats.isVerifiedPro)
                      Chip(
                        avatar: const Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: AppTheme.navy,
                        ),
                        label: Text(l10n.profileProBadge),
                        backgroundColor: AppTheme.goldSoft,
                      ),
                    const SizedBox(height: 10),
                    const ProVerificationCard(),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const Key('profile-sign-out'),
                      onPressed: () => session.signOut(),
                      child: Text(l10n.profileSignOut),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMetalCardDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.metalCardDialogTitle),
          content: Text(l10n.metalCardDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.metalCardDialogClose),
            ),
          ],
        );
      },
    );
  }
}

String _gradeLabel(AppLocalizations l10n, MemberGrade grade) {
  switch (grade) {
    case MemberGrade.member:
      return l10n.memberGradeMember;
    case MemberGrade.special:
      return l10n.memberGradeSpecial;
    case MemberGrade.vip:
      return l10n.memberGradeVip;
    case MemberGrade.instructor:
      return l10n.memberGradeInstructor;
  }
}
