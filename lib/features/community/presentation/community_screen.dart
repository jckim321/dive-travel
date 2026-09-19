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
        final posts = [
          for (final post in store.visiblePosts)
            if (_matches(post)) post,
        ];
        final looking = store.visiblePosts.fold<int>(
          0,
          (sum, post) => sum + post.lookingSeats,
        );
        final lastCall = store.visiblePosts
            .where((post) => post.kind == TideKind.lastCall)
            .length;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'community-fab',
            onPressed: () => _compose(context),
            icon: const Icon(Icons.flag_outlined, size: 20),
            label: Text(l10n.communityPlantFlag),
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              key: const Key('tide-board'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
              children: [
                const _TideHero(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _TideStat(
                      value: '${store.visiblePosts.length}',
                      label: l10n.communityFilterAll,
                    ),
                    const SizedBox(width: 10),
                    _TideStat(value: '$looking', label: l10n.communityManifest),
                    const SizedBox(width: 10),
                    _TideStat(
                      value: '$lastCall',
                      label: l10n.communityFilterLastCall,
                      warn: lastCall > 0,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(l10n.communityFilterAll, _TideFilter.all),
                    _chip(l10n.communityFilterLastCall, _TideFilter.lastCall),
                    _chip(l10n.communityFilterSolo, _TideFilter.solo),
                    _chip(l10n.communityFilterShop, _TideFilter.shop),
                  ],
                ),
                const SizedBox(height: 18),
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
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CommunityPostDetailScreen(post: post),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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

  Widget _chip(String label, _TideFilter value) {
    return Padding(
      padding: EdgeInsets.zero,
      child: ChoiceChip(
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
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

class _TideHero extends StatelessWidget {
  const _TideHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F33), Color(0xFF0A4A73), Color(0xFFC4A35A)],
          stops: [0, 0.62, 1],
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned(
              right: -28,
              top: -40,
              child: IgnorePointer(
                child: _TideRing(size: 160, color: Color(0x33FFFFFF)),
              ),
            ),
            const Positioned(
              right: 18,
              bottom: -36,
              child: IgnorePointer(
                child: _TideRing(size: 110, color: Color(0x22C4A35A)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.communityTideKicker,
                    style: const TextStyle(
                      color: Color(0xFFF4EBD3),
                      fontSize: 11,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.communityTideHeadline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.communityTideBody,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF6DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Text(
                        l10n.communityTideSafety,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

class _TideRing extends StatelessWidget {
  const _TideRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TideRingPainter(color),
    );
  }
}

class _TideRingPainter extends CustomPainter {
  const _TideRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.42, paint);
    canvas.drawCircle(center, size.width * 0.28, paint..strokeWidth = 6);
    canvas.drawCircle(center, size.width * 0.14, paint..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _TideRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TideStat extends StatelessWidget {
  const _TideStat({
    required this.value,
    required this.label,
    this.warn = false,
  });

  final String value;
  final String label;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: warn ? const Color(0xFFFBE9E7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: warn ? const Color(0xFFB42318) : AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
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
  });

  final CommunityPost post;
  final DiveShop? shop;
  final VoidCallback onOpen;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tide-card-${post.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 8, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.communityFrom,
                                style: const TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.muted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  post.destination.isEmpty
                                      ? post.authorName
                                      : post.destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.navy,
                                  ),
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: post.kind == TideKind.lastCall
                                      ? const Color(0xFFFBE9E7)
                                      : AppTheme.goldSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    kindLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: post.kind == TideKind.lastCall
                                          ? const Color(0xFFB42318)
                                          : AppTheme.navy,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                l10n.communityTo,
                                style: const TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.muted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.windowLabel.isEmpty
                                    ? 'OPEN'
                                    : post.windowLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ocean,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TranslatableText(
                            text: post.title,
                            language: post.language,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          TranslatableText(
                            text: post.subtitle,
                            language: post.language,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          _BerthMeter(post: post),
                          const SizedBox(height: 10),
                          Text(
                            '${l10n.communityBerths(post.bookedSeats, post.capacity)}  ·  ${l10n.communityLooking(post.lookingSeats)}  ·  ${l10n.communitySeatsLeft(post.emptySeats)}',
                            style: theme.textTheme.labelSmall,
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
                    _TideManifestCard(post: post, shop: shop, onOpen: () {}),
                    const SizedBox(height: 12),
                    Text(
                      l10n.communityTideSafety,
                      style: theme.textTheme.bodySmall,
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
