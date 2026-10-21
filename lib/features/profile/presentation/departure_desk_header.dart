import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Identity header on My page. Grade follows stored [MemberGrade].
class DepartureDeskHeader extends StatelessWidget {
  const DepartureDeskHeader({
    super.key,
    required this.displayName,
    required this.regionsCount,
    required this.logCount,
    required this.memberGrade,
    required this.isInstructor,
    required this.onSettings,
  });

  final String displayName;
  final int regionsCount;
  final int logCount;
  final MemberGrade memberGrade;
  final bool isInstructor;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final grade = ProfileDisplayGrade.fromMember(
      grade: memberGrade,
      isInstructor: isInstructor,
    );
    final gradeLabel = switch (grade) {
      ProfileDisplayGrade.silver => l10n.profileGradeSilver,
      ProfileDisplayGrade.gold => l10n.profileGradeGold,
      ProfileDisplayGrade.diamond => l10n.profileGradeDiamond,
      ProfileDisplayGrade.platinum => l10n.profileGradePlatinum,
      ProfileDisplayGrade.instructor => l10n.profileGradeInstructor,
    };
    final gradeMark = switch (grade) {
      ProfileDisplayGrade.silver => '🥈',
      ProfileDisplayGrade.gold => '🥇',
      ProfileDisplayGrade.diamond => '💎',
      ProfileDisplayGrade.platinum => '💠',
      ProfileDisplayGrade.instructor => '🎓',
    };

    return Container(
      key: const Key('departure-desk-header'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF052A4A),
            Color(0xFF0B3A4F),
            Color(0xFF164A5C),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3C8FB6), Color(0xFF0A4A73)],
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.scuba_diving_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileMyOceanKicker,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFD7E7EF),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$gradeMark $gradeLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.profileRegions(regionsCount)} · '
                  '${l10n.profileTotalDives} $logCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('open-profile-settings'),
            onPressed: onSettings,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('👤 ${l10n.profileViewMyInfo}'),
          ),
        ],
      ),
    );
  }
}
