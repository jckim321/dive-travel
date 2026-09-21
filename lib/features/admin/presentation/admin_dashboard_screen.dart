import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/admin/presentation/admin_instructors_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_posts_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_pricing_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_shops_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_weather_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.adminDashboardSubtitle, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          _AdminMenuCard(
            key: const Key('admin-menu-members'),
            icon: Icons.groups_outlined,
            title: l10n.adminMembersTitle,
            subtitle: l10n.adminMembersSubtitle,
            onTap: () => _open(context, const AdminMembersScreen()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            key: const Key('admin-menu-instructors'),
            icon: Icons.verified_user,
            title: l10n.adminInstructorsTitle,
            subtitle: l10n.adminInstructorsSubtitle,
            onTap: () => _open(context, const AdminInstructorsScreen()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            key: const Key('admin-menu-shops'),
            icon: Icons.stars,
            title: l10n.adminShopsTitle,
            subtitle: l10n.adminShopsSubtitle,
            onTap: () => _open(context, const AdminShopsScreen()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            key: const Key('admin-menu-pricing'),
            icon: Icons.percent,
            title: l10n.adminPricingTitle,
            subtitle: l10n.adminPricingSubtitle,
            onTap: () => _open(context, const AdminPricingScreen()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            key: const Key('admin-menu-posts'),
            icon: Icons.fact_check,
            title: l10n.adminPostsTitle,
            subtitle: l10n.adminPostsSubtitle,
            onTap: () => _open(context, const AdminPostsScreen()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            key: const Key('admin-menu-weather'),
            icon: Icons.thunderstorm_outlined,
            title: l10n.weatherAdminTitle,
            subtitle: l10n.weatherAdminBody,
            onTap: () => _open(context, const AdminWeatherScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
