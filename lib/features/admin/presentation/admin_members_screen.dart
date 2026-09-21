import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final needle = _query.text.trim().toLowerCase();
    final members = [
      for (final member in store.members)
        if (needle.isEmpty ||
            member.displayName.toLowerCase().contains(needle) ||
            member.email.toLowerCase().contains(needle))
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            Text(member.displayName, style: theme.textTheme.titleMedium),
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
