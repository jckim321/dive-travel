import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/i18n/translation_engine.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/features/community/presentation/open_tide_room.dart';
import 'package:dive_travel_app/features/community/presentation/translatable_text.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _TideFilter { all, lastCall, solo, shop }

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  _TideFilter _filter = _TideFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.visiblePosts;
        final posts = [for (final post in all) if (_matches(post)) post];
        final lastCallPosts = [
          for (final post in all)
            if (post.kind == TideKind.lastCall) post,
        ];
        final openSeats = all.fold<int>(
          0,
          (sum, post) => sum + post.emptySeats,
        );

        return Scaffold(
          backgroundColor: AppTheme.canvas,
          floatingActionButton: FloatingActionButton(
            heroTag: 'community-fab',
            onPressed: () => _compose(context),
            tooltip: l10n.communityPlantFlag,
            child: const Icon(Icons.flag_outlined),
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              key: const Key('tide-board'),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 108),
              children: [
                _TideHeader(
                  openSeats: openSeats,
                  departureCount: all.length,
                  lastCallCount: lastCallPosts.length,
                ),
                if (lastCallPosts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _UrgentStrip(
                    count: lastCallPosts.length,
                    onTap: () => setState(() => _filter = _TideFilter.lastCall),
                  ),
                ],
                const SizedBox(height: 16),
                _TideSegmentFilter(
                  value: _filter,
                  onChanged: (next) => setState(() => _filter = next),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.communityBoardList,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.communityBoardListHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (posts.isEmpty)
                  AppCard(
                    child: Text(
                      l10n.communityEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final post in posts) ...[
                    _TideManifestCard(
                      post: post,
                      shop: _shopFor(store, post),
                      compact: true,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CommunityPostDetailScreen(post: post),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 8),
                Text(
                  l10n.communityHostMileage,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _matches(CommunityPost post) {
    switch (_filter) {
      case _TideFilter.all:
        return true;
      case _TideFilter.lastCall:
        return post.kind == TideKind.lastCall;
      case _TideFilter.solo:
        return post.soloShare || post.kind == TideKind.soloShare;
      case _TideFilter.shop:
        return post.kind == TideKind.shopCrew ||
            post.type == CommunityPostType.shopTour;
    }
  }

  Future<void> _compose(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final active = [
      for (final booking in store.bookings)
        if (booking.isActive) booking,
    ];
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityNeedBooking)),
      );
      return;
    }
    final picked = await showDialog<TourBooking>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.communityPlantFlag),
          children: [
            for (final booking in active)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, booking),
                child: Text('${booking.shopName}\n${booking.productName}'),
              ),
          ],
        );
      },
    );
    if (picked == null || !context.mounted) {
      return;
    }
    await openTideRoomForBooking(context: context, booking: picked);
  }
}

DiveShop? _shopFor(DiverStore store, CommunityPost post) {
  final id = post.shopId;
  if (id == null || id.isEmpty) {
    return null;
  }
  final hullId = id.split('--').first;
  final listings = store.listingsOnHull(hullId);
  for (final shop in listings) {
    if (shop.id == id || shop.productName == post.subtitle) {
      return _withPostDeparture(shop, post);
    }
  }
  if (listings.isEmpty) {
    return null;
  }
  return _withPostDeparture(listings.first, post);
}

DiveShop _withPostDeparture(DiveShop shop, CommunityPost post) {
  return shop.copyWith(
    productName: post.subtitle.isEmpty ? shop.productName : post.subtitle,
    departure: TourDeparture(
      start: shop.departure?.start ??
          DateTime.now().add(const Duration(days: 7)),
      windowLabel: post.windowLabel.isNotEmpty
          ? post.windowLabel
          : (shop.departure?.windowLabel ?? ''),
      capacity: post.capacity,
      bookedSeats: post.bookedSeats,
      lookingSeats: post.lookingSeats,
      lastCall: post.kind == TideKind.lastCall,
      soloShare: post.soloShare,
    ),
  );
}

class _TideHeader extends StatelessWidget {
  const _TideHeader({
    required this.openSeats,
    required this.departureCount,
    required this.lastCallCount,
  });

