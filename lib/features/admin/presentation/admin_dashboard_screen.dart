import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_instructors_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partners_roster_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_posts_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_pricing_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_home_curation_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_documents_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_same_boat_monitor_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_shops_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_bookings_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_contract_vault_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_contracts_overview_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_trial_data_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_weather_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_applications_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_form_import_screen.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_hub_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const double _kAdminWideBreakpoint = 900;

/// Primary IA hubs. [tools] is reached via More / tools chip only (phase-1 deferrals).
enum _AdminHub {
  overview,
  members,
  diveStar,
  products,
  bookings,
  contracts,
  settlement,
  sales,
  stats,
  reports,
  tools,
}

enum _MembersSub { general, partners, instructors }

enum _DiveStarSub { applications, review, forms }

enum _ProductsSub { catalog, seats, sameBoat, homeCuration }

enum _BookingsSub { list, paymentSoon, customersSoon, cancelSoon }

enum _ContractsSub { overview, vault, documents }

enum _SettlementSub { pricing, historySoon }

enum _ToolsSub {
  shopsMonitor,
  weather,
  posts,
  terms,
  inbox,
  trialData,
}

/// Dive Travel HQ 관리자 콘솔.
/// 상단 1차 탭 + 필요 시 2차 탭, 현황 탭에 KPI·대기 작업·등급 분포.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminHub _hub = _AdminHub.overview;
  _MembersSub _membersSub = _MembersSub.general;
  _DiveStarSub _diveStarSub = _DiveStarSub.applications;
  _ProductsSub _productsSub = _ProductsSub.catalog;
  _BookingsSub _bookingsSub = _BookingsSub.list;
  _ContractsSub _contractsSub = _ContractsSub.overview;
  _SettlementSub _settlementSub = _SettlementSub.pricing;
  _ToolsSub _toolsSub = _ToolsSub.shopsMonitor;
  String? _productsShopFilter;
  String? _contractsShopFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final store = DiverStoreScope.of(context);
      unawaited(store.ensureAdminInboxLoaded());
      unawaited(store.ensureCommunityPostsLoaded());
      unawaited(store.ensureShopStatsLoaded());
    });
  }

  void _go(_AdminHub hub, {Object? sub, String? shopFilter}) {
    setState(() {
      _hub = hub;
      if (hub == _AdminHub.members && sub is _MembersSub) {
        _membersSub = sub;
      }
      if (hub == _AdminHub.diveStar && sub is _DiveStarSub) {
        _diveStarSub = sub;
      }
      if (hub == _AdminHub.products && sub is _ProductsSub) {
        _productsSub = sub;
        if (sub == _ProductsSub.catalog) {
          _productsShopFilter = shopFilter;
        }
      }
      if (hub == _AdminHub.bookings && sub is _BookingsSub) {
        _bookingsSub = sub;
      }
      if (hub == _AdminHub.contracts && sub is _ContractsSub) {
        _contractsSub = sub;
        if (sub == _ContractsSub.vault) {
          _contractsShopFilter = shopFilter ?? _contractsShopFilter;
        }
      }
      if (hub == _AdminHub.settlement && sub is _SettlementSub) {
        _settlementSub = sub;
      }
      if (hub == _AdminHub.tools && sub is _ToolsSub) {
        _toolsSub = sub;
      }
    });
  }

  void _openShopProducts(String shopId) {
    _go(_AdminHub.products, sub: _ProductsSub.catalog, shopFilter: shopId);
  }

  void _openContractVault(String shopId) {
    _go(_AdminHub.contracts, sub: _ContractsSub.vault, shopFilter: shopId);
  }

  Future<void> _openMoreSheet(AppLocalizations l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AdminConsoleTheme.surfaceHigh,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            key: const Key('admin-nav-more-sheet'),
            children: [
              for (final entry in _moreHubEntries(l10n))
                ListTile(
                  key: entry.key,
                  leading: Icon(entry.icon, color: AdminConsoleTheme.aqua),
                  title: Text(entry.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _go(entry.hub, sub: entry.sub);
                  },
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.adminNavToolsSection,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final entry in _toolsEntries(l10n))
                ListTile(
                  key: entry.key,
                  leading: Icon(entry.icon, color: AdminConsoleTheme.muted),
                  title: Text(entry.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _go(_AdminHub.tools, sub: entry.sub);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<_MoreHubEntry> _moreHubEntries(AppLocalizations l10n) => [
        _MoreHubEntry(
          hub: _AdminHub.diveStar,
          label: l10n.adminTabDiveStar,
          icon: Icons.star_outline,
          key: const Key('admin-more-dive-star'),
        ),
        _MoreHubEntry(
          hub: _AdminHub.contracts,
          label: l10n.adminTabContracts,
          icon: Icons.gavel_outlined,
          key: const Key('admin-more-contracts'),
        ),
        _MoreHubEntry(
          hub: _AdminHub.settlement,
          label: l10n.adminTabSettlement,
          icon: Icons.percent,
          key: const Key('admin-more-settlement'),
          sub: _SettlementSub.pricing,
        ),
        _MoreHubEntry(
          hub: _AdminHub.sales,
          label: l10n.adminTabSales,
          icon: Icons.point_of_sale_outlined,
          key: const Key('admin-more-sales'),
        ),
        _MoreHubEntry(
          hub: _AdminHub.stats,
          label: l10n.adminTabStats,
          icon: Icons.insights_outlined,
          key: const Key('admin-more-stats'),
        ),
        _MoreHubEntry(
          hub: _AdminHub.reports,
          label: l10n.adminTabReports,
          icon: Icons.assessment_outlined,
          key: const Key('admin-more-reports'),
        ),
      ];

  List<_ToolEntry> _toolsEntries(AppLocalizations l10n) => [
        _ToolEntry(
          sub: _ToolsSub.shopsMonitor,
          label: l10n.adminShopsTitle,
          icon: Icons.storefront_outlined,
          key: const Key('admin-tool-shops'),
        ),
        _ToolEntry(
          sub: _ToolsSub.weather,
          label: l10n.weatherAdminTitle,
          icon: Icons.thunderstorm_outlined,
          key: const Key('admin-menu-weather'),
        ),
        _ToolEntry(
          sub: _ToolsSub.posts,
          label: l10n.adminPostsTitle,
          icon: Icons.forum_outlined,
          key: const Key('admin-tool-posts'),
        ),
        _ToolEntry(
          sub: _ToolsSub.terms,
          label: l10n.adminContractsSubTerms,
          icon: Icons.description_outlined,
          key: const Key('admin-sub-contracts-terms'),
        ),
        _ToolEntry(
          sub: _ToolsSub.inbox,
          label: l10n.adminContractsSubInbox,
          icon: Icons.inbox_outlined,
          key: const Key('admin-sub-contracts-inbox'),
        ),
        _ToolEntry(
          sub: _ToolsSub.trialData,
          label: l10n.adminTrialDataTab,
          icon: Icons.delete_sweep_outlined,
          key: const Key('admin-sub-trial-data'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final pending = store.pendingInstructors.length;
    final plaque = store.plaqueQueue.length;
    final hidden = store.posts.where((p) => p.hidden).length;
    final pendingProducts = store.pendingProductApprovals.length;

    return Theme(
      data: AdminConsoleTheme.dark,
      child: Builder(
        builder: (context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _kAdminWideBreakpoint;
              return Scaffold(
                key: Key(wide ? 'admin-layout-wide' : 'admin-layout-narrow'),
                backgroundColor: AdminConsoleTheme.bg,
                appBar: AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.adminHqTitle),
                      Text(
                        l10n.adminHqSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AdminConsoleTheme.muted,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (wide)
                      IconButton(
                        key: const Key('admin-nav-tools'),
                        tooltip: l10n.adminNavToolsSection,
                        onPressed: () => _openMoreSheet(l10n),
                        icon: const Icon(Icons.handyman_outlined),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        l10n.adminHqClose,
                        style: const TextStyle(
                          color: AdminConsoleTheme.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      _PrimaryTabStrip(
                        hub: _hub,
                        pendingCertify: pending,
                        pendingProducts: pendingProducts,
                        onSelect: _go,
                      ),
                    ..._subTabsFor(
                      l10n: l10n,
                      pending: pending,
                      plaque: plaque,
                      pendingProducts: pendingProducts,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(
                            '${_hub.name}-$_membersSub-$_diveStarSub-'
                            '$_productsSub-$_bookingsSub-$_contractsSub-'
                            '$_settlementSub-$_toolsSub',
                          ),
                          child: _bodyFor(
                            l10n: l10n,
                            store: store,
                            pending: pending,
                            plaque: plaque,
                            hidden: hidden,
                            pendingProducts: pendingProducts,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: wide
                    ? null
                    : _AdminBottomNav(
                        hub: _hub,
                        pendingCertify: pending,
                        pendingProducts: pendingProducts,
                        onSelect: _go,
                        onMore: () => _openMoreSheet(l10n),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _subTabsFor({
    required AppLocalizations l10n,
    required int pending,
    required int plaque,
    required int pendingProducts,
  }) {
    switch (_hub) {
      case _AdminHub.members:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminMembersSubGeneral,
              l10n.adminMembersSubPartners,
            ],
            keys: const [
              Key('admin-sub-divers'),
              Key('admin-sub-partners'),
            ],
            badges: [pending, plaque],
            selected: switch (_membersSub) {
              _MembersSub.partners => 1,
              _MembersSub.general || _MembersSub.instructors => 0,
            },
            onSelect: (i) => _go(
              _AdminHub.members,
              sub: i == 1 ? _MembersSub.partners : _MembersSub.general,
            ),
          ),
          if (_membersSub == _MembersSub.instructors)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: OutlinedButton.icon(
                key: const Key('admin-instructors-back'),
                onPressed: () =>
                    _go(_AdminHub.members, sub: _MembersSub.general),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(l10n.adminMembersSubGeneral),
              ),
            ),
        ];
      case _AdminHub.diveStar:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminDiveStarSubApplications,
              l10n.adminDiveStarSubReview,
              l10n.adminDiveStarSubForms,
            ],
            keys: const [
              Key('admin-sub-dive-star-apps'),
              Key('admin-sub-dive-star-review'),
              Key('admin-sub-dive-star-forms'),
            ],
            selected: switch (_diveStarSub) {
              _DiveStarSub.applications => 0,
              _DiveStarSub.review => 1,
              _DiveStarSub.forms => 2,
            },
            onSelect: (i) => _go(
              _AdminHub.diveStar,
              sub: switch (i) {
                1 => _DiveStarSub.review,
                2 => _DiveStarSub.forms,
                _ => _DiveStarSub.applications,
              },
            ),
          ),
        ];
      case _AdminHub.products:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminProductsTab,
              l10n.adminSameBoatApplyTab,
              l10n.adminSameBoatTab,
              l10n.adminHomeCurationTab,
            ],
            keys: const [
              Key('admin-sub-products'),
              Key('admin-sub-seats-apply'),
              Key('admin-sub-same-boat'),
              Key('admin-sub-home-curation'),
            ],
            badges: [pendingProducts, 0, 0, 0],
            selected: switch (_productsSub) {
              _ProductsSub.catalog => 0,
              _ProductsSub.seats => 1,
              _ProductsSub.sameBoat => 2,
              _ProductsSub.homeCuration => 3,
            },
            onSelect: (i) => _go(
              _AdminHub.products,
              sub: switch (i) {
                1 => _ProductsSub.seats,
                2 => _ProductsSub.sameBoat,
                3 => _ProductsSub.homeCuration,
                _ => _ProductsSub.catalog,
              },
            ),
          ),
        ];
      case _AdminHub.bookings:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminBookingsSubList,
              '${l10n.adminBookingsSubPayment} (${l10n.adminContractsComingSoon})',
              '${l10n.adminBookingsSubCustomers} (${l10n.adminContractsComingSoon})',
              '${l10n.adminBookingsSubCancel} (${l10n.adminContractsComingSoon})',
            ],
            keys: const [
              Key('admin-sub-bookings'),
              Key('admin-sub-bookings-payment'),
              Key('admin-sub-bookings-customers'),
              Key('admin-sub-bookings-cancel'),
            ],
            selected: switch (_bookingsSub) {
              _BookingsSub.list => 0,
              _BookingsSub.paymentSoon => 1,
              _BookingsSub.customersSoon => 2,
              _BookingsSub.cancelSoon => 3,
            },
            onSelect: (i) => _go(
              _AdminHub.bookings,
              sub: switch (i) {
                1 => _BookingsSub.paymentSoon,
                2 => _BookingsSub.customersSoon,
                3 => _BookingsSub.cancelSoon,
                _ => _BookingsSub.list,
              },
            ),
          ),
        ];
      case _AdminHub.contracts:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminContractsSubOverview,
              l10n.adminContractsSubVault,
              l10n.adminDocsTitle,
            ],
            keys: const [
              Key('admin-sub-contracts-overview'),
              Key('admin-sub-contracts-vault'),
              Key('admin-sub-documents'),
            ],
            selected: switch (_contractsSub) {
              _ContractsSub.overview => 0,
              _ContractsSub.vault => 1,
              _ContractsSub.documents => 2,
            },
            onSelect: (i) => _go(
              _AdminHub.contracts,
              sub: switch (i) {
                1 => _ContractsSub.vault,
                2 => _ContractsSub.documents,
                _ => _ContractsSub.overview,
              },
            ),
          ),
        ];
      case _AdminHub.settlement:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminSettlementSubPricing,
              '${l10n.adminSettlementSubHistory} (${l10n.adminContractsComingSoon})',
            ],
            keys: const [
              Key('admin-menu-pricing'),
              Key('admin-sub-settlement-history'),
            ],
            selected: switch (_settlementSub) {
              _SettlementSub.pricing => 0,
              _SettlementSub.historySoon => 1,
            },
            onSelect: (i) => _go(
              _AdminHub.settlement,
              sub: i == 1
                  ? _SettlementSub.historySoon
                  : _SettlementSub.pricing,
            ),
          ),
        ];
      case _AdminHub.tools:
        return [
          _SubTabStrip(
            labels: [
              l10n.adminShopsTitle,
              l10n.weatherAdminTitle,
              l10n.adminPostsCommunityShort,
              l10n.adminContractsSubTerms,
              l10n.adminContractsSubInbox,
              l10n.adminTrialDataTab,
            ],
            keys: const [
              Key('admin-sub-shops'),
              Key('admin-menu-weather'),
              Key('admin-sub-posts'),
              Key('admin-sub-contracts-terms'),
              Key('admin-sub-contracts-inbox'),
              Key('admin-sub-trial-data'),
            ],
            selected: switch (_toolsSub) {
              _ToolsSub.shopsMonitor => 0,
              _ToolsSub.weather => 1,
              _ToolsSub.posts => 2,
              _ToolsSub.terms => 3,
              _ToolsSub.inbox => 4,
              _ToolsSub.trialData => 5,
            },
            onSelect: (i) => _go(
              _AdminHub.tools,
              sub: switch (i) {
                1 => _ToolsSub.weather,
                2 => _ToolsSub.posts,
                3 => _ToolsSub.terms,
                4 => _ToolsSub.inbox,
                5 => _ToolsSub.trialData,
                _ => _ToolsSub.shopsMonitor,
              },
            ),
          ),
        ];
      case _AdminHub.overview:
      case _AdminHub.sales:
      case _AdminHub.stats:
      case _AdminHub.reports:
        return const [];
    }
  }

  Widget _bodyFor({
    required AppLocalizations l10n,
    required DiverStore store,
    required int pending,
    required int plaque,
    required int hidden,
    required int pendingProducts,
  }) {
    switch (_hub) {
      case _AdminHub.overview:
        return _OverviewPane(
          onJump: _go,
          memberCount: store.members.length,
          pendingCertify: pending,
          plaqueCount: plaque,
          postCount: store.posts.length,
          hiddenCount: hidden,
          shopCount: store.shops.length,
          pendingProducts: pendingProducts,
          members: store.members,
          salesByKind: store.salesThisMonthByKind(),
          salesTotal: store.salesTotalThisMonth,
          ops: store.adminOpsSnapshot(),
          publicProductCount: [
            for (final s in store.shops)
              for (final p in (store.liveStatsFor(s.hullId)?.products ??
                  store.liveStatsFor(s.id)?.products ??
                  const []))
                if (p.isListedPublicly) p,
          ].length,
        );
      case _AdminHub.members:
        return switch (_membersSub) {
          _MembersSub.general => AdminMembersScreen(
            embedded: true,
            onOpenInstructors: () =>
                _go(_AdminHub.members, sub: _MembersSub.instructors),
          ),
          _MembersSub.instructors =>
            const AdminInstructorsScreen(embedded: true),
          _MembersSub.partners => AdminPartnersRosterScreen(
            embedded: true,
            onOpenProducts: _openShopProducts,
          ),
        };
      case _AdminHub.diveStar:
        return switch (_diveStarSub) {
          _DiveStarSub.applications =>
            const AdminDiveStarApplicationsScreen(embedded: true),
          _DiveStarSub.review => AdminShopsScreen(
            embedded: true,
            onOpenProducts: _openShopProducts,
          ),
          _DiveStarSub.forms =>
            const AdminDiveStarFormImportScreen(embedded: true),
        };
      case _AdminHub.products:
        return switch (_productsSub) {
          _ProductsSub.catalog => AdminProductsScreen(
            embedded: true,
            filterShopId: _productsShopFilter,
            onClearShopFilter: () =>
                setState(() => _productsShopFilter = null),
          ),
          _ProductsSub.seats => const SameBoatSeatsHubScreen(
            embedded: true,
            adminBypassApproval: true,
            showSourceFilter: false,
            compactFilters: true,
          ),
          _ProductsSub.sameBoat => const AdminSameBoatMonitorScreen(
            embedded: true,
          ),
          _ProductsSub.homeCuration =>
            const AdminHomeCurationScreen(embedded: true),
        };
      case _AdminHub.bookings:
        return switch (_bookingsSub) {
          _BookingsSub.list => const AdminBookingsScreen(embedded: true),
          _BookingsSub.paymentSoon => _AdminComingSoonPane(
            title: l10n.adminBookingsSubPayment,
            body: l10n.adminContractsComingSoon,
          ),
          _BookingsSub.customersSoon => _AdminComingSoonPane(
            title: l10n.adminBookingsSubCustomers,
            body: l10n.adminContractsComingSoon,
          ),
          _BookingsSub.cancelSoon => _AdminComingSoonPane(
            title: l10n.adminBookingsSubCancel,
            body: l10n.adminContractsComingSoon,
          ),
        };
      case _AdminHub.contracts:
        return switch (_contractsSub) {
          _ContractsSub.overview => AdminContractsOverviewScreen(
            embedded: true,
            onOpenVault: _openContractVault,
          ),
          _ContractsSub.vault => AdminContractVaultScreen(
            embedded: true,
            initialShopId: _contractsShopFilter,
          ),
          _ContractsSub.documents =>
            const AdminPartnerDocumentsScreen(embedded: true),
        };
      case _AdminHub.settlement:
        return switch (_settlementSub) {
          _SettlementSub.pricing =>
            const AdminPricingScreen(embedded: true),
          _SettlementSub.historySoon => _AdminComingSoonPane(
            title: l10n.adminSettlementSubHistory,
            body: l10n.adminContractsComingSoon,
          ),
        };
      case _AdminHub.sales:
        return _AdminComingSoonPane(
          title: l10n.adminTabSales,
          body: l10n.adminContractsComingSoon,
        );
      case _AdminHub.stats:
        return _AdminComingSoonPane(
          title: l10n.adminTabStats,
          body: l10n.adminContractsComingSoon,
        );
      case _AdminHub.reports:
        return _AdminComingSoonPane(
          title: l10n.adminTabReports,
          body: l10n.adminContractsComingSoon,
        );
      case _AdminHub.tools:
        return switch (_toolsSub) {
          _ToolsSub.shopsMonitor => AdminShopsScreen(
            embedded: true,
            onOpenProducts: _openShopProducts,
          ),
          _ToolsSub.weather => const AdminWeatherScreen(embedded: true),
          _ToolsSub.posts => const AdminPostsScreen(embedded: true),
          _ToolsSub.terms => _AdminComingSoonPane(
            title: l10n.adminContractsSubTerms,
            body: l10n.adminContractsComingSoon,
          ),
          _ToolsSub.inbox => _AdminComingSoonPane(
            title: l10n.adminContractsSubInbox,
            body: l10n.adminContractsComingSoon,
          ),
          _ToolsSub.trialData =>
            const AdminTrialDataScreen(embedded: true),
        };
    }
  }
}

