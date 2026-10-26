import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/features/auth/presentation/device_pin_dialogs.dart';
import 'package:dive_travel_app/features/profile/presentation/nationality_field.dart';
import 'package:dive_travel_app/features/profile/presentation/partner_application_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/pro_verification_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final session = SessionScope.of(context);
    final pins = DevicePinScope.maybeOf(context);
    final email = session.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.seaMist,
      appBar: AppBar(title: Text(l10n.profileSettingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          store,
          if (pins != null) pins,
        ]),
        builder: (context, _) {
          final live = store.stats;
          final liveGrade = ProfileDisplayGrade.fromMember(
            grade: live.memberGrade,
            isInstructor: live.isInstructor,
          );
          return ListView(
            key: const Key('profile-settings-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _SettingsCard(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: live.displayName,
                      subtitle: email,
                    ),
                    const Divider(height: 28),
                    _SettingsRow(
                      icon: Icons.workspace_premium_outlined,
                      title: l10n.profileMembershipTitle,
                      subtitle: _useGradeLabel(l10n, liveGrade),
                    ),
                    const SizedBox(height: 16),
                    _GradeLadder(current: liveGrade),
                    const SizedBox(height: 10),
                    Text(
                      _nextGradeLine(l10n, live),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _NationalityCard(nationality: live.nationality),
              if (!live.isAdmin && !live.isBusiness) ...[
                const SizedBox(height: 16),
                _SettingsCard(
                  child: _SettingsAction(
                    key: const Key('profile-partner-apply'),
                    icon: Icons.storefront_outlined,
                    title: l10n.partnerApplyTitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PartnerApplicationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (live.isAdmin || live.isBusiness) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.profileWorkModeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: Column(
                    children: [
                      if (live.isAdmin)
                        _SettingsAction(
                          key: const Key('open-admin-mode'),
                          icon: Icons.admin_panel_settings_outlined,
                          title: l10n.adminMode,
                          onTap: () => openAdminMode(context),
                        ),
                      if (live.isAdmin && live.isBusiness)
                        const Divider(height: 1),
                      if (live.isBusiness)
                        _SettingsAction(
                          key: const Key('open-partner-mode'),
                          icon: Icons.storefront_outlined,
                          title: l10n.partnerTitle,
                          onTap: () => openPartnerMode(context),
                        ),
                    ],
                  ),
                ),
                if (pins != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.devicePinSettingsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    child: _SettingsAction(
                      key: const Key('device-pin-settings'),
                      icon: Icons.pin_outlined,
                      title: pins.hasPin && pins.pinnedUid == store.uid
                          ? l10n.devicePinSettingsChange
                          : l10n.devicePinSettingsSet,
                      subtitle: l10n.devicePinSettingsHint,
                      onTap: () async {
                        final uid = store.uid ?? session.user?.uid ?? '';
                        if (uid.isEmpty) return;
                        await showDevicePinSetupDialog(context, uid: uid);
                      },
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 28),
              OutlinedButton.icon(
                key: const Key('profile-sign-out'),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await session.signOut();
                  if (!context.mounted) return;
                  nav.popUntil((route) => route.isFirst);
                },
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
          );
        },
      ),
    );
  }
}

class _NationalityCard extends StatefulWidget {
  const _NationalityCard({required this.nationality});

  final String nationality;

  @override
  State<_NationalityCard> createState() => _NationalityCardState();
}

class _NationalityCardState extends State<_NationalityCard> {
  String? _selected;
  var _consent = false;
  var _busy = false;
  var _saving = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _selected = normalizeNationalityCode(widget.nationality);
  }

  @override
  void didUpdateWidget(_NationalityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nationality != widget.nationality) {
      _selected = normalizeNationalityCode(widget.nationality);
      _consent = false;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final code = _selected;
    if (code == null || _busy) {
      return;
    }
    if (!_consent) {
      setState(() => _notice = l10n.profileNationalityNeedConsent);
      return;
    }
    if (!await ensureSignedIn(context)) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _saving = true;
      _notice = null;
    });
    try {
      await DiverStoreScope.of(context).setNationality(code);
      if (!mounted) {
        return;
      }
      setState(() => _consent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('국적을 저장했어요')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _notice = '$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = false;
        });
      }
    }
  }

  Future<void> _clear() async {
    if (_busy || widget.nationality.isEmpty) {
      return;
    }
    if (!await ensureSignedIn(context)) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await DiverStoreScope.of(context).clearNationality();
      if (!mounted) {
        return;
      }
      setState(() {
        _selected = null;
        _consent = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('국적을 지웠어요')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _notice = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saved = normalizeNationalityCode(widget.nationality);
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileNationality,
            key: const Key('profile-nationality'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            saved == null ? l10n.profileNationalityEmpty : nationalityNameKo(saved),
            key: const Key('profile-nationality-current'),
          ),
          const SizedBox(height: 12),
          NationalityField(
            key: ValueKey('profile-nationality-${_selected ?? ''}'),
            fieldKey: const Key('profile-nationality-field'),
            value: _selected,
            onChanged: (code) => setState(() {
              _selected = code;
              if (code == null) {
                _consent = false;
              }
            }),
          ),
          if (_selected != null) ...[
            CheckboxListTile(
              key: const Key('profile-nationality-consent'),
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _consent = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(nationalityConsentKo),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('profile-nationality-save'),
                onPressed: _busy ? null : _save,
                child: _saving
                    ? const SizedBox(
                        key: Key('profile-nationality-saving'),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.profileNationalitySave),
              ),
            ),
          ],
          if (saved != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('profile-nationality-clear'),
                onPressed: _busy ? null : _clear,
                child: Text(l10n.profileNationalityClear),
              ),
            ),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 8),
            Text(
              _notice!,
              key: const Key('profile-nationality-notice'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
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
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.ocean),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
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
  if (stats.isInstructor) {
    return l10n.profileGradeShownAsInstructor;
  }
  if (stats.memberGrade == MemberGrade.platinum) {
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
    (ProfileDisplayGrade.instructor, '🎓'),
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
