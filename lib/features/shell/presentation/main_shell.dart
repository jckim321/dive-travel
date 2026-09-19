import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/community/presentation/community_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_screen.dart';
import 'package:dive_travel_app/features/logbook/presentation/logbook_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static void goToTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainShellState>()?.goToTab(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  DiverStore? _store;

  void goToTab(int index) {
    setState(() => _index = index);
  }
  final _seenNotices = <String>{};

  static const _screens = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    CommunityScreen(),
    LogbookScreen(),
    ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = DiverStoreScope.of(context);
    if (!identical(_store, store)) {
      _store?.removeListener(_onStore);
      _store = store;
      _store?.addListener(_onStore);
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    final store = _store;
    if (store == null || !mounted) {
      return;
    }
    for (final booking in store.bookings) {
      if (!booking.needsRefundNotice || _seenNotices.contains(booking.id)) {
        continue;
      }
      _seenNotices.add(booking.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showWeatherDialog(booking);
      });
      break;
    }
  }

  Future<void> _showWeatherDialog(TourBooking booking) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.weatherRefundTitle),
          content: Text(
            l10n.weatherRefundBody(booking.shopName, booking.productName),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await DiverStoreScope.of(context).acknowledgeRefundNotice(
                  booking.id,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(l10n.weatherRefundAck),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_outlined),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.travel_explore_outlined),
            selectedIcon: const Icon(Icons.travel_explore_outlined),
            label: l10n.navExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_2_outlined),
            selectedIcon: const Icon(Icons.groups_2_outlined),
            label: l10n.navCommunity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_outlined),
            label: l10n.navLogbook,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person_outline),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
