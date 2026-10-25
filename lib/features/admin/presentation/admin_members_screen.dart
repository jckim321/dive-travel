import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _MemberGradeFilter {
  all,
  needsAction,
  silver,
  gold,
  diamond,
  platinum,
  instructor,
}

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({
    super.key,
    this.embedded = false,
    this.onOpenInstructors,
    this.focusUid,
    this.focusGeneration = 0,
  });

  final bool embedded;
  final VoidCallback? onOpenInstructors;
  final String? focusUid;
  final int focusGeneration;

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _query = TextEditingController();
  _MemberGradeFilter _gradeFilter = _MemberGradeFilter.all;

  @override
  void initState() {
    super.initState();
    _applyFocus(widget.focusUid);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureAdminInboxLoaded());
    });
  }

  @override
  void didUpdateWidget(AdminMembersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusGeneration != oldWidget.focusGeneration) {
      _applyFocus(widget.focusUid);
    }
  }

  void _applyFocus(String? uid) {
    final focus = uid?.trim() ?? '';
    if (focus.isEmpty) {
      return;
    }
    _query.text = focus;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matchesGrade(MemberAccount member, Set<String> pendingUids) {
    switch (_gradeFilter) {
      case _MemberGradeFilter.all:
        return true;
      case _MemberGradeFilter.needsAction:
        return pendingUids.contains(member.uid);
      case _MemberGradeFilter.silver:
        return !member.isInstructor && member.grade == MemberGrade.silver;
      case _MemberGradeFilter.gold:
        return !member.isInstructor && member.grade == MemberGrade.gold;
      case _MemberGradeFilter.diamond:
        return !member.isInstructor && member.grade == MemberGrade.diamond;
      case _MemberGradeFilter.platinum:
        return !member.isInstructor && member.grade == MemberGrade.platinum;
      case _MemberGradeFilter.instructor:
        return member.isInstructor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final needle = _query.text.trim().toLowerCase();
    final pendingUids = {
      for (final p in store.pendingInstructors) p.uid,
    };
    final members = [
      for (final member in store.members)
        if ((needle.isEmpty ||
                member.displayName.toLowerCase().contains(needle) ||
                member.email.toLowerCase().contains(needle) ||
                member.loginId.toLowerCase().contains(needle) ||
                member.uid.toLowerCase().contains(needle) ||
                member.ownedShopId.toLowerCase().contains(needle)) &&
            _matchesGrade(member, pendingUids))
          member,
    ];

    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.adminMembersTitle,
      body: Column(
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.adminMembersTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          if (store.pendingInstructors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Material(
                color: AdminConsoleTheme.danger.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const Key('admin-menu-instructors'),
                  onTap: widget.onOpenInstructors,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: AdminConsoleTheme.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.adminMembersNeedsActionHint(
                              store.pendingInstructors.length,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          l10n.adminPartnerOpenInstructors,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AdminConsoleTheme.aqua,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: const Key('admin-members-search'),
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminMembersSearch,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in <(_MemberGradeFilter, String)>[
                    (_MemberGradeFilter.all, l10n.adminMembersGradeAll),
                    (
                      _MemberGradeFilter.needsAction,
                      l10n.adminMembersNeedsAction,
                    ),
                    (
                      _MemberGradeFilter.silver,
                      memberGradeLabel(l10n, MemberGrade.silver),
                    ),
                  ]) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        key: Key('admin-member-grade-${entry.$1.name}'),
                        label: Text(entry.$2),
                        selected: _gradeFilter == entry.$1,
                        onSelected: (_) =>
                            setState(() => _gradeFilter = entry.$1),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PopupMenuButton<_MemberGradeFilter>(
                      key: const Key('admin-member-grade-more'),
                      tooltip: l10n.adminFilterMore,
                      onSelected: (value) =>
                          setState(() => _gradeFilter = value),
                      itemBuilder: (context) => [
                        for (final entry in <(_MemberGradeFilter, String)>[
                          (
                            _MemberGradeFilter.gold,
                            memberGradeLabel(l10n, MemberGrade.gold),
                          ),
                          (
                            _MemberGradeFilter.diamond,
                            memberGradeLabel(l10n, MemberGrade.diamond),
                          ),
                          (
                            _MemberGradeFilter.platinum,
                            memberGradeLabel(l10n, MemberGrade.platinum),
                          ),
                          (
                            _MemberGradeFilter.instructor,
                            l10n.profileGradeInstructor,
                          ),
                        ])
                          PopupMenuItem(
                            value: entry.$1,
                            child: Text(entry.$2),
                          ),
                      ],
                      child: Chip(
                        label: Text(
                          {
                                _MemberGradeFilter.gold,
                                _MemberGradeFilter.diamond,
                                _MemberGradeFilter.platinum,
                                _MemberGradeFilter.instructor,
                              }.contains(_gradeFilter)
                              ? switch (_gradeFilter) {
                                  _MemberGradeFilter.gold => memberGradeLabel(
                                    l10n,
                                    MemberGrade.gold,
                                  ),
                                  _MemberGradeFilter.diamond =>
                                    memberGradeLabel(
                                      l10n,
                                      MemberGrade.diamond,
                                    ),
                                  _MemberGradeFilter.instructor =>
                                    l10n.profileGradeInstructor,
                                  _ => memberGradeLabel(
                                    l10n,
                                    MemberGrade.platinum,
                                  ),
                                }
                              : l10n.adminFilterMore,
                        ),
                        avatar: const Icon(Icons.expand_more, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: store.refreshAdminInbox,
              child: members.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.35,
                          child: Center(child: Text(l10n.adminMembersEmpty)),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _MemberCard(member: members[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final MemberAccount member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final theme = Theme.of(context);
    final suggested = member.suggestedGrade;
    final leftoverHint = member.isAdmin && member.isBusiness;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    member.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (member.isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _RoleBadge(
                      label: l10n.adminMembersBadgeAdmin,
                      color: AdminConsoleTheme.aqua,
                    ),
                  ),
                if (member.isInstructor)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _RoleBadge(
                      label: l10n.adminMembersBadgeInstructor,
                      color: AdminConsoleTheme.ice,
                    ),
                  ),
                if (member.isBusiness)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _RoleBadge(
                      label: l10n.adminMembersBadgePartner,
                      color: AdminConsoleTheme.amber,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _displayGradeLabel(
                l10n,
                ProfileDisplayGrade.fromMember(
                  grade: member.grade,
                  isInstructor: member.isInstructor,
                ),
              ),
              key: Key('admin-member-display-grade-${member.uid}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AdminConsoleTheme.aqua,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (member.loginId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminMembersLoginId(member.loginId),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${l10n.profileNationality} · ${member.nationality.isEmpty ? l10n.profileNationalityEmpty : nationalityNameKo(member.nationality)}',
              key: Key('admin-member-nationality-${member.uid}'),
              style: theme.textTheme.bodySmall,
            ),
            if (member.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(member.email, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 6),
            Text(
              l10n.adminMembersRoleStatus(
                member.isAdmin
                    ? l10n.adminMembersRoleAdmin
                    : (member.isBusiness
                        ? l10n.adminMembersRolePartner
                        : l10n.adminMembersRoleDiver),
                member.userRole,
                member.ownedShopId.isEmpty ? '—' : member.ownedShopId,
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (leftoverHint) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminMembersLeftoverPartnerHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AdminConsoleTheme.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.adminMembersPurchasesReviews(
                member.paidPurchaseCount,
                member.reviewCount,
              ),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              l10n.adminMembersActivity(
                member.totalLogCount,
                member.uniqueRegionsCount,
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (suggested != member.grade) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminMembersSuggested(memberGradeLabel(l10n, suggested)),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (member.gradeLocked) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminMembersGradeLocked,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AdminConsoleTheme.amber,
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<MemberGrade>(
              key: Key('admin-member-grade-${member.uid}'),
              initialValue: member.grade,
              decoration: InputDecoration(
                labelText: l10n.adminMembersGrade,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final grade in MemberGrade.valuesInOrder)
                  DropdownMenuItem(
                    value: grade,
                    child: Text(memberGradeLabel(l10n, grade)),
                  ),
              ],
              onChanged: member.isAdmin
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      store.setMemberGrade(uid: member.uid, grade: value);
                    },
            ),
            if (member.gradeLocked && !member.isAdmin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: Key('admin-member-unlock-${member.uid}'),
                  onPressed: () => store.unlockMemberGrade(member.uid),
                  child: Text(l10n.adminMembersUnlockAuto),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (!member.isBusiness)
                  FilledButton.tonal(
                    key: Key('admin-member-promote-${member.uid}'),
                    onPressed: () => _confirmPromote(context, store, member),
                    child: Text(l10n.adminMembersPromotePartner),
                  ),
                if (member.isBusiness)
                  OutlinedButton(
                    key: Key('admin-member-demote-${member.uid}'),
                    onPressed: () => _confirmDemote(context, store, member),
                    child: Text(l10n.adminMembersDemotePartner),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPromote(
    BuildContext context,
    DiverStore store,
    MemberAccount member,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (member.isBusiness) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminMembersAlreadyPartner)),
      );
      return;
    }
    final unowned = store.unownedPartnerShops;
    final result = await showDialog<_PromoteChoice>(
      context: context,
      builder: (ctx) => _PromotePartnerDialog(
        memberName: member.displayName,
        unownedShops: unowned,
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }
    try {
      if (result.createNew) {
        await store.promoteMemberToPartnerWithNewShop(
          uid: member.uid,
          shopName: result.newShopName!,
        );
      } else {
        await store.promoteMemberToPartner(
          uid: member.uid,
          shopId: result.shopId!,
        );
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminMembersPromoteDone)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.toString().contains('ALREADY_PARTNER')
          ? l10n.adminMembersAlreadyPartner
          : error.toString().contains('SHOP_ALREADY_OWNED')
              ? l10n.adminMembersShopOwned
              : l10n.adminMembersPromoteFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _confirmDemote(
    BuildContext context,
    DiverStore store,
    MemberAccount member,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminMembersDemotePartner),
        content: Text(
          l10n.adminMembersDemoteConfirm(
            member.displayName,
            member.ownedShopId.isEmpty ? '—' : member.ownedShopId,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.adminHqClose),
          ),
          FilledButton(
            key: Key('admin-member-demote-confirm-${member.uid}'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminMembersDemotePartner),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await store.demoteMemberFromPartner(member.uid);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminMembersDemoteDone)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminMembersDemoteFailed)),
      );
    }
  }
}

class _PromoteChoice {
  const _PromoteChoice.existing(this.shopId)
      : createNew = false,
        newShopName = null;

  const _PromoteChoice.create(this.newShopName)
      : createNew = true,
        shopId = null;

  final bool createNew;
  final String? shopId;
  final String? newShopName;
}

class _PromotePartnerDialog extends StatefulWidget {
  const _PromotePartnerDialog({
    required this.memberName,
    required this.unownedShops,
  });

  final String memberName;
  final List<DiveShop> unownedShops;

  @override
  State<_PromotePartnerDialog> createState() => _PromotePartnerDialogState();
}

class _PromotePartnerDialogState extends State<_PromotePartnerDialog> {
  var _mode = 0; // 0 existing, 1 new
  String? _shopId;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.unownedShops.isNotEmpty) {
      _shopId = widget.unownedShops.first.id;
    } else {
      _mode = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminMembersPromotePartner),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminMembersPromoteConfirm(widget.memberName)),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(l10n.adminMembersPromotePickShop),
                  enabled: widget.unownedShops.isNotEmpty,
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(l10n.adminMembersPromoteNewShop),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) => setState(() => _mode = set.first),
            ),
            const SizedBox(height: 12),
            if (_mode == 0) ...[
              if (widget.unownedShops.isEmpty)
                Text(l10n.adminMembersNoUnownedShops)
              else
                DropdownButtonFormField<String>(
                  key: const Key('admin-promote-shop'),
                  initialValue: _shopId,
                  decoration: InputDecoration(
                    labelText: l10n.adminMembersPromotePickShop,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final shop in widget.unownedShops)
                      DropdownMenuItem(
                        value: shop.id,
                        child: Text('${shop.name} (${shop.id})'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _shopId = value),
                ),
            ] else
              TextField(
                key: const Key('admin-promote-new-shop-name'),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.adminMembersNewShopName,
                  border: const OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.adminHqClose),
        ),
        FilledButton(
          key: const Key('admin-promote-confirm'),
          onPressed: () {
            if (_mode == 0) {
              final id = _shopId;
              if (id == null || id.isEmpty) {
                return;
              }
              Navigator.pop(context, _PromoteChoice.existing(id));
              return;
            }
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.pop(context, _PromoteChoice.create(name));
          },
          child: Text(l10n.adminMembersPromotePartner),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

String _displayGradeLabel(AppLocalizations l10n, ProfileDisplayGrade grade) {
  return switch (grade) {
    ProfileDisplayGrade.silver => l10n.memberGradeSilver,
    ProfileDisplayGrade.gold => l10n.memberGradeGold,
    ProfileDisplayGrade.diamond => l10n.memberGradeDiamond,
    ProfileDisplayGrade.platinum => l10n.memberGradePlatinum,
    ProfileDisplayGrade.instructor => l10n.profileGradeInstructor,
  };
}

String memberGradeLabel(AppLocalizations l10n, MemberGrade grade) {
  switch (grade) {
    case MemberGrade.silver:
      return l10n.memberGradeSilver;
    case MemberGrade.gold:
      return l10n.memberGradeGold;
    case MemberGrade.diamond:
      return l10n.memberGradeDiamond;
    case MemberGrade.platinum:
      return l10n.memberGradePlatinum;
  }
}
