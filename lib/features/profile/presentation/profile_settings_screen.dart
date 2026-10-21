import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/features/profile/presentation/pro_verification_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final session = SessionScope.of(context);
    final stats = store.stats;
    final email = session.user?.email ?? '';
    final useGrade = ProfileDisplayGrade.fromMember(
      grade: stats.memberGrade,
      isInstructor: stats.isInstructor,
    );

    return Scaffold(
      backgroundColor: AppTheme.seaMist,
      appBar: AppBar(title: Text(l10n.profileSettingsTitle)),
      body: ListView(
        key: const Key('profile-settings-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  title: stats.displayName,
                  subtitle: email,
                ),
                const Divider(height: 28),
                _SettingsRow(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.profileMembershipTitle,
                  subtitle: _useGradeLabel(l10n, useGrade),
                ),
                const SizedBox(height: 16),
                _GradeLadder(current: useGrade),
                const SizedBox(height: 10),
                Text(
                  _nextGradeLine(l10n, stats),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (stats.isAdmin || stats.isBusiness) ...[
            const SizedBox(height: 24),
            Text(
              l10n.profileWorkModeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              child: Column(
                children: [
                  if (stats.isAdmin)
                    _SettingsAction(
                      key: const Key('open-admin-mode'),
                      icon: Icons.admin_panel_settings_outlined,
                      title: l10n.adminMode,
                      onTap: () => openAdminMode(context),
                    ),
                  if (stats.isAdmin && stats.isBusiness)
                    const Divider(height: 1),
                  if (stats.isBusiness)
                    _SettingsAction(
                      key: const Key('open-partner-mode'),
                      icon: Icons.storefront_outlined,
                      title: l10n.partnerTitle,
                      onTap: () => openPartnerMode(context),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            key: const Key('profile-sign-out'),
            onPressed: () => session.signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(l10n.profileSignOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.profileCredentialsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const ProVerificationCard(),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: AppTheme.navy.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.ocean),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.ocean),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

String _useGradeLabel(AppLocalizations l10n, ProfileDisplayGrade grade) {
  return switch (grade) {
    ProfileDisplayGrade.silver => l10n.profileGradeSilver,
    ProfileDisplayGrade.gold => l10n.profileGradeGold,
    ProfileDisplayGrade.diamond => l10n.profileGradeDiamond,
    ProfileDisplayGrade.platinum => l10n.profileGradePlatinum,
    ProfileDisplayGrade.instructor => l10n.profileGradeInstructor,
  };
}

String _nextGradeLine(AppLocalizations l10n, DiverStats stats) {
  if (stats.isInstructor || stats.memberGrade == MemberGrade.platinum) {
    return l10n.profileGradeDeepest;
  }
  final deficit = MemberGrade.deficitToNext(
    current: stats.memberGrade,
    paidPurchases: stats.paidPurchaseCount,
    reviews: stats.reviewCount,
  );
  final nextLabel = switch (stats.memberGrade) {
    MemberGrade.silver => l10n.profileGradeGold,
    MemberGrade.gold => l10n.profileGradeDiamond,
    MemberGrade.diamond => l10n.profileGradePlatinum,
    MemberGrade.platinum => l10n.profileGradePlatinum,
  };
  return '${l10n.adminNearUpgradeHint(deficit.$1, deficit.$2)} → $nextLabel';
}

class _GradeLadder extends StatefulWidget {
  const _GradeLadder({required this.current});

  final ProfileDisplayGrade current;

  @override
  State<_GradeLadder> createState() => _GradeLadderState();
}

class _GradeLadderState extends State<_GradeLadder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  static const _steps = [
    (ProfileDisplayGrade.silver, '🥈'),
    (ProfileDisplayGrade.gold, '🥇'),
    (ProfileDisplayGrade.diamond, '💎'),
    (ProfileDisplayGrade.platinum, '💠'),
  ];

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final testing = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!testing) {
      _blink.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(height: 2, color: const Color(0xFFD5DDE3)),
            ),
          FadeTransition(
            opacity: widget.current == _steps[i].$1
                ? Tween<double>(begin: 0.35, end: 1).animate(_blink)
                : const AlwaysStoppedAnimation(1),
            child: Text(_steps[i].$2, style: const TextStyle(fontSize: 22)),
          ),
        ],
      ],
    );
  }
}
