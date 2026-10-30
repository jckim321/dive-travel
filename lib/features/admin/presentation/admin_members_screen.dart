import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/partner_provision.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/models/shop_hull_id.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _MemberFilter { all, silver, gold, diamond, platinum, instructor, partner, admin }

/// 회원 관리. 파트너 상품 화면으로는 이동하지 않습니다.
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
  var _filter = _MemberFilter.all;

  @override
  void initState() {
    super.initState();
    _applyFocus(widget.focusUid);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = DiverStoreScope.of(context);
      unawaited(store.ensureAdminInboxLoaded());
      unawaited(store.ensureShopStatsLoaded());
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
    if (focus.isEmpty) return;
    _query.text = focus;
    _filter = _MemberFilter.all;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _inFilter(MemberAccount member) {
    if (_filter == _MemberFilter.all) return true;
    return memberRosterBucket(member) == _filter;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final q = _query.text.trim().toLowerCase();
        final active = [
          for (final member in store.members)
            if (!member.loginBlocked) member,
        ];
        final visible = [
          for (final member in active)
            if (_inFilter(member) &&
                _matchesQuery(
                  member,
                  q,
                  memberResortName(member, store.shopStats),
                ))
              member,
        ]..sort(compareMembersByRecentLogin);
        final missing = [for (final m in visible) if (m.missingProfile) m];
        final pending = store.pendingInstructors;
        final pendingUids = {for (final item in pending) item.uid};
        return Material(
          color: AdminConsoleTheme.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(embedded: widget.embedded),
              if (pending.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Material(
                    color: const Color(0xFF3D3218),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: const Key('admin-members-pending-banner'),
                      onTap: widget.onOpenInstructors,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text(
                          '강사 인증 대기 ${pending.length}건 ›',
                          key: const Key('admin-members-pending-banner-label'),
                          style: const TextStyle(
                            color: Color(0xFFE2B15A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    _CountGrid(
                      members: active,
                      filter: _filter,
                      onSelect: (filter) => setState(() => _filter = filter),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          '${_filterLabel(_filter)} ${visible.length}명',
                          style: const TextStyle(
                            color: Color(0xFFE2B15A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '오른쪽에서 구분을 바꿔요',
                          style: TextStyle(
                            color: AdminConsoleTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('admin-members-search'),
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: AdminConsoleTheme.text),
                      decoration: InputDecoration(
                        hintText: '이름·아이디·리조트·이메일로 찾기',
                        hintStyle: const TextStyle(color: AdminConsoleTheme.muted),
                        prefixIcon: const Icon(Icons.search, color: AdminConsoleTheme.muted),
                        filled: true,
                        fillColor: AdminConsoleTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminConsoleTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminConsoleTheme.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        key: const Key('admin-create-partner'),
                        onPressed: () => _openCreatePartner(context, store),
                        child: const Text('제휴파트너 만들기'),
                      ),
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Material(
                        color: const Color(0xFF3D3218),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '프로필이 없는 계정이 있어요.',
                                  style: TextStyle(color: AdminConsoleTheme.amber, fontSize: 13),
                                ),
                              ),
                              TextButton(
                                key: const Key('admin-member-make-profile'),
                                onPressed: () async {
                                  for (final member in missing) {
                                    await store.ensureMemberProfile(member);
                                  }
                                },
                                child: const Text('프로필 만들기'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    for (final member in visible)
                      _MemberRow(
                        member: member,
                        resortName: memberResortName(member, store.shopStats),
                        pendingVerification: pendingUids.contains(member.uid),
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminMemberDetailScreen(uid: member.uid),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      '이름을 누르면 상세 화면 (차단·탈퇴)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
                    ),
                  ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 줄의 구분과 같다. 관리자, 제휴파트너, 강사, 그다음 구매자 등급.
_MemberFilter memberRosterBucket(MemberAccount member) {
  if (member.isAdmin) return _MemberFilter.admin;
  if (member.isBusiness) return _MemberFilter.partner;
  if (member.isInstructor) return _MemberFilter.instructor;
  return switch (member.grade) {
    MemberGrade.silver => _MemberFilter.silver,
    MemberGrade.gold => _MemberFilter.gold,
    MemberGrade.diamond => _MemberFilter.diamond,
    MemberGrade.platinum => _MemberFilter.platinum,
  };
}

/// 연결된 리조트의 저장된 이름. 없거나 이름이 비어 있으면 빈 문자열.
String memberResortName(MemberAccount member, List<ShopLiveStats> shops) {
  final id = member.ownedShopId.trim();
  if (id.isEmpty) return '';
  for (final shop in shops) {
    if (shop.shopId == id) {
      return (shop.name ?? '').trim();
    }
  }
  return '';
}

bool _matchesQuery(MemberAccount member, String q, String resortName) {
  if (q.isEmpty) return true;
  final resort = resortName.trim().toLowerCase();
  return member.displayName.toLowerCase().contains(q) ||
      member.loginId.toLowerCase().contains(q) ||
      member.listHandle.toLowerCase().contains(q) ||
      member.email.toLowerCase().contains(q) ||
      member.uid.toLowerCase().contains(q) ||
      (resort.isNotEmpty && resort.contains(q));
}

String _filterLabel(_MemberFilter filter) {
  return switch (filter) {
    _MemberFilter.all => '전체',
    _MemberFilter.silver => '실버',
    _MemberFilter.gold => '골드',
    _MemberFilter.diamond => '다이아몬드',
    _MemberFilter.platinum => '플래티넘',
    _MemberFilter.instructor => '강사',
    _MemberFilter.partner => '제휴파트너',
    _MemberFilter.admin => '관리자',
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          if (!embedded)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            )
          else
            const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '회원 관리',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE2B15A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '+ 회원 추가',
                key: Key('admin-member-add'),
                style: TextStyle(
                  color: Color(0xFF1A1408),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({
    required this.members,
    required this.filter,
    required this.onSelect,
  });

  final List<MemberAccount> members;
  final _MemberFilter filter;
  final ValueChanged<_MemberFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    int bucketCount(_MemberFilter filter) {
      return members.where((member) => memberRosterBucket(member) == filter).length;
    }

    final cards = <_StatSpec>[
      _StatSpec(_MemberFilter.all, '전체', Icons.circle_outlined, Colors.white, members.length),
      _StatSpec(_MemberFilter.silver, '실버', Icons.diamond_outlined, const Color(0xFFD5DEE8), bucketCount(_MemberFilter.silver)),
      _StatSpec(_MemberFilter.gold, '골드', Icons.diamond, const Color(0xFFE2B15A), bucketCount(_MemberFilter.gold)),
      _StatSpec(_MemberFilter.diamond, '다이아몬드', Icons.diamond_outlined, const Color(0xFF7EC8FF), bucketCount(_MemberFilter.diamond)),
      _StatSpec(_MemberFilter.platinum, '플래티넘', Icons.diamond_outlined, const Color(0xFFC9B6FF), bucketCount(_MemberFilter.platinum)),
      _StatSpec(_MemberFilter.instructor, '강사', Icons.school_outlined, const Color(0xFF7DDEA0), bucketCount(_MemberFilter.instructor)),
      _StatSpec(_MemberFilter.partner, '제휴파트너', Icons.storefront_outlined, AdminConsoleTheme.aqua, bucketCount(_MemberFilter.partner)),
      _StatSpec(_MemberFilter.admin, '관리자', Icons.favorite_border, const Color(0xFFFFB15A), bucketCount(_MemberFilter.admin)),
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
          _StatCard(
            spec: card,
            selected: filter == card.filter,
            onTap: () => onSelect(card.filter),
          ),
      ],
    );
  }
}

class _StatSpec {
  const _StatSpec(this.filter, this.label, this.icon, this.color, this.count);
  final _MemberFilter filter;
  final String label;
  final IconData icon;
  final Color color;
  final int count;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _StatSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('admin-member-filter-${spec.filter.name}'),
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
              Icon(spec.icon, size: 14, color: spec.color),
              const SizedBox(height: 4),
              Text(
                '${spec.count}',
                style: TextStyle(
                  color: spec.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                spec.label,
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

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.onOpen,
    this.resortName = '',
    this.pendingVerification = false,
  });

  final MemberAccount member;
  final VoidCallback onOpen;
  final String resortName;
  final bool pendingVerification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final handle = member.listHandle;
    final placeholder = member.nameIsPlaceholder;
    final title = placeholder
        ? (handle.isEmpty ? '(이름 없음)' : handle)
        : member.displayName.trim();
    final initial = title == '(이름 없음)' ? '?' : title.characters.first;
    final showHandle = !placeholder && handle.isNotEmpty;
    final partner = memberRosterBucket(member) == _MemberFilter.partner;
    final resort = resortName.trim();
    final subtitle = partner && resort.isNotEmpty
        ? (handle.isEmpty ? resort : '$handle · $resort')
        : (showHandle ? handle : '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: Key('admin-member-open-${member.uid}'),
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _avatarColor(member.uid),
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            key: Key('admin-member-name-${member.uid}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              key: Key('admin-member-login-${member.uid}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminConsoleTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (pendingVerification) ...[
                      const SizedBox(width: 6),
                      Text(
                        '인증 대기',
                        key: Key('admin-member-pending-${member.uid}'),
                        style: const TextStyle(
                          color: Color(0xFFE2B15A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (member.loginBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A2430),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminConsoleTheme.danger),
                        ),
                        child: Text(
                          member.withdrawnAt != null ? '탈퇴' : '차단됨',
                          key: Key('admin-member-blocked-${member.uid}'),
                          style: const TextStyle(color: AdminConsoleTheme.danger, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!member.loginBlocked) ...[
            const SizedBox(width: 8),
            _RoleMenu(member: member, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

Color _avatarColor(String uid) {
  const colors = [
    Color(0xFF1F8A8A),
    Color(0xFFC4A15A),
    Color(0xFF3D7EBF),
    Color(0xFF7A4E9A),
    Color(0xFF2E8B57),
  ];
  return colors[uid.hashCode.abs() % colors.length];
}

class _RoleMenu extends StatelessWidget {
  const _RoleMenu({required this.member, required this.l10n});

  final MemberAccount member;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuChoice>(
      key: Key('admin-member-menu-${member.uid}'),
      color: const Color(0xFF152033),
      onSelected: (choice) => _onChoice(context, choice),
      itemBuilder: (context) => [
        for (final grade in MemberGrade.valuesInOrder)
          PopupMenuItem(
            key: Key('admin-member-grade-${grade.name}-${member.uid}'),
            value: _MenuChoice.grade(grade),
            child: _KindRow(
              label: memberGradeLabel(l10n, grade),
              color: grade == MemberGrade.gold
                  ? const Color(0xFFE2B15A)
                  : AdminConsoleTheme.ice,
              selected: _kindSelected(member, _MenuChoice.grade(grade)),
            ),
          ),
        PopupMenuItem(
          key: Key('admin-member-grade-instructor-${member.uid}'),
          value: const _MenuChoice.instructor(),
          child: _KindRow(
            label: '강사',
            color: const Color(0xFF7DDEA0),
            selected: _kindSelected(member, const _MenuChoice.instructor()),
          ),
        ),
        PopupMenuItem(
          key: Key('admin-member-promote-${member.uid}'),
          value: const _MenuChoice.partner(),
          child: _KindRow(
            label: '제휴파트너',
            color: AdminConsoleTheme.aqua,
            selected: _kindSelected(member, const _MenuChoice.partner()),
          ),
        ),
        PopupMenuItem(
          key: Key('admin-member-admin-${member.uid}'),
          value: const _MenuChoice.admin(),
          child: _KindRow(
            label: '관리자',
            color: const Color(0xFFFFB15A),
            selected: _kindSelected(member, const _MenuChoice.admin()),
          ),
        ),
        const PopupMenuItem(
          enabled: false,
          child: Text('등급을 직접 바꾸면 자동 승급이 멈춰요', style: TextStyle(color: AdminConsoleTheme.muted, fontSize: 11)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AdminConsoleTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminConsoleTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              memberShownGradeLabel(l10n, member),
              key: Key('admin-member-shown-grade-${member.uid}'),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _onChoice(BuildContext context, _MenuChoice choice) async {
    final store = DiverStoreScope.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      switch (choice.kind) {
        case _ChoiceKind.grade:
          if (member.isBusiness) {
            await _confirmDemote(context, store, member);
          } else {
            final next = choice.grade!;
            if (member.isInstructor) {
              await store.rejectInstructor(member.uid);
            }
            if (!member.isInstructor || next != member.grade) {
              await store.setMemberGrade(uid: member.uid, grade: next);
            }
          }
        case _ChoiceKind.instructor:
          if (member.isInstructor) {
            await store.rejectInstructor(member.uid);
          } else {
            await store.approveInstructor(member.uid);
          }
        case _ChoiceKind.partner:
          if (!member.isBusiness) {
            await _confirmPromote(context, store, member);
          }
        case _ChoiceKind.admin:
          await _confirmAdmin(context, store, member);
      }
    } catch (error) {
      if (!context.mounted) return;
      final text = error.toString();
      final message = text.contains('ADMIN_SELF')
          ? '본인 관리자 권한은 해제할 수 없어요.'
          : text.contains('ADMIN_LAST')
              ? '마지막 관리자는 해제할 수 없어요.'
              : text.contains('ALREADY_PARTNER')
                  ? l10n.adminMembersAlreadyPartner
                  : text.contains('SHOP_ALREADY_OWNED')
                      ? l10n.adminMembersShopOwned
                      : l10n.adminMembersPromoteFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

enum _ChoiceKind { grade, instructor, partner, admin }

class _MenuChoice {
  const _MenuChoice.grade(this.grade) : kind = _ChoiceKind.grade;
  const _MenuChoice.instructor() : kind = _ChoiceKind.instructor, grade = null;
  const _MenuChoice.partner() : kind = _ChoiceKind.partner, grade = null;
  const _MenuChoice.admin() : kind = _ChoiceKind.admin, grade = null;
  final _ChoiceKind kind;
  final MemberGrade? grade;
}

Future<void> _confirmPromote(BuildContext context, DiverStore store, MemberAccount member) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<_PromoteChoice>(
    context: context,
    builder: (ctx) => _PromotePartnerDialog(
      memberName: member.displayName,
      unownedShops: store.unownedPartnerShops,
    ),
  );
  if (result == null || !context.mounted) return;
  if (result.createNew) {
    await store.promoteMemberToPartnerWithNewShop(uid: member.uid, shopName: result.newShopName!);
  } else {
    await store.promoteMemberToPartner(
      uid: member.uid,
      shopId: partnerShopHull(result.shopId!),
    );
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminMembersPromoteDone)));
}

Future<void> _confirmDemote(BuildContext context, DiverStore store, MemberAccount member) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.adminMembersDemotePartner),
      content: Text(l10n.adminMembersDemoteConfirm(member.displayName, member.ownedShopId.isEmpty ? '—' : member.ownedShopId)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.adminHqClose)),
        FilledButton(
          key: Key('admin-member-demote-confirm-${member.uid}'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.adminMembersDemotePartner),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await store.demoteMemberFromPartner(member.uid);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminMembersDemoteDone)));
}

Future<void> _confirmAdmin(BuildContext context, DiverStore store, MemberAccount member) async {
  final grant = !member.isAdmin;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(grant ? '관리자로 지정' : '관리자 해제'),
      content: Text(grant ? '${member.displayName} 님을 관리자로 지정할까요?' : '${member.displayName} 님의 관리자 권한을 해제할까요?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
        FilledButton(
          key: Key('admin-member-admin-confirm-${member.uid}'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('확인'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await store.setMemberAdmin(uid: member.uid, admin: grant);
}

class AdminMemberDetailScreen extends StatelessWidget {
  const AdminMemberDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final store = DiverStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        MemberAccount? member;
        for (final item in store.members) {
          if (item.uid == uid) member = item;
        }
        final shown = member;
        return Scaffold(
          key: const Key('admin-member-detail'),
          backgroundColor: AdminConsoleTheme.bg,
          body: SafeArea(
            child: shown == null
                ? const Center(child: Text('회원을 찾을 수 없어요', style: TextStyle(color: Colors.white)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                          ),
                          const Text('회원 상세', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _detailCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _avatarColor(shown.uid),
                              child: Text(
                                shown.displayName.trim().isEmpty ? '?' : shown.displayName.trim().characters.first,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shown.displayName.trim().isEmpty ? '(이름 없음)' : shown.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  Text(
                                    shown.loginId.isEmpty ? shown.email : '아이디 ${shown.loginId}',
                                    style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(memberShownGradeLabel(AppLocalizations.of(context), shown), style: const TextStyle(color: Color(0xFFE2B15A))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailCard(
                        child: Column(
                          children: [
                            _infoRow('가입일', _when(shown.createdAt)),
                            _infoRow('최근 로그인', _when(shown.lastSeenAt)),
                            _infoRow('예약', '${shown.paidPurchaseCount}건'),
                            _infoRow('국적', shown.nationality.isEmpty ? '미입력' : nationalityNameKo(shown.nationality)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (shown.ownedShopId.contains('--')) ...[
                        _actionTile(
                          key: Key('admin-member-fix-hull-${shown.uid}'),
                          icon: Icons.storefront_outlined,
                          title: '샵을 hull로 고치기',
                          subtitle: shown.ownedShopId,
                          color: AdminConsoleTheme.aqua,
                          onTap: () => _confirmFixHull(context, store, shown),
                        ),
                      ],
                      const Text('계정 관리', style: TextStyle(color: AdminConsoleTheme.muted)),
                      const SizedBox(height: 8),
                      ..._accountActions(context, store, shown),
                      const SizedBox(height: 12),
                      const Text(
                        '구분은 위 목록의 칸에서 바꿔요.',
                        style: TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

List<Widget> _accountActions(
  BuildContext context,
  DiverStore store,
  MemberAccount shown,
) {
  final l10n = AppLocalizations.of(context);
  final self = store.uid == shown.uid;
  final linked = shown.ownedShopId.trim().isNotEmpty;
  final deletedAt = shown.deletedAt;
  if (deletedAt != null) {
    final days = memberPurgeDaysRemaining(deletedAt, DateTime.now());
    return [
      Text(
        days == 0
            ? l10n.adminMemberPurgeDue
            : l10n.adminMemberPurgeRemaining(days),
        key: Key('admin-member-purge-days-${shown.uid}'),
        style: const TextStyle(color: AdminConsoleTheme.muted),
      ),
      const SizedBox(height: 8),
      _actionTile(
        key: Key('admin-member-restore-${shown.uid}'),
        icon: Icons.restore,
        title: l10n.adminMemberRestore,
        subtitle: l10n.adminMemberRestoreSubtitle,
        color: AdminConsoleTheme.aqua,
        onTap: () async {
          try {
            await store.restoreDeletedMember(shown.uid);
            if (context.mounted) Navigator.pop(context);
          } catch (error) {
            _showClosureError(context, error);
          }
        },
      ),
    ];
  }
  if (shown.withdrawnAt != null) {
    return [
      Text(
        l10n.adminMemberWithdrawnOnly,
        key: Key('admin-member-withdrawn-only-${shown.uid}'),
        style: const TextStyle(color: AdminConsoleTheme.muted),
      ),
    ];
  }
  if (shown.accountBlocked) {
    return [
      if (self)
        Text(
          l10n.adminMemberSelfDenied,
          key: Key('admin-member-self-denied-${shown.uid}'),
          style: const TextStyle(color: AdminConsoleTheme.danger, fontSize: 12),
        ),
      _actionTile(
        key: Key('admin-member-block-${shown.uid}'),
        icon: Icons.pause_circle_outline,
        title: '차단 해제',
        subtitle: '로그인을 다시 허용해요.',
        color: const Color(0xFFE2B15A),
        onTap: self
            ? null
            : () async {
                try {
                  await store.setAccountBlocked(uid: shown.uid, blocked: false);
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  _showClosureError(context, error);
                }
              },
      ),
    ];
  }
  return [
    if (self)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          l10n.adminMemberSelfDenied,
          key: Key('admin-member-self-denied-${shown.uid}'),
          style: const TextStyle(color: AdminConsoleTheme.danger, fontSize: 12),
        ),
      ),
    if (!self && linked)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          l10n.adminMemberShopLinked,
          key: Key('admin-member-shop-linked-${shown.uid}'),
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
        ),
      ),
    _actionTile(
      key: Key('admin-member-block-${shown.uid}'),
      icon: Icons.pause_circle_outline,
      title: '차단하기',
      subtitle: '로그인을 막아요. 언제든 풀 수 있어요.',
      color: const Color(0xFFE2B15A),
      onTap: self
          ? null
          : () async {
              try {
                await store.setAccountBlocked(uid: shown.uid, blocked: true);
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                _showClosureError(context, error);
              }
            },
    ),
    _actionTile(
      key: Key('admin-member-withdraw-${shown.uid}'),
      icon: Icons.waving_hand_outlined,
      title: '탈퇴 처리',
      subtitle: '이름·연락처를 지우고 예약 기록만 남겨요.',
      color: const Color(0xFFE2B15A),
      onTap: self || linked ? null : () => _confirmWithdraw(context, store, shown),
    ),
    _actionTile(
      key: Key('admin-member-delete-${shown.uid}'),
      icon: Icons.delete_outline,
      title: '삭제하기',
      subtitle: l10n.adminMemberDeleteSubtitle,
      color: AdminConsoleTheme.danger,
      onTap: self || linked ? null : () => _confirmSoftDelete(context, store, shown),
    ),
  ];
}

void _showClosureError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final text = error.toString();
  final message = text.contains('ADMIN_SELF')
      ? l10n.adminMemberSelfDenied
      : text.contains('SHOP_LINKED')
          ? l10n.adminMemberShopLinked
          : '반영하지 못해서 이전 상태로 되돌렸어요.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _confirmWithdraw(
  BuildContext context,
  DiverStore store,
  MemberAccount shown,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('탈퇴 처리'),
      content: const Text('이름과 연락처를 지웁니다. 예약 기록은 남습니다.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
        FilledButton(
          key: Key('admin-member-withdraw-confirm-${shown.uid}'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('탈퇴 처리'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await store.withdrawMember(shown.uid);
    if (context.mounted) Navigator.pop(context);
  } catch (error) {
    if (!context.mounted) return;
    _showClosureError(context, error);
  }
}

Future<void> _confirmSoftDelete(
  BuildContext context,
  DiverStore store,
  MemberAccount shown,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.adminMemberDeleteTitle),
      content: Text(l10n.adminMemberDeleteBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
        FilledButton(
          key: Key('admin-member-delete-confirm-${shown.uid}'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.adminMemberDeleteConfirm),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await store.softDeleteMember(shown.uid);
    if (context.mounted) Navigator.pop(context);
  } catch (error) {
    if (!context.mounted) return;
    _showClosureError(context, error);
  }
}

Widget _detailCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AdminConsoleTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdminConsoleTheme.border),
    ),
    child: child,
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: AdminConsoleTheme.muted)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

String _when(DateTime? time) {
  if (time == null) return '—';
  final local = time.toLocal();
  final now = DateTime.now();
  if (local.year == now.year && local.month == now.month && local.day == now.day) {
    return '오늘';
  }
  return '${local.month}월 ${local.day}일';
}

Widget _actionTile({
  required Key key,
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AdminConsoleTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        key: key,
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    ),
  );
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
  const _PromotePartnerDialog({required this.memberName, required this.unownedShops});
  final String memberName;
  final List<DiveShop> unownedShops;
  @override
  State<_PromotePartnerDialog> createState() => _PromotePartnerDialogState();
}

class _PromotePartnerDialogState extends State<_PromotePartnerDialog> {
  var _mode = 0;
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
                ButtonSegment(value: 0, label: Text(l10n.adminMembersPromotePickShop), enabled: widget.unownedShops.isNotEmpty),
                ButtonSegment(value: 1, label: Text(l10n.adminMembersPromoteNewShop)),
              ],
              selected: {_mode},
              onSelectionChanged: (set) => setState(() => _mode = set.first),
            ),
            const SizedBox(height: 12),
            if (_mode == 0)
              DropdownButtonFormField<String>(
                key: const Key('admin-promote-shop'),
                initialValue: _shopId,
                items: [
                  for (final shop in widget.unownedShops)
                    DropdownMenuItem(value: shop.id, child: Text('${shop.name} (${shop.id})')),
                ],
                onChanged: (value) => setState(() => _shopId = value),
              )
            else
              TextField(
                key: const Key('admin-promote-new-shop-name'),
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.adminMembersNewShopName),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.adminHqClose)),
        FilledButton(
          key: const Key('admin-promote-confirm'),
          onPressed: () {
            if (_mode == 0) {
              final id = _shopId;
              if (id == null || id.isEmpty) return;
              Navigator.pop(context, _PromoteChoice.existing(id));
              return;
            }
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, _PromoteChoice.create(name));
          },
          child: Text(l10n.adminMembersPromotePartner),
        ),
      ],
    );
  }
}

String memberShownGradeLabel(AppLocalizations l10n, MemberAccount member) {
  if (member.isAdmin) {
    return '관리자';
  }
  if (member.isBusiness) {
    return '제휴파트너';
  }
  if (member.isInstructor) {
    return l10n.profileGradeInstructor;
  }
  return memberGradeLabel(l10n, member.grade);
}

bool _kindSelected(MemberAccount member, _MenuChoice choice) {
  final bucket = memberRosterBucket(member);
  return switch (choice.kind) {
    _ChoiceKind.admin => bucket == _MemberFilter.admin,
    _ChoiceKind.partner => bucket == _MemberFilter.partner,
    _ChoiceKind.instructor => bucket == _MemberFilter.instructor,
    _ChoiceKind.grade => switch (choice.grade) {
        MemberGrade.silver => bucket == _MemberFilter.silver,
        MemberGrade.gold => bucket == _MemberFilter.gold,
        MemberGrade.diamond => bucket == _MemberFilter.diamond,
        MemberGrade.platinum => bucket == _MemberFilter.platinum,
        null => false,
      },
  };
}

class _KindRow extends StatelessWidget {
  const _KindRow({
    required this.label,
    required this.color,
    required this.selected,
  });

  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: color))),
        if (selected)
          const Icon(Icons.check, size: 16, color: AdminConsoleTheme.muted),
      ],
    );
  }
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

Future<void> _openCreatePartner(BuildContext context, DiverStore store) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _CreatePartnerDialog(store: store),
  );
}

Future<void> _confirmFixHull(
  BuildContext context,
  DiverStore store,
  MemberAccount member,
) async {
  final prefix = partnerShopHull(member.ownedShopId);
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => _FixHullDialog(prefix: prefix, shops: store.resortHulls),
  );
  if (picked == null || !context.mounted) return;
  try {
    await store.fixPartnerShopHull(uid: member.uid, shopId: picked);
  } catch (error) {
    if (!context.mounted) return;
    final code = error is StateError ? '${error.message}' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_provisionMessage(code))),
    );
  }
}

String _provisionMessage(String code) {
  return switch (code) {
    'ADMIN_SESSION_LOST' => '관리자 로그인이 바뀌어 멈췄어요.',
    'SHOP_ALREADY_OWNED' => '이미 다른 파트너가 쓰는 샵이에요.',
    'ALREADY_PARTNER' => '이미 다른 샵의 파트너예요.',
    'WEAK_PASSWORD' => '비밀번호는 6자 이상이어야 해요.',
    'SHOP_NAME_REQUIRED' => '샵 이름을 입력해 주세요.',
    'LOGIN_ID_EMPTY' ||
    'LOGIN_ID_RESERVED' ||
    'LOGIN_ID_FORMAT' ||
    'LOGIN_ID_TOO_LONG' => '아이디를 확인해 주세요.',
    'PROMOTE_FAILED' => '파트너 지정에 실패했어요. 같은 아이디로 다시 누르면 지정만 이어 갑니다.',
    _ => '만들지 못했어요. 다시 시도해 주세요.',
  };
}

/// Step, error code, and message shown in the create-partner dialog.
String partnerCreateFailureText(PartnerProvisionFailure error) {
  final step = switch (error.step) {
    PartnerProvisionStep.shop => '샵 만들기',
    PartnerProvisionStep.account => '로그인 계정 만들기',
    PartnerProvisionStep.link => '회원 연결',
    PartnerProvisionStep.none => '',
  };
  final friendly = _provisionMessage(error.code);
  final generic = friendly.startsWith('만들지 못했어요');
  final lines = <String>[
    if (step.isNotEmpty) step,
    if (!generic) friendly,
    if (error.code.isNotEmpty) error.code,
    if (error.message.isNotEmpty &&
        error.message != error.code &&
        error.message != friendly)
      error.message,
  ];
  if (lines.isEmpty) {
    return friendly;
  }
  return lines.join('\n');
}

class _CreatePartnerDialog extends StatefulWidget {
  const _CreatePartnerDialog({required this.store});

  final DiverStore store;

  @override
  State<_CreatePartnerDialog> createState() => _CreatePartnerDialogState();
}

class _CreatePartnerDialogState extends State<_CreatePartnerDialog> {
  final _shop = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _done = false;
  var _existing = false;
  String? _error;
  String? _failure;
  String _loginShown = '';
  String _passwordShown = '';
  var _copied = false;
  List<ShopHullChoice> _choices = const [];
  String? _pickedDocId;

  @override
  void dispose() {
    _shop.dispose();
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _ready =>
      _shop.text.trim().isNotEmpty &&
      _login.text.trim().isNotEmpty &&
      _password.text.length >= 6;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final picked = _pickedDocId == null
        ? null
        : _choices
            .where((choice) => choice.documentId == _pickedDocId)
            .map((choice) => choice.hullId)
            .firstOrNull;
    try {
      final result = await widget.store.provisionPartnerAccount(
        shopName: _shop.text,
        loginId: _login.text,
        password: _password.text,
        hullId: picked,
      );
      if (!mounted) return;
      if (result.needsChoice) {
        setState(() {
          _choices = result.choices;
          _pickedDocId = result.choices.first.documentId;
          _busy = false;
        });
        return;
      }
      setState(() {
        _done = true;
        _existing = !result.createdAccount;
        _loginShown = result.loginId;
        _passwordShown = result.createdAccount ? result.password : '';
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      final failure = PartnerProvisionFailure.wrap(error);
      final detail = partnerCreateFailureText(failure);
      setState(() {
        _busy = false;
        if (failure.accountCreated) {
          _done = true;
          _loginShown = AuthIdentity.storedLoginId(_login.text);
          _passwordShown = _password.text;
          _failure = '계정은 만들어졌어요. 회원 연결은 실패했어요.\n$detail';
        } else {
          _error = detail;
        }
      });
    }
  }

  Future<void> _copy() async {
    final text = _passwordShown.isEmpty
        ? _loginShown
        : '$_loginShown\n$_passwordShown';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_done ? '만들어졌어요' : '제휴파트너 만들기'),
      content: SingleChildScrollView(
        child: _done ? _card() : _form(),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(_done ? '닫기' : '취소'),
        ),
        if (!_done)
          FilledButton(
            key: const Key('admin-create-partner-submit'),
            onPressed: _busy || !_ready ? null : _submit,
            child: Text(_choices.isEmpty ? '만들기' : '이 샵으로 만들기'),
          ),
      ],
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('admin-create-partner-shop'),
          controller: _shop,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: '샵 이름'),
        ),
        TextField(
          key: const Key('admin-create-partner-login'),
          controller: _login,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: '아이디'),
        ),
        TextField(
          key: const Key('admin-create-partner-password'),
          controller: _password,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: '임시 비밀번호'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('admin-create-partner-generate'),
            onPressed: () {
              _password.text = generatePartnerPassword();
              setState(() {});
            },
            child: const Text('자동 생성'),
          ),
        ),
        if (_choices.isNotEmpty) ...[
          const Text('같은 이름의 샵이 여러 개예요. 하나를 고르세요.'),
          for (final choice in _choices)
            RadioListTile<String>(
              key: Key('admin-partner-choice-${choice.documentId}'),
              value: choice.documentId,
              groupValue: _pickedDocId,
              onChanged: (value) => setState(() => _pickedDocId = value),
              title: Text('${choice.name} (${choice.hullId})'),
            ),
        ],
        if (_error != null)
          Text(
            _error!,
            key: const Key('admin-create-partner-error'),
            style: const TextStyle(color: AdminConsoleTheme.danger),
          ),
      ],
    );
  }

  Widget _card() {
    return Column(
      key: const Key('admin-create-partner-card'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_failure != null)
          Text(
            _failure!,
            key: const Key('admin-create-partner-failure'),
            style: const TextStyle(color: AdminConsoleTheme.danger),
          ),
        Text('아이디 $_loginShown'),
        if (_passwordShown.isNotEmpty) Text('임시 비밀번호 $_passwordShown'),
        if (_existing)
          const Text(
            '이미 있는 아이디예요, 비밀번호는 바뀌지 않아요',
            key: Key('admin-create-partner-existing'),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('admin-create-partner-copy'),
            onPressed: _copy,
            child: Text(_copied ? '복사했어요' : '복사'),
          ),
        ),
      ],
    );
  }
}

class _FixHullDialog extends StatefulWidget {
  const _FixHullDialog({required this.prefix, required this.shops});

  final String prefix;
  final List<DiveShop> shops;

  @override
  State<_FixHullDialog> createState() => _FixHullDialogState();
}

class _FixHullDialogState extends State<_FixHullDialog> {
  late String _hull = widget.prefix;

  @override
  Widget build(BuildContext context) {
    final options = <String>{
      widget.prefix,
      for (final shop in widget.shops) shop.hullId,
    }.where((id) => id.isNotEmpty && !id.contains('--'));
    return AlertDialog(
      title: const Text('샵을 hull로 고치기'),
      content: DropdownButtonFormField<String>(
        key: const Key('admin-fix-hull-shop'),
        initialValue: _hull,
        items: [
          for (final id in options)
            DropdownMenuItem(value: id, child: Text(id)),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _hull = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          key: const Key('admin-fix-hull-confirm'),
          onPressed: () => Navigator.pop(context, _hull),
          child: const Text('고치기'),
        ),
      ],
    );
  }
}