class _MoreHubEntry {
  const _MoreHubEntry({
    required this.hub,
    required this.label,
    required this.icon,
    required this.key,
    this.sub,
  });

  final _AdminHub hub;
  final String label;
  final IconData icon;
  final Key key;
  final Object? sub;
}

class _ToolEntry {
  const _ToolEntry({
    required this.sub,
    required this.label,
    required this.icon,
    required this.key,
  });

  final _ToolsSub sub;
  final String label;
  final IconData icon;
  final Key key;
}

class _PrimaryTabStrip extends StatelessWidget {
  const _PrimaryTabStrip({
    required this.hub,
    required this.pendingCertify,
    required this.pendingProducts,
    required this.onSelect,
  });

  final _AdminHub hub;
  final int pendingCertify;
  final int pendingProducts;
  final void Function(_AdminHub hub, {Object? sub, String? shopFilter})
  onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <(_AdminHub, IconData, String, int, Key)>[
      (
        _AdminHub.overview,
        Icons.dashboard_outlined,
        l10n.adminTabOverview,
        0,
        const Key('admin-tab-overview'),
      ),
      (
        _AdminHub.members,
        Icons.groups_outlined,
        l10n.adminTabMembers,
        pendingCertify,
        const Key('admin-menu-members'),
      ),
      (
        _AdminHub.diveStar,
        Icons.star_outline,
        l10n.adminTabDiveStar,
        0,
        const Key('admin-menu-dive-star'),
      ),
      (
        _AdminHub.products,
        Icons.inventory_2_outlined,
        l10n.adminTabProducts,
        pendingProducts,
        const Key('admin-menu-shops'),
      ),
      (
        _AdminHub.bookings,
        Icons.event_available_outlined,
        l10n.adminTabBookings,
        0,
        const Key('admin-menu-bookings'),
      ),
      (
        _AdminHub.contracts,
        Icons.gavel_outlined,
        l10n.adminTabContracts,
        0,
        const Key('admin-menu-contracts'),
      ),
      (
        _AdminHub.settlement,
        Icons.percent,
        l10n.adminTabSettlement,
        0,
        const Key('admin-menu-settlement'),
      ),
      (
        _AdminHub.sales,
        Icons.point_of_sale_outlined,
        l10n.adminTabSales,
        0,
        const Key('admin-menu-sales'),
      ),
      (
        _AdminHub.stats,
        Icons.insights_outlined,
        l10n.adminTabStats,
        0,
        const Key('admin-menu-stats'),
      ),
      (
        _AdminHub.reports,
        Icons.assessment_outlined,
        l10n.adminTabReports,
        0,
        const Key('admin-menu-reports'),
      ),
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (id, icon, label, badge, key) = tabs[index];
          final selected = hub == id;
          return _PrimaryTabChip(
            key: key,
            icon: icon,
            label: label,
            selected: selected,
            badge: badge,
            onTap: () => onSelect(id),
          );
        },
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({
    required this.hub,
    required this.pendingCertify,
    required this.pendingProducts,
    required this.onSelect,
    required this.onMore,
  });

