import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _ArchiveFilter { all, blocked, withdrawn, trash }

/// 차단, 탈퇴, 삭제된 회원. 활동 중 목록에는 나오지 않는다.
class AdminMembersArchiveScreen extends StatefulWidget {
  const AdminMembersArchiveScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminMembersArchiveScreen> createState() =>
      _AdminMembersArchiveScreenState();
}

class _AdminMembersArchiveScreenState extends State<AdminMembersArchiveScreen> {
  final _query = TextEditingController();
  var _filter = _ArchiveFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(DiverStoreScope.of(context).ensureAdminInboxLoaded());
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final archived = [
          for (final member in store.members)
            if (memberArchiveGroup(member) != null) member,
        ]..sort(compareMembersByRecentLogin);
        final q = _query.text.trim().toLowerCase();
        final visible = [
          for (final member in archived)
            if (_inFilter(member) && _matches(member, q)) member,
        ];
        return Material(
          color: AdminConsoleTheme.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l10n.adminMembersSubArchive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _ArchiveGrid(
                      members: archived,
                      filter: _filter,
                      l10n: l10n,
                      onSelect: (filter) => setState(() => _filter = filter),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('admin-archive-search'),
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: AdminConsoleTheme.text),
                      decoration: InputDecoration(
                        hintText: '이름·아이디·이메일로 찾기',
                        hintStyle: const TextStyle(color: AdminConsoleTheme.muted),
                        prefixIcon: const Icon(Icons.search, color: AdminConsoleTheme.muted),
                        filled: true,
                        fillColor: AdminConsoleTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminConsoleTheme.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final member in visible)
                      ListTile(
                        key: Key('admin-archive-row-${member.uid}'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminMemberDetailScreen(uid: member.uid),
                            ),
                          );
                        },
                        title: Text(
                          member.displayName.trim().isEmpty
                              ? member.listHandle.isEmpty
                                  ? member.uid
                                  : member.listHandle
                              : member.displayName,
                          key: Key('admin-member-name-${member.uid}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _groupLabel(l10n, memberArchiveGroup(member)!),
                          style: const TextStyle(color: AdminConsoleTheme.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _inFilter(MemberAccount member) {
    final group = memberArchiveGroup(member);
    return switch (_filter) {
      _ArchiveFilter.all => group != null,
      _ArchiveFilter.blocked => group == MemberArchiveGroup.blocked,
      _ArchiveFilter.withdrawn => group == MemberArchiveGroup.withdrawn,
      _ArchiveFilter.trash => group == MemberArchiveGroup.trash,
    };
  }
}

bool _matches(MemberAccount member, String q) {
  if (q.isEmpty) return true;
  return member.displayName.toLowerCase().contains(q) ||
      member.loginId.toLowerCase().contains(q) ||
      member.listHandle.toLowerCase().contains(q) ||
      member.email.toLowerCase().contains(q) ||
      member.uid.toLowerCase().contains(q);
}

String _groupLabel(AppLocalizations l10n, MemberArchiveGroup group) {
  return switch (group) {
    MemberArchiveGroup.blocked => l10n.adminMemberArchiveBlocked,
    MemberArchiveGroup.withdrawn => l10n.adminMemberArchiveWithdrawn,
    MemberArchiveGroup.trash => l10n.adminMemberArchiveTrash,
  };
}

class _ArchiveGrid extends StatelessWidget {
  const _ArchiveGrid({
    required this.members,
    required this.filter,
    required this.l10n,
    required this.onSelect,
  });

  final List<MemberAccount> members;
  final _ArchiveFilter filter;
  final AppLocalizations l10n;
  final ValueChanged<_ArchiveFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    int count(MemberArchiveGroup group) {
      return members.where((member) => memberArchiveGroup(member) == group).length;
    }

    final cards = [
      (filter: _ArchiveFilter.all, label: '전체', count: members.length),
      (
        filter: _ArchiveFilter.blocked,
        label: l10n.adminMemberArchiveBlocked,
        count: count(MemberArchiveGroup.blocked),
      ),
      (
        filter: _ArchiveFilter.withdrawn,
        label: l10n.adminMemberArchiveWithdrawn,
        count: count(MemberArchiveGroup.withdrawn),
      ),
      (
        filter: _ArchiveFilter.trash,
        label: l10n.adminMemberArchiveTrash,
        count: count(MemberArchiveGroup.trash),
      ),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      mainAxisExtent: 92,
      children: [
        for (final card in cards)
          _ArchiveCard(
            filterName: card.filter.name,
            label: card.label,
            count: card.count,
            selected: filter == card.filter,
            onTap: () => onSelect(card.filter),
          ),
      ],
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({
    required this.filterName,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String filterName;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('admin-archive-filter-$filterName'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFE2B15A) : AdminConsoleTheme.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
