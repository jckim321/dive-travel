import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/profile/presentation/flight_link_sheet.dart';
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
    this.showFlightSearch = true,
  });

  final String displayName;
  final int regionsCount;
  final int logCount;
  final MemberGrade memberGrade;
  final bool isInstructor;
  final VoidCallback onSettings;

  /// My hides this row. The boarding pass opens the same sheet.
  final bool showFlightSearch;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          if (showFlightSearch) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                key: const Key('profile-flight-search'),
                borderRadius: BorderRadius.circular(999),
                onTap: () => showFlightLinkSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flight, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.profileFlightSearch,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.profileFlightPayHint,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