  final _AdminHub hub;
  final int pendingCertify;
  final int pendingProducts;
  final void Function(_AdminHub hub, {Object? sub, String? shopFilter})
  onSelect;
  final VoidCallback onMore;

  static const _primary = {
    _AdminHub.overview,
    _AdminHub.bookings,
    _AdminHub.members,
    _AdminHub.products,
  };

  int get _index {
    return switch (hub) {
      _AdminHub.overview => 0,
      _AdminHub.bookings => 1,
      _AdminHub.members => 2,
      _AdminHub.products => 3,
      _ => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      key: const Key('admin-bottom-nav'),
      selectedIndex: _index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            onSelect(_AdminHub.overview);
          case 1:
            onSelect(_AdminHub.bookings);
          case 2:
            onSelect(_AdminHub.members);
          case 3:
            onSelect(_AdminHub.products);
          default:
            onMore();
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          label: l10n.adminTabOverview,
        ),
        NavigationDestination(
          icon: const Icon(Icons.event_available_outlined),
          label: l10n.adminTabBookings,
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: pendingCertify > 0,
            label: Text(pendingCertify > 9 ? '9+' : '$pendingCertify'),
            child: const Icon(Icons.groups_outlined),
          ),
          label: l10n.adminTabMembers,
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: pendingProducts > 0,
            label: Text(pendingProducts > 9 ? '9+' : '$pendingProducts'),
            child: const Icon(Icons.inventory_2_outlined),
          ),
          label: l10n.adminTabProducts,
        ),
        NavigationDestination(
          icon: Icon(
            Icons.more_horiz,
            color: !_primary.contains(hub) ? AdminConsoleTheme.aqua : null,
          ),
          label: l10n.adminNavMore,
        ),
      ],
    );
  }
}