  final int openSeats;
  final int departureCount;
  final int lastCallCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.communityTideKicker,
          style: const TextStyle(
            color: AppTheme.ocean,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.communityTideHeadline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                height: 1.2,
                color: AppTheme.navy,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.communityTideBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                value: '$openSeats',
                label: l10n.communityStatOpenSeats,
                accent: AppTheme.ocean,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                value: '$departureCount',
                label: l10n.communityFilterAll,
                accent: AppTheme.navy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                value: '$lastCallCount',
                label: l10n.communityFilterLastCall,
                accent: lastCallCount > 0
                    ? const Color(0xFFB42318)
                    : AppTheme.muted,
                warn: lastCallCount > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.accent,
    this.warn = false,
  });

  final String value;
  final String label;
  final Color accent;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFBE9E7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warn ? const Color(0xFFF2C4BE) : const Color(0xFFE8EBEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: accent,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentStrip extends StatelessWidget {
  const _UrgentStrip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFFFBE9E7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Color(0xFFB42318),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.communityUrgentBanner(count),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB42318),
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB42318)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TideSegmentFilter extends StatelessWidget {
  const _TideSegmentFilter({
    required this.value,
    required this.onChanged,
  });

  final _TideFilter value;
  final ValueChanged<_TideFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBEE)),
      ),
      child: Row(
        children: [
          for (final entry in [
            (_TideFilter.all, l10n.communityFilterAll),
            (_TideFilter.lastCall, l10n.communityFilterLastCall),
            (_TideFilter.solo, l10n.communityFilterSolo),
            (_TideFilter.shop, l10n.communityFilterShop),
          ])
            Expanded(
              child: _SegmentCell(
                label: entry.$2,
                selected: value == entry.$1,
                onTap: () => onChanged(entry.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _TideManifestCard extends StatelessWidget {
  const _TideManifestCard({
    required this.post,
    required this.shop,
    required this.onOpen,
    this.compact = false,
  });

  final CommunityPost post;
  final DiveShop? shop;
  final VoidCallback onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = Color(shop?.accentColor ?? 0xFF0B1F33);
    final kindLabel = switch (post.kind) {
      TideKind.lastCall => l10n.communityKindLast,
      TideKind.soloShare => l10n.communityKindSolo,
      TideKind.shopCrew => l10n.communityKindShop,
    };
    final destination =
        post.destination.isEmpty ? post.authorName : post.destination;
    final window =
        post.windowLabel.isEmpty ? l10n.communityWindowOpen : post.windowLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tide-card-${post.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EBEE)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 7, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: AppTheme.navy,
                                  ),
                                ),
                              ),
                              _KindPill(
                                label: kindLabel,
                                urgent: post.kind == TideKind.lastCall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: AppTheme.ocean,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                window,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ocean,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.communitySeatsLeft(post.emptySeats),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ],
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 10),
                            TranslatableText(
                              text: post.title,
                              language: post.language,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            TranslatableText(
                              text: post.subtitle,
                              language: post.language,
                              style: theme.textTheme.bodySmall,
                            ),
                          ] else if (post.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              post.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _BerthMeter(post: post),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.communityBerths(
                                    post.bookedSeats,
                                    post.capacity,
                                  ),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                              if (compact)
                                FilledButton(
                                  onPressed: onOpen,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: Text(l10n.communityViewSeats),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.label, required this.urgent});

  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFBE9E7) : AppTheme.goldSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: urgent ? const Color(0xFFB42318) : AppTheme.navy,
          ),
        ),
      ),
    );
  }
}

class _BerthMeter extends StatelessWidget {
  const _BerthMeter({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final slots = post.capacity.clamp(1, 12);
    return Row(
      children: [
        for (var i = 0; i < slots; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          _BerthDot(
            fill: i < post.bookedSeats
                ? AppTheme.navy
                : i < post.bookedSeats + post.lookingSeats
                    ? AppTheme.gold
                    : const Color(0xFFD5DBE0),
          ),
        ],
      ],
    );
  }
}

class _BerthDot extends StatelessWidget {
  const _BerthDot({required this.fill});

  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 18,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final post = widget.post;
    final theme = Theme.of(context);
    final shop = _shopFor(store, post);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: Text(l10n.communityManifest)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommunityComment>>(
              stream: store.watchComments(post.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? const <CommunityComment>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    _TideManifestCard(
                      post: post,
                      shop: shop,
                      onOpen: () {},
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.communityTideSafety,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('raise-tide-flag'),
                      onPressed: () => _raiseFlag(context, post),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(l10n.communityRaiseFlag),
                    ),
                    if (shop != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => showTourCheckoutSheet(
                          context: context,
                          shop: shop,
                          quote: store.quoteFor(shop),
                        ),
                        child: Text(l10n.communityOpenTrip),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      l10n.communityComments,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (comments.isEmpty)
                      Text(
                        l10n.communityNoComments,
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      for (final item in comments) ...[
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.authorName,
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              TranslatableText(
                                text: item.body,
                                language: item.language,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comment,
                      decoration: InputDecoration(
                        hintText: l10n.communityCommentHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final body = _comment.text.trim();
                      if (body.isEmpty) {
                        return;
                      }
                      await store.addComment(
                        postId: post.id,
                        body: body,
                        language: LanguageDetector.detect(body),
                      );
                      _comment.clear();
                    },
                    icon: const Icon(Icons.send_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _raiseFlag(BuildContext context, CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    await store.addComment(
      postId: post.id,
      body: l10n.communityRaiseFlagMessage,
      language: Localizations.localeOf(context).languageCode,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.communityRaiseFlagDone)),
    );
    final shop = _shopFor(store, post);
    if (shop == null) {
      return;
    }
    await showTourCheckoutSheet(
      context: context,
      shop: shop,
      quote: store.quoteFor(shop),
    );
  }
}
