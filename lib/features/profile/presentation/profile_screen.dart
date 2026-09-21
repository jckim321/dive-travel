import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/core/theme/century_tank_colors.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/features/profile/presentation/pro_verification_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final session = SessionScope.of(context);
    final stats = store.stats;
    final theme = Theme.of(context);
    final email = session.user?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          TextButton(
            onPressed: () => SessionScope.of(context).signOut(),
            child: Text(l10n.profileSignOut),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (store.loading) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 16),
          ],
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.canvas,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 30,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.displayName, style: theme.textTheme.titleLarge),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(email, style: theme.textTheme.bodySmall),
                      ],
                      const SizedBox(height: 10),
                      Chip(
                        label: Text(
                          _gradeLabel(l10n, stats.memberGrade),
                        ),
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
                      Text(
                        l10n.profileRegions(stats.uniqueRegionsCount),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (stats.isAdmin) ...[
            FilledButton.icon(
              key: const Key('open-admin-mode'),
              onPressed: () => openAdminMode(context),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
              label: Text(l10n.adminMode),
            ),
            const SizedBox(height: 12),
          ],
          if (stats.isBusiness) ...[
            FilledButton.tonalIcon(
              key: const Key('open-partner-mode'),
              onPressed: () => openPartnerMode(context),
              icon: const Icon(Icons.storefront_outlined, size: 20),
              label: Text(l10n.partnerTitle),
            ),
            const SizedBox(height: 16),
          ],
          const ProVerificationCard(),
          const SizedBox(height: 32),
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
                fillColor: CenturyTankColors.ofLogs(stats.totalLogCount),
                borderColor: CenturyTankColors.ofLogs(stats.totalLogCount),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (stats.hasReachedMaster) ...[
            FilledButton.icon(
              onPressed: () => _showMetalCardDialog(context, l10n),
              icon: const Icon(Icons.workspace_premium_outlined, size: 20),
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
        ],
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