class _AdminComingSoonPane extends StatelessWidget {
  const _AdminComingSoonPane({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AdminConsoleTheme.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(color: AdminConsoleTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryTabChip extends StatelessWidget {
  const _PrimaryTabChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AdminConsoleTheme.aqua.withValues(alpha: 0.16)
          : AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AdminConsoleTheme.aqua
                  : AdminConsoleTheme.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AdminConsoleTheme.aqua
                        : AdminConsoleTheme.muted,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AdminConsoleTheme.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AdminConsoleTheme.aqua
                      : AdminConsoleTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTabStrip extends StatelessWidget {
  const _SubTabStrip({
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.keys = const [],
    this.badges = const [],
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final List<Key> keys;
  final List<int> badges;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Material(
            color: selected == i
                ? AdminConsoleTheme.aqua
                : AdminConsoleTheme.surface,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              key: i < keys.length ? keys[i] : null,
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected == i
                            ? AdminConsoleTheme.bg
                            : AdminConsoleTheme.muted,
                      ),
                    ),
                    if (i < badges.length && badges[i] > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected == i
                              ? AdminConsoleTheme.bg
                              : AdminConsoleTheme.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badges[i] > 9 ? '9+' : '${badges[i]}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: selected == i
                                ? AdminConsoleTheme.aqua
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({
    required this.onJump,
    required this.memberCount,
    required this.pendingCertify,
    required this.plaqueCount,
    required this.postCount,
    required this.hiddenCount,
    required this.shopCount,
    required this.pendingProducts,
    required this.members,
    required this.salesByKind,
    required this.salesTotal,
    required this.ops,
    required this.publicProductCount,
  });

  final void Function(_AdminHub hub, {Object? sub, String? shopFilter}) onJump;
  final int memberCount;
  final int pendingCertify;
  final int plaqueCount;
  final int postCount;
  final int hiddenCount;
  final int shopCount;
  final int pendingProducts;
  final List<MemberAccount> members;
  final Map<String, int> salesByKind;
  final int salesTotal;
  final AdminOpsSnapshot ops;
  final int publicProductCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradeCounts = <MemberGrade, int>{
      for (final g in MemberGrade.valuesInOrder) g: 0,
    };
    for (final m in members) {
      gradeCounts[m.grade] = (gradeCounts[m.grade] ?? 0) + 1;
    }
    final conversionPct = (ops.conversionRate * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text(
          l10n.adminDashboardTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(l10n.adminDashboardSubtitle),
        const SizedBox(height: 16),
        _SectionHeader(
          icon: Icons.favorite_outline,
          title: l10n.adminPulseTitle,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _MetricCard(
              label: l10n.adminPulseSalesMonth,
              value: NumberFormat.compact(locale: 'ko').format(salesTotal),
              accent: AdminConsoleTheme.aqua,
            ),
            _MetricCard(
              label: l10n.adminPulseConversion,
              value: '$conversionPct%',
              accent: AdminConsoleTheme.ice,
              hint: l10n.adminPulseFunnelHint(
                ops.bookingPaid,
                ops.bookingRequested,
              ),
            ),
            _MetricCard(
              label: l10n.adminPulseNewWeek,
              value: '${ops.new7d}',
              accent: AdminConsoleTheme.amber,
              onTap: () =>
                  onJump(_AdminHub.members, sub: _MembersSub.general),
            ),
            _MetricCard(
              label: l10n.adminMetricPendingCert,
              value: '$pendingCertify',
              accent: pendingCertify > 0
                  ? AdminConsoleTheme.danger
                  : AdminConsoleTheme.ice,
              onTap: () =>
                  onJump(_AdminHub.members, sub: _MembersSub.instructors),
            ),
            _MetricCard(
              label: l10n.adminMetricMembers,
              value: '$memberCount',
              accent: AdminConsoleTheme.aqua,
              onTap: () =>
                  onJump(_AdminHub.members, sub: _MembersSub.general),
            ),
            _MetricCard(
              label: l10n.adminProductsTab,
              value: '$pendingProducts',
              accent: pendingProducts > 0
                  ? AdminConsoleTheme.danger
                  : AdminConsoleTheme.aqua,
              onTap: () =>
                  onJump(_AdminHub.products, sub: _ProductsSub.catalog),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.visibility_outlined,
          title: l10n.adminVisitsTitle,
        ),
        const SizedBox(height: 10),
        _StatRowCard(
          rows: [
            (l10n.adminVisitsDau, '${ops.seenToday}'),
            (l10n.adminVisitsWau, '${ops.seen7d}'),
            (l10n.adminVisitsMau, '${ops.seen30d}'),
            (l10n.adminVisitsDormant, '${ops.dormant}'),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.person_add_alt_1_outlined,
          title: l10n.adminNewMembersTitle,
        ),
        const SizedBox(height: 10),
        _StatRowCard(
          rows: [
            (l10n.adminNewMembersToday, '${ops.newToday}'),
            (l10n.adminNewMembersWeek, '${ops.new7d}'),
            (l10n.adminNewMembersMonth, '${ops.new30d}'),
            (
              l10n.adminNewMembersPaid,
              ops.new30d == 0
                  ? '—'
                  : '${((ops.newPaid30d / ops.new30d) * 100).round()}%',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.filter_alt_outlined,
          title: l10n.adminFunnelTitle,
        ),
        const SizedBox(height: 10),
        _StatRowCard(
          rows: [
            (l10n.adminFunnelRequested, '${ops.bookingRequested}'),
            (l10n.adminFunnelPaid, '${ops.bookingPaid}'),
            (l10n.adminFunnelCancelled, '${ops.bookingCancelled}'),
            (l10n.adminFunnelUnreviewed, '${ops.unpaidReviewCount}'),
          ],
        ),
        const SizedBox(height: 20),
        _SalesByKindCard(salesByKind: salesByKind),
        const SizedBox(height: 20),
        if (ops.nearUpgrade.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.trending_up,
            title: l10n.adminNearUpgradeTitle,
          ),
          const SizedBox(height: 10),
          for (final m in ops.nearUpgrade) ...[
            _NearUpgradeTile(member: m),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
        _SectionHeader(
          icon: Icons.inventory_2_outlined,
          title: l10n.adminProductSignalTitle,
        ),
        const SizedBox(height: 10),
        _StatRowCard(
          rows: [
            (l10n.adminProductSignalPublic, '$publicProductCount'),
            (l10n.adminProductSignalPending, '$pendingProducts'),
            (l10n.adminMetricPlaques, '$plaqueCount'),
            (l10n.adminProductSignalShops, '$shopCount'),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.bolt_outlined,
          title: l10n.adminAttentionTitle,
        ),
        const SizedBox(height: 10),
        if (pendingCertify == 0 &&
            plaqueCount == 0 &&
            hiddenCount == 0 &&
            pendingProducts == 0)
          _EmptyAttention(message: l10n.adminAttentionClear)
        else ...[
          if (pendingCertify > 0)
            _AttentionTile(
              icon: Icons.verified_user_outlined,
              title: l10n.adminAttentionCertify(pendingCertify),
              color: AdminConsoleTheme.danger,
              onTap: () =>
                  onJump(_AdminHub.members, sub: _MembersSub.instructors),
            ),
          if (pendingProducts > 0) ...[
            const SizedBox(height: 8),
            _AttentionTile(
              icon: Icons.add_box_outlined,
              title: '${l10n.adminProductPendingQueue} · $pendingProducts',
              color: AdminConsoleTheme.danger,
              onTap: () =>
                  onJump(_AdminHub.products, sub: _ProductsSub.catalog),
            ),
          ],
          if (plaqueCount > 0) ...[
            const SizedBox(height: 8),
            _AttentionTile(
              icon: Icons.workspace_premium_outlined,
              title: l10n.adminAttentionPlaque(plaqueCount),
              color: AdminConsoleTheme.amber,
              onTap: () =>
                  onJump(_AdminHub.members, sub: _MembersSub.partners),
            ),
          ],
          if (hiddenCount > 0) ...[
            const SizedBox(height: 8),
            _AttentionTile(
              icon: Icons.visibility_off_outlined,
              title: l10n.adminAttentionHidden(hiddenCount),
              color: AdminConsoleTheme.ice,
              onTap: () => onJump(_AdminHub.tools, sub: _ToolsSub.posts),
            ),
          ],
        ],
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.bar_chart_rounded,
          title: l10n.adminGradeMixTitle,
        ),
        const SizedBox(height: 10),
        _GradeMixCard(
          counts: gradeCounts,
          labels: {
            MemberGrade.silver: l10n.memberGradeSilver,
            MemberGrade.gold: l10n.memberGradeGold,
            MemberGrade.diamond: l10n.memberGradeDiamond,
            MemberGrade.platinum: l10n.memberGradePlatinum,
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.adminGradeMixInstructorNote,
          style: const TextStyle(
            fontSize: 12,
            color: AdminConsoleTheme.muted,
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.grid_view_rounded,
          title: l10n.adminQuickActions,
        ),
        const SizedBox(height: 10),
        _QuickAction(
          icon: Icons.event_available_outlined,
          title: l10n.adminTabBookings,
          subtitle: l10n.adminBookingsSubList,
          onTap: () => onJump(_AdminHub.bookings, sub: _BookingsSub.list),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.inventory_2_outlined,
          title: l10n.adminTabProducts,
          subtitle: l10n.adminProductPendingQueue,
          onTap: () => onJump(_AdminHub.products, sub: _ProductsSub.catalog),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.gavel_outlined,
          title: l10n.adminTabContracts,
          subtitle: l10n.adminContractsSubOverview,
          onTap: () =>
              onJump(_AdminHub.contracts, sub: _ContractsSub.overview),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.star_outline,
          title: l10n.adminTabDiveStar,
          subtitle: l10n.adminDiveStarSubApplications,
          onTap: () =>
              onJump(_AdminHub.diveStar, sub: _DiveStarSub.applications),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.percent,
          title: l10n.adminTabSettlement,
          subtitle: l10n.adminSettlementSubPricing,
          onTap: () =>
              onJump(_AdminHub.settlement, sub: _SettlementSub.pricing),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.home_outlined,
          title: l10n.adminHomeCurationTab,
          subtitle: l10n.adminHomeCurationSubtitle,
          onTap: () =>
              onJump(_AdminHub.products, sub: _ProductsSub.homeCuration),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.event_seat_outlined,
          title: l10n.adminSameBoatApplyTab,
          subtitle: l10n.adminSameBoatApplyHint,
          onTap: () => onJump(_AdminHub.products, sub: _ProductsSub.seats),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.directions_boat_outlined,
          title: l10n.adminSameBoatTab,
          subtitle: l10n.adminSameBoatHint,
          onTap: () =>
              onJump(_AdminHub.products, sub: _ProductsSub.sameBoat),
        ),
      ],
    );
  }
}

class _StatRowCard extends StatelessWidget {
  const _StatRowCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(color: AdminConsoleTheme.muted),
                      ),
                    ),
                    Text(
                      row.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NearUpgradeTile extends StatelessWidget {
  const _NearUpgradeTile({required this.member});

  final MemberAccount member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deficit = MemberGrade.deficitToNext(
      current: member.grade,
      paidPurchases: member.paidPurchaseCount,
      reviews: member.reviewCount,
    );
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        title: Text(member.displayName),
        subtitle: Text(
          l10n.adminNearUpgradeHint(deficit.$1, deficit.$2),
        ),
        trailing: Text(
          memberGradeShort(l10n, member.grade),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AdminConsoleTheme.aqua,
          ),
        ),
      ),
    );
  }
}

String memberGradeShort(AppLocalizations l10n, MemberGrade grade) {
  return switch (grade) {
    MemberGrade.silver => l10n.memberGradeSilver,
    MemberGrade.gold => l10n.memberGradeGold,
    MemberGrade.diamond => l10n.memberGradeDiamond,
    MemberGrade.platinum => l10n.memberGradePlatinum,
  };
}

class _SalesByKindCard extends StatelessWidget {
  const _SalesByKindCard({required this.salesByKind});

  final Map<String, int> salesByKind;

  static final _money = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final won = Localizations.localeOf(context).languageCode == 'ko';
    var total = 0;
    for (final amount in salesByKind.values) {
      total += amount;
    }
    final rows = <(String, String)>[
      ('explore_only', l10n.adminSalesExplore),
      ('flag', l10n.adminSalesFlag),
      ('diver_planned', l10n.adminSalesDiverPlanned),
      ('curated', l10n.adminSalesCurated),
      ('dive_star', l10n.adminSalesDiveStar),
      ('hot_spot', l10n.adminSalesHotSpot),
      ('next_departure', l10n.adminSalesNextDeparture),
    ];
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminConsoleTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminSalesTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminSalesTotal(_money.format(total)),
              style: const TextStyle(
                color: AdminConsoleTheme.aqua,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            for (final (kind, label) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    Text(
                      won
                          ? '${_money.format(salesByKind[kind] ?? 0)}원'
                          : '${_money.format(salesByKind[kind] ?? 0)} KRW',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
    this.hint,
  });

  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminConsoleTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdminConsoleTheme.muted,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: accent,
                  height: 1,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AdminConsoleTheme.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminConsoleTheme.aqua),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AdminConsoleTheme.text,
          ),
        ),
      ],
    );
  }
}

class _EmptyAttention extends StatelessWidget {
  const _EmptyAttention({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AdminConsoleTheme.muted),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeMixCard extends StatelessWidget {
  const _GradeMixCard({required this.counts, required this.labels});

  final Map<MemberGrade, int> counts;
  final Map<MemberGrade, String> labels;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final max = counts.values.fold<int>(1, (a, b) => a > b ? a : b);
    const colors = {
      MemberGrade.silver: AdminConsoleTheme.muted,
      MemberGrade.gold: AdminConsoleTheme.ice,
      MemberGrade.diamond: AdminConsoleTheme.amber,
      MemberGrade.platinum: AdminConsoleTheme.aqua,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final grade in MemberGrade.valuesInOrder) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${counts[grade] ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors[grade],
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            height: total == 0
                                ? 8
                                : 16 +
                                    72 *
                                        ((counts[grade] ?? 0) / max),
                            decoration: BoxDecoration(
                              color: colors[grade],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (colors[grade] ?? Colors.white)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final grade in MemberGrade.valuesInOrder)
                Expanded(
                  child: Text(
                    labels[grade] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AdminConsoleTheme.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminConsoleTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminConsoleTheme.aqua.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AdminConsoleTheme.aqua, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AdminConsoleTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminConsoleTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AdminConsoleTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
