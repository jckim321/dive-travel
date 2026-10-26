import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
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
    return switch (_filter) {
      _MemberFilter.all => true,
      _MemberFilter.silver => member.grade == MemberGrade.silver,
      _MemberFilter.gold => member.grade == MemberGrade.gold,
      _MemberFilter.diamond => member.grade == MemberGrade.diamond,
      _MemberFilter.platinum => member.grade == MemberGrade.platinum,
      _MemberFilter.instructor => member.isInstructor,
      _MemberFilter.partner => member.isBusiness,
      _MemberFilter.admin => member.isAdmin,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final q = _query.text.trim().toLowerCase();
        final all = store.members;
        final visible = [
          for (final member in all)
            if (_inFilter(member) && _matchesQuery(member, q)) member,
        ];
        final missing = [for (final m in visible) if (m.missingProfile) m];
        return Material(
          color: AdminConsoleTheme.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(embedded: widget.embedded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    _CountGrid(
                      members: all,
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
                          '오른쪽에서 등급·역할을 바꿔요',
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
                        hintText: '이름·아이디로 찾기',
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

bool _matchesQuery(MemberAccount member, String q) {
  if (q.isEmpty) return true;
  return member.displayName.toLowerCase().contains(q) ||
      member.loginId.toLowerCase().contains(q) ||
      member.uid.toLowerCase().contains(q);
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
    final cards = <_StatSpec>[
      _StatSpec(_MemberFilter.all, '전체', Icons.circle_outlined, Colors.white, members.length),
      _StatSpec(_MemberFilter.silver, '실버', Icons.diamond_outlined, const Color(0xFFD5DEE8), members.where((m) => m.grade == MemberGrade.silver).length),
      _StatSpec(_MemberFilter.gold, '골드', Icons.diamond, const Color(0xFFE2B15A), members.where((m) => m.grade == MemberGrade.gold).length),
      _StatSpec(_MemberFilter.diamond, '다이아몬드', Icons.diamond_outlined, const Color(0xFF7EC8FF), members.where((m) => m.grade == MemberGrade.diamond).length),
      _StatSpec(_MemberFilter.platinum, '플래티넘', Icons.diamond_outlined, const Color(0xFFC9B6FF), members.where((m) => m.grade == MemberGrade.platinum).length),
      _StatSpec(_MemberFilter.instructor, '강사', Icons.school_outlined, const Color(0xFF7DDEA0), members.where((m) => m.isInstructor).length),
      _StatSpec(_MemberFilter.partner, '제휴파트너', Icons.storefront_outlined, AdminConsoleTheme.aqua, members.where((m) => m.isBusiness).length),
      _StatSpec(_MemberFilter.admin, '관리자', Icons.favorite_border, const Color(0xFFFFB15A), members.where((m) => m.isAdmin).length),
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
  const _MemberRow({required this.member, required this.onOpen});

  final MemberAccount member;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = member.displayName.trim().isEmpty
        ? '?'
        : member.displayName.trim().characters.first;
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
                      child: Text(
                        member.displayName.trim().isEmpty ? '(이름 없음)' : member.displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
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
        const PopupMenuItem(enabled: false, child: Text('등급', style: TextStyle(color: AdminConsoleTheme.muted, fontSize: 12))),
        for (final grade in MemberGrade.valuesInOrder)
          PopupMenuItem(
            value: _MenuChoice.grade(grade),
            child: Row(
              children: [
                Expanded(child: Text(memberGradeLabel(l10n, grade), style: TextStyle(color: grade == MemberGrade.gold ? const Color(0xFFE2B15A) : AdminConsoleTheme.ice))),
                if (member.grade == grade) const Icon(Icons.check, size: 16, color: AdminConsoleTheme.muted),
              ],
            ),
          ),
        const PopupMenuItem(enabled: false, child: Text('역할', style: TextStyle(color: AdminConsoleTheme.muted, fontSize: 12))),
        PopupMenuItem(
          value: const _MenuChoice.instructor(),
          child: Text(member.isInstructor ? '강사 해제' : '강사', style: const TextStyle(color: Color(0xFF7DDEA0))),
        ),
        PopupMenuItem(
          key: Key('admin-member-promote-${member.uid}'),
          value: const _MenuChoice.partner(),
          child: Text(
            member.isBusiness ? '제휴파트너 해제' : '제휴파트너',
            style: const TextStyle(color: AdminConsoleTheme.aqua),
          ),
        ),
        PopupMenuItem(
          key: Key('admin-member-admin-${member.uid}'),
          value: const _MenuChoice.admin(),
          child: Text(
            member.isAdmin ? '관리자 해제' : '관리자',
            style: const TextStyle(color: Color(0xFFFFB15A)),
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
            Text(memberGradeLabel(l10n, member.grade), style: const TextStyle(color: Colors.white, fontSize: 12)),
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
          await store.setMemberGrade(uid: member.uid, grade: choice.grade!);
        case _ChoiceKind.instructor:
          if (member.isInstructor) {
            await store.rejectInstructor(member.uid);
          } else {
            await store.approveInstructor(member.uid);
          }
        case _ChoiceKind.partner:
          if (member.isBusiness) {
            await _confirmDemote(context, store, member);
          } else {
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
    await store.promoteMemberToPartner(uid: member.uid, shopId: result.shopId!);
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
                            Text(memberGradeLabel(AppLocalizations.of(context), shown.grade), style: const TextStyle(color: Color(0xFFE2B15A))),
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
                      const Text('계정 관리', style: TextStyle(color: AdminConsoleTheme.muted)),
                      const SizedBox(height: 8),
                      _actionTile(
                        key: Key('admin-member-block-${shown.uid}'),
                        icon: Icons.pause_circle_outline,
                        title: shown.accountBlocked ? '차단 해제' : '차단하기',
                        subtitle: '로그인을 막아요. 언제든 풀 수 있어요.',
                        color: const Color(0xFFE2B15A),
                        onTap: () async {
                          try {
                            await store.setAccountBlocked(
                              uid: shown.uid,
                              blocked: !shown.accountBlocked,
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('반영하지 못해서 이전 상태로 되돌렸어요.'),
                              ),
                            );
                          }
                        },
                      ),
                      _actionTile(
                        key: Key('admin-member-withdraw-${shown.uid}'),
                        icon: Icons.waving_hand_outlined,
                        title: '탈퇴 처리',
                        subtitle: '이름·연락처를 지우고 예약 기록만 남겨요.',
                        color: const Color(0xFFE2B15A),
                        onTap: shown.withdrawnAt != null
                            ? null
                            : () async {
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
                                if (ok == true) {
                                  try {
                                    await store.withdrawMember(shown.uid);
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('반영하지 못해서 이전 상태로 되돌렸어요.'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      _actionTile(
                        key: Key('admin-member-delete-${shown.uid}'),
                        icon: Icons.delete_outline,
                        title: '삭제하기',
                        subtitle: '계정과 정보를 완전히 지워요. 되돌릴 수 없어요.',
                        color: AdminConsoleTheme.danger,
                        onTap: null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '역할(제휴파트너·관리자·강사)은 위 목록의 등급·역할 칸에서 바꿔요.',
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
