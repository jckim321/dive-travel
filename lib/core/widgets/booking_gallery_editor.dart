import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// One gallery cell: remote URL and/or local picked bytes.
class BookingGalleryItem {
  const BookingGalleryItem._({this.url, this.photo});

  factory BookingGalleryItem.remote(String url) =>
      BookingGalleryItem._(url: url);

  factory BookingGalleryItem.local(PickedPhoto photo) =>
      BookingGalleryItem._(photo: photo);

  final String? url;
  final PickedPhoto? photo;

  bool get hasImage =>
      (photo != null && photo!.bytes.isNotEmpty) ||
      (url != null && url!.trim().isNotEmpty && !url!.startsWith('memory://'));
}

/// Booking.com-style editor: large cover + secondary grid.
class BookingGalleryEditor extends StatelessWidget {
  const BookingGalleryEditor({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onMakeCover,
    this.onTest,
    this.maxItems = GalleryLimits.maxProductPhotos,
    this.cornerRadius = 12,
    this.fieldKey,
    this.attachKey,
    this.testKey,
  });

  final List<BookingGalleryItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;
  final VoidCallback? onTest;
  final int maxItems;
  final double cornerRadius;
  final Key? fieldKey;
  final Key? attachKey;
  final Key? testKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canAdd = items.length < maxItems;

    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          items.isEmpty
              ? l10n.exploreGalleryEmpty
              : l10n.exploreGalleryCount(items.length),
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyDrop(onAdd: onAdd, cornerRadius: cornerRadius)
        else
          _BookingMosaic(
            items: items,
            onRemove: onRemove,
            onMakeCover: onMakeCover,
            onAdd: canAdd ? onAdd : null,
            cornerRadius: cornerRadius,
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: attachKey,
              onPressed: canAdd ? onAdd : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: Text(
                items.isEmpty
                    ? l10n.exploreAttachPhoto
                    : l10n.exploreGalleryAddMore,
              ),
            ),
            if (onTest != null)
              OutlinedButton(
                key: testKey,
                onPressed: canAdd ? onTest : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navy,
                  side: const BorderSide(color: Color(0xFFC5CED6)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.logbookUseTestPhoto),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyDrop extends StatelessWidget {
  const _EmptyDrop({required this.onAdd, this.cornerRadius = 12});

  final VoidCallback onAdd;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(cornerRadius);
    return Material(
      color: const Color(0xFF0B1F33),
      borderRadius: radius,
      child: InkWell(
        onTap: onAdd,
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: ListingCover.aspectRatio,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.exploreGalleryAdd,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.exploreGalleryHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
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

class _BookingMosaic extends StatelessWidget {
  const _BookingMosaic({
    required this.items,
    required this.onRemove,
    required this.onMakeCover,
    this.onAdd,
    this.cornerRadius = 12,
  });

  final List<BookingGalleryItem> items;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;
  final VoidCallback? onAdd;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final extras = items.length > 1 ? items.sublist(1) : const <BookingGalleryItem>[];
    final showTiles = extras.take(4).toList();
    final moreCount = items.length > 5 ? items.length - 5 : 0;
    final narrow = MediaQuery.sizeOf(context).width < 560;

    final cover = _GalleryTile(
      item: items.first,
      isCover: true,
      cornerRadius: cornerRadius,
      label: l10n.exploreCoverPhoto,
      badge: items.length > 1 ? l10n.exploreGalleryViewAll : null,
      onRemove: () => onRemove(0),
    );

    final grid = _SecondaryGrid(
      showTiles: showTiles,
      moreCount: moreCount,
      onAdd: onAdd,
      onRemove: onRemove,
      onMakeCover: onMakeCover,
      cornerRadius: cornerRadius,
    );

    if (narrow) {
      return Column(
        children: [
          AspectRatio(aspectRatio: 16 / 10, child: cover),
          const SizedBox(height: 6),
          AspectRatio(aspectRatio: 2.2, child: grid),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 2.05,
      child: Row(
        children: [
          Expanded(flex: 6, child: cover),
          const SizedBox(width: 6),
          Expanded(flex: 4, child: grid),
        ],
      ),
    );
  }
}

class _SecondaryGrid extends StatelessWidget {
  const _SecondaryGrid({
    required this.showTiles,
    required this.moreCount,
    required this.onRemove,
    required this.onMakeCover,
    this.onAdd,
    this.cornerRadius = 12,
  });

  final List<BookingGalleryItem> showTiles;
  final int moreCount;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;
  final VoidCallback? onAdd;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final tileRadius = cornerRadius > 2 ? cornerRadius * 0.67 : cornerRadius;
    Widget cell(int slotIndex) {
      final tileIndex = slotIndex - 1;
      if (tileIndex < showTiles.length) {
        final tile = _GalleryTile(
          item: showTiles[tileIndex],
          cornerRadius: tileRadius,
          onRemove: () => onRemove(slotIndex),
          onMakeCover: () => onMakeCover(slotIndex),
        );
        if (slotIndex == 4 && moreCount > 0) {
          return Stack(
            fit: StackFit.expand,
            children: [
              tile,
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(tileRadius),
                  ),
                  child: Center(
                    child: Text(
                      '+$moreCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return tile;
      }
      if (onAdd == null) {
        return const SizedBox.shrink();
      }
      final radius = BorderRadius.circular(tileRadius);
      return Material(
        color: const Color(0xFF16324A),
        borderRadius: radius,
        child: InkWell(
          onTap: onAdd,
          borderRadius: radius,
          child: const Center(
            child: Icon(Icons.add, color: Colors.white70, size: 28),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(1)),
              const SizedBox(width: 6),
              Expanded(child: cell(2)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(3)),
              const SizedBox(width: 6),
              Expanded(child: cell(4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.item,
    required this.onRemove,
    this.onMakeCover,
    this.isCover = false,
    this.cornerRadius = 8,
    this.label,
    this.badge,
  });

  final BookingGalleryItem item;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;
  final bool isCover;
  final double cornerRadius;
  final String? label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(cornerRadius);
    final chipRadius =
        cornerRadius > 2 ? (isCover ? 6.0 : 4.0) : cornerRadius;
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF0B1F33),
            child: item.photo != null
                ? Image.memory(item.photo!.bytes, fit: BoxFit.cover)
                : item.url != null && item.url!.isNotEmpty
                    ? Image.network(
                        item.url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : Image.asset(
                        'assets/images/test_dive_photo.png',
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.45),
                      ),
          ),
          if (label != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(chipRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(chipRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMakeCover != null)
                  _Action(
                    tooltip: l10n.exploreGalleryMakeCover,
                    icon: Icons.star_outline,
                    onTap: onMakeCover!,
                  ),
                _Action(
                  tooltip: l10n.exploreCoverRemove,
                  icon: Icons.close,
                  onTap: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Booking.com partner-style numbered section card.
class BookingFormSection extends StatelessWidget {
  const BookingFormSection({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.borderRadius = 12,
  });

  final String step;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final stepRadius = borderRadius > 2 ? 6.0 : borderRadius;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B1F33),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(stepRadius),
                  ),
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
bool bookingGalleryUsesStackedLayout(double width) => width < 560;
