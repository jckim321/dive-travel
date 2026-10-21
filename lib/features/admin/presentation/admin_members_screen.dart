import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _MemberGradeFilter {
  all,
  needsAction,
  member,
  special,
  vip,
  instructor,
}

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({
    super.key,
    this.embedded = false,
    this.onOpenInstructors,
  });

  final bool embedded;
  final VoidCallback? onOpenInstructors;

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _query = TextEditingController();
  _MemberGradeFilter _gradeFilter = _MemberGradeFilter.all;

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
        return pendingUids.contains(member.uid) || member.isBusiness;
      case _MemberGradeFilter.member:
        return member.grade == MemberGrade.member;
      case _MemberGradeFilter.special:
        return member.grade == MemberGrade.special;
      case _MemberGradeFilter.vip:
        return member.grade == MemberGrade.vip;
      case _MemberGradeFilter.instructor:
        return member.grade == MemberGrade.instructor || member.isInstructor;
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
                member.email.toLowerCase().contains(needle)) &&
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
                  l10n.adminMembersSubDivers,
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
                  key: const Key('admin-members-needs-action-banner'),
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
                      _MemberGradeFilter.member,
                      memberGradeLabel(l10n, MemberGrade.member),
                    ),
                    (
                      _MemberGradeFilter.special,
                      memberGradeLabel(l10n, MemberGrade.special),
                    ),
                    (
                      _MemberGradeFilter.vip,
                      memberGradeLabel(l10n, MemberGrade.vip),
                    ),
                    (
                      _MemberGradeFilter.instructor,
                      memberGradeLabel(l10n, MemberGrade.instructor),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? Center(child: Text(l10n.adminMembersEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _MemberCard(member: members[index]);
                    },
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
                if (member.isInstructor ||
                    member.grade == MemberGrade.instructor)
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
            if (member.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(member.email, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
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
          ],
        ),
      ),
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

String memberGradeLabel(AppLocalizations l10n, MemberGrade grade) {
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
