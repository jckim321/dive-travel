import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/bilingual_rotator.dart';
import 'package:dive_travel_app/core/widgets/language_switch.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
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
    final cardHeight = (width * 0.36).clamp(132.0, 152.0);

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
              onAuth: () async {
                if (session.isSignedIn) {
                  final nav = Navigator.of(context);
                  await session.signOut();
                  nav.popUntil((route) => route.isFirst);
                  return;
                }
                if (!context.mounted) return;
                await ensureSignedIn(context);
              },
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
                      key: const Key('home-hero-card'),
                      height: cardHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
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
                                        errorBuilder: (_, _, _) =>
                                            const ColoredBox(
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
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        10,
                                        16,
                                        10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
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
                                                  0.35 +
                                                  (0.55 * _stubWidth.value),
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
                          Positioned(
                            top: 10,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _GradeDepthChip(
                                  signedIn: session.isSignedIn,
                                  memberGrade: stats.memberGrade,
                                  isInstructor: stats.isInstructor,
                                ),
                                const LanguageSwitch(),
                              ],
                            ),
                          ),
                        ],
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
  final VoidCallback onAuth;
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
  const _SloganBlock({required this.title, required this.subtitle});

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

class _GradeDepthChip extends StatelessWidget {
  const _GradeDepthChip({
    required this.signedIn,
    required this.memberGrade,
    required this.isInstructor,
  });

  final bool signedIn;
  final MemberGrade memberGrade;
  final bool isInstructor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grade = signedIn
        ? ProfileDisplayGrade.fromMember(
            grade: memberGrade,
            isInstructor: isInstructor,
          )
        : null;
    final (emoji, label) = switch (grade) {
      null => ('🌊', 'SURFACE · 0m'),
      ProfileDisplayGrade.silver => ('🥈', 'SILVER · 10m'),
      ProfileDisplayGrade.gold => ('🥇', 'GOLD · 18m'),
      ProfileDisplayGrade.diamond => ('💎', 'DIAMOND · 30m'),
      ProfileDisplayGrade.platinum => ('💠', 'PLATINUM · 40m'),
      ProfileDisplayGrade.instructor => ('🎓', 'INSTRUCTOR'),
    };
    final semanticsLabel = switch (grade) {
      null => l10n.authLogin,
      ProfileDisplayGrade.silver => l10n.profileGradeSilver,
      ProfileDisplayGrade.gold => l10n.profileGradeGold,
      ProfileDisplayGrade.diamond => l10n.profileGradeDiamond,
      ProfileDisplayGrade.platinum => l10n.profileGradePlatinum,
      ProfileDisplayGrade.instructor => l10n.profileGradeInstructor,
    };
    return Semantics(
      key: const Key('home-grade-chip'),
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (!signedIn) {
            await ensureSignedIn(context);
            return;
          }
          if (isInstructor) {
            MainShell.goToTab(context, 4);
            return;
          }
          final host = context;
          await showModalBottomSheet<void>(
            context: host,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (sheetContext) => _DepthLadderSheet(
              onViewMembership: () {
                Navigator.of(sheetContext).pop();
                MainShell.goToTab(host, 4);
              },
            ),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xCC0B1F33),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.85)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 13, height: 1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        height: 1,
                        color: AppTheme.goldSoft.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepthLadderSheet extends StatelessWidget {
  const _DepthLadderSheet({required this.onViewMembership});

  final VoidCallback onViewMembership;

  static const _bands =
      <
        ({
          int meters,
          Color color,
          String koDepth,
          String enDepth,
          String koScene,
          String enScene,
        })
      >[
        (
          meters: 0,
          color: Color(0xFFD9F0FA),
          koDepth: '수면',
          enDepth: 'Surface',
          koScene: '출발 전, 아직 물 위',
          enScene: 'Before the dive, still on the surface',
        ),
        (
          meters: 10,
          color: Color(0xFFB7DDF3),
          koDepth: '10m',
          enDepth: '10m',
          koScene: '햇빛이 닿는 산호 정원',
          enScene: 'A sunlit coral garden',
        ),
        (
          meters: 18,
          color: Color(0xFF6AA6D4),
          koDepth: '18m',
          enDepth: '18m',
          koScene: '거북이와 만나는 푸른 바다',
          enScene: 'Blue water and sea turtles',
        ),
        (
          meters: 30,
          color: Color(0xFF1F5C92),
          koDepth: '30m',
          enDepth: '30m',
          koScene: '난파선과 대형 어류의 세계',
          enScene: 'Wrecks and big fish',
        ),
        (
          meters: 40,
          color: Color(0xFF0B2744),
          koDepth: '40m',
          enDepth: '40m',
          koScene: '고요한 심해, 가장 깊은 곳',
          enScene: 'The quiet deep, the deepest place',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final stats = DiverStoreScope.of(context).stats;
    final grade = stats.memberGrade;
    final hereMeters = switch (grade) {
      MemberGrade.silver => 10,
      MemberGrade.gold => 18,
      MemberGrade.diamond => 30,
      MemberGrade.platinum => 40,
    };
    final nextMeters = switch (grade) {
      MemberGrade.silver => 18,
      MemberGrade.gold => 30,
      MemberGrade.diamond => 40,
      MemberGrade.platinum => null,
    };
    final remaining = MemberGrade.deficitToNext(
      current: grade,
      paidPurchases: stats.paidPurchaseCount,
      reviews: 0,
    ).$1;
    final footer = nextMeters == null
        ? (ko ? '가장 깊은 바다에 도착했어요' : "You've reached the deepest sea")
        : (ko
              ? '다음 수심 ${nextMeters}m까지 예약 $remaining회 남았어요'
              : '$remaining more ${remaining == 1 ? 'booking' : 'bookings'} to reach ${nextMeters}m');
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _bands.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _DepthBand(
                  band: _bands[i],
                  ko: ko,
                  here: _bands[i].meters == hereMeters,
                ),
              ],
              const SizedBox(height: 14),
              Text(
                footer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onViewMembership,
                child: Text(ko ? '내 멤버십 보기' : 'View my membership'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepthBand extends StatelessWidget {
  const _DepthBand({required this.band, required this.ko, required this.here});

  final ({
    int meters,
    Color color,
    String koDepth,
    String enDepth,
    String koScene,
    String enScene,
  })
  band;
  final bool ko;
  final bool here;

  @override
  Widget build(BuildContext context) {
    final ink = band.color.computeLuminance() > 0.45
        ? AppTheme.navy
        : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: band.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: here ? AppTheme.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Text(
              ko ? band.koDepth : band.enDepth,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ko ? band.koScene : band.enScene,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
            if (here) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ko ? '● 지금 여기' : '● You are here',
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
            ],
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
