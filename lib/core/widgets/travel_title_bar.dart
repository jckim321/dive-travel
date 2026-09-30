import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/bilingual_rotator.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Compact APDI-style hero card: photo background, darkened for type.
class TravelPosterHeader extends StatefulWidget {
  const TravelPosterHeader({super.key});

  @override
  State<TravelPosterHeader> createState() => _TravelPosterHeaderState();
}

class _TravelPosterHeaderState extends State<TravelPosterHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<double> _stubWidth;

  static const _heroAsset = 'assets/images/home_hero_dive.jpg';

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _stubWidth = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = lookupAppLocalizations(const Locale('en'));
    final session = SessionScope.of(context);
    final stats = DiverStoreScope.of(context).stats;
    final width = MediaQuery.sizeOf(context).width;
    final cardHeight = (width * 0.48).clamp(168.0, 220.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppTheme.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrangeTopBar(
              title: english.appTitle.toUpperCase(),
              isAdmin: stats.isAdmin,
              isBusiness: stats.isBusiness,
              isSignedIn: session.isSignedIn,
              onAdmin: () => openAdminMode(context),
              onPartner: () => openPartnerMode(context),
              onAuth: session.isSignedIn ? () => session.signOut() : null,
              signOutLabel: l10n.profileSignOut,
              loginLabel: l10n.authLogin,
              adminTooltip: l10n.adminMode,
              partnerTooltip: l10n.partnerTitle,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: AnimatedBuilder(
                animation: _enter,
                builder: (context, _) {
                  return Opacity(
                    opacity: _fade.value,
                    child: SizedBox(
                      height: cardHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: AppTheme.oceanDeep),
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.28),
                                  BlendMode.darken,
                                ),
                                child: Image.asset(
                                  _heroAsset,
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, -0.15),
                                  errorBuilder: (_, _, _) => const ColoredBox(
                                    color: AppTheme.oceanDeep,
                                  ),
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x99052A4A),
                                      Color(0x55052A4A),
                                      Color(0xCC0B1F33),
                                    ],
                                    stops: [0.0, 0.42, 1.0],
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Align(
                                      alignment: Alignment.topRight,
                                      child: _LuggageChip(),
                                    ),
                                    const Spacer(),
                                    BilingualRotator(
                                      alignment: Alignment.centerLeft,
                                      english: _SloganBlock(
                                        title: english.homeWelcome,
                                        subtitle: english.homeSubtitle,
                                      ),
                                      localized: _SloganBlock(
                                        title: l10n.homeWelcome,
                                        subtitle: l10n.homeSubtitle,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor:
                                            0.35 + (0.55 * _stubWidth.value),
                                        alignment: Alignment.centerLeft,
                                        child: const _BoardingStubStrip(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// APDI-like top app bar: brand left, login/actions right, orange field.
class _OrangeTopBar extends StatelessWidget {
  const _OrangeTopBar({
    required this.title,
    required this.isAdmin,
    required this.isBusiness,
    required this.isSignedIn,
    required this.onAdmin,
    required this.onPartner,
    required this.onAuth,
    required this.signOutLabel,
    required this.loginLabel,
    required this.adminTooltip,
    required this.partnerTooltip,
  });

  static const Color _orange = Color(0xFFE36A1A);

  final String title;
  final bool isAdmin;
  final bool isBusiness;
  final bool isSignedIn;
  final VoidCallback onAdmin;
  final VoidCallback onPartner;
  final VoidCallback? onAuth;
  final String signOutLabel;
  final String loginLabel;
  final String adminTooltip;
  final String partnerTooltip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _orange,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.4,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.scuba_diving,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      height: 1.1,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    key: const Key('open-admin-mode-home'),
                    tooltip: adminTooltip,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: onAdmin,
                  ),
                if (isBusiness)
                  IconButton(
                    key: const Key('open-partner-mode-home'),
                    tooltip: partnerTooltip,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.storefront_outlined),
                    onPressed: onPartner,
                  ),
                TextButton(
                  key: const Key('home-auth-button'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  onPressed: onAuth,
                  child: Text(isSignedIn ? signOutLabel : loginLabel),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SloganBlock extends StatelessWidget {
  const _SloganBlock({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.88),
            shadows: const [
              Shadow(
                color: Color(0x55000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuggageChip extends StatelessWidget {
  const _LuggageChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1F33),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 1.3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'SS-07',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.goldSoft.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardingStubStrip extends StatelessWidget {
  const _BoardingStubStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1.1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gold,
                AppTheme.gold.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BOARDING  ·  SEVEN SEAS',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
