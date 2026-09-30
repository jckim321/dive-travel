import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/bilingual_rotator.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Full-bleed ocean hero with passport / luggage / boarding accents —
/// travel mood without a boarding-pass card.
class TravelPosterHeader extends StatefulWidget {
  const TravelPosterHeader({super.key});

  @override
  State<TravelPosterHeader> createState() => _TravelPosterHeaderState();
}

class _TravelPosterHeaderState extends State<TravelPosterHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _stampOpacity;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _brandTracking;
  late final Animation<double> _stubWidth;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _stampOpacity = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _brandOpacity = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOut),
    );
    _brandTracking = Tween<double>(begin: 6, end: 2.2).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.12, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _stubWidth = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF052A4A),
              Color(0xFF0B1F33),
              Color(0xFF0A4A73),
              Color(0xFF16344A),
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: _OceanVeil())),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 28),
                child: AnimatedBuilder(
                  animation: _enter,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _QuietActions(
                          isAdmin: stats.isAdmin,
                          isBusiness: stats.isBusiness,
                          isSignedIn: session.isSignedIn,
                          onAdmin: () => openAdminMode(context),
                          onPartner: () => openPartnerMode(context),
                          onAuth: session.isSignedIn
                              ? () => session.signOut()
                              : null,
                          signOutLabel: l10n.profileSignOut,
                          loginLabel: l10n.authLogin,
                          adminTooltip: l10n.adminMode,
                          partnerTooltip: l10n.partnerTitle,
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: _brandOpacity.value,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: _stampOpacity.value,
                                child: const _PassportStamp(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  english.appTitle.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: _brandTracking.value,
                                    height: 1.05,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
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
                        const SizedBox(height: 20),
                        const _LuggageChip(),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.28 + (0.72 * _stubWidth.value),
                            alignment: Alignment.centerLeft,
                            child: const _BoardingStubStrip(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OceanVeil extends StatelessWidget {
  const _OceanVeil();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.8, -1),
          end: Alignment(0.9, 1.1),
          colors: [
            Color(0x33C4A35A),
            Color(0x00000000),
            Color(0x22156A96),
            Color(0x44052A4A),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
    );
  }
}

class _QuietActions extends StatelessWidget {
  const _QuietActions({
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
    return Row(
      children: [
        const Spacer(),
        if (isAdmin)
          IconButton(
            key: const Key('open-admin-mode-home'),
            tooltip: adminTooltip,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.92),
            ),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: onAdmin,
          ),
        if (isBusiness)
          IconButton(
            key: const Key('open-partner-mode-home'),
            tooltip: partnerTooltip,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.92),
            ),
            icon: const Icon(Icons.storefront_outlined),
            onPressed: onPartner,
          ),
        TextButton(
          key: const Key('home-auth-button'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.88),
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          onPressed: onAuth,
          child: Text(isSignedIn ? signOutLabel : loginLabel),
        ),
      ],
    );
  }
}

class _PassportStamp extends StatelessWidget {
  const _PassportStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gold, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.55),
            width: 1,
          ),
          color: const Color(0xCC0B1F33),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/icons/app_icon.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.scuba_diving,
              color: AppTheme.gold,
              size: 24,
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
    return SizedBox(
      height: 88,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              height: 1.22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuggageChip extends StatelessWidget {
  const _LuggageChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x22F4EBD3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 1.4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DIVE · SS-07',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
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
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gold,
                AppTheme.gold.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'BOARDING  ·  SEVEN SEAS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
