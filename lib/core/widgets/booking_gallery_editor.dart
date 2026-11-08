import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// One gallery cell: remote URL and/or local picked bytes.
class BookingGalleryItem {
  const BookingGalleryItem._({this.url, this.photo});

  factory BookingGalleryItem.remote(String url) =>
      BookingGalleryItem._(url: R2Config.normalizePublicUrl(url));

  factory BookingGalleryItem.local(PickedPhoto photo) =>
      BookingGalleryItem._(photo: photo);

  final String? url;
  final PickedPhoto? photo;

  bool get hasImage =>
      (photo != null && photo!.bytes.isNotEmpty) ||
      (url != null && url!.trim().isNotEmpty && !url!.startsWith('memory://'));
}

/// Booking.com-style editor: large cover + horizontal scroll of all photos.

/// Mosaic preview plus a manage dialog. Callbacks stay with the caller.
class BookingGalleryEditor extends StatefulWidget {
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
    this.compact = false,
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

  /// Narrower width cap. Product forms use this. Resort keeps the wider one.
  final bool compact;

  @override
  State<BookingGalleryEditor> createState() => _BookingGalleryEditorState();
}

class _BookingGalleryEditorState extends State<BookingGalleryEditor> {
  final _generation = ValueNotifier<int>(0);

  double get _maxWidth => widget.compact ? 360 : 640;

  bool get _canAdd => widget.items.length < widget.maxItems;

  @override
  void didUpdateWidget(BookingGalleryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generation.value++;
  }

  @override
  void dispose() {
    _generation.dispose();
    super.dispose();
  }

  Future<void> _openManager() {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return showDialog<void>(
      context: context,
      builder: (_) {
        return ValueListenableBuilder<int>(
          valueListenable: _generation,
          builder: (context, _, _) {
            final body = _ManageGallery(
              items: widget.items,
              onAdd: _canAdd ? widget.onAdd : null,
              onRemove: widget.onRemove,
              onMakeCover: widget.onMakeCover,
              onTest: widget.onTest,
              testEnabled: _canAdd,
              attachKey: widget.attachKey ?? const Key('product-photo-add'),
              testKey: widget.testKey,
            );
            if (!wide) {
              return Dialog.fullscreen(child: body);
            }
            return Dialog(
              backgroundColor: PlannerPalette.card,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: SizedBox(width: 760, height: 640, child: body),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = widget.items;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final width = !available.isFinite
            ? _maxWidth
            : math.min(_maxWidth, math.max(0.0, available));
        final metrics = _MosaicMetrics.of(width, items.length);
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            key: widget.fieldKey ?? const Key('product-photo-strip'),
            width: metrics.width,
            height: metrics.height,
            child: items.isEmpty
                ? _EmptyAddBox(
                    height: metrics.height,
                    radius: widget.cornerRadius,
                    onTap: _canAdd ? widget.onAdd : null,
                    buttonKey: widget.attachKey ?? const Key('product-photo-add'),
                    label: l10n.exploreGalleryAdd,
                  )
                : Stack(
                    children: [
                      _Mosaic(
                        items: items,
                        radius: widget.cornerRadius,
                        metrics: metrics,
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _CaptionButton(
                          label: '모든 사진 관리 (${items.length}장)',
                          onTap: _openManager,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Width cap and 4:3 cells. Height follows the width.
class _MosaicMetrics {
  const _MosaicMetrics({
    required this.width,
    required this.height,
    required this.largeWidth,
    required this.largeHeight,
    required this.smallWidth,
    required this.smallHeight,
    required this.smallCount,
  });

  final double width;
  final double height;
  final double largeWidth;
  final double largeHeight;
  final double smallWidth;
  final double smallHeight;
  final int smallCount;

  static const gap = 4.0;

  factory _MosaicMetrics.of(double maxWidth, int count) {
    if (count <= 1) {
      final height = maxWidth * 3 / 4;
      return _MosaicMetrics(
        width: maxWidth,
        height: height,
        largeWidth: maxWidth,
        largeHeight: height,
        smallWidth: 0,
        smallHeight: 0,
        smallCount: 0,
      );
    }
    final height = (maxWidth - 2 * gap / 3) * 3 / 8;
    final largeWidth = height * 4 / 3;
    final smallHeight = (height - gap) / 2;
    final smallWidth = smallHeight * 4 / 3;
    final smallCount = math.min(4, count - 1);
    final columns = smallCount == 1 ? 1 : 2;
    final rightWidth = columns * smallWidth + (columns - 1) * gap;
    return _MosaicMetrics(
      width: largeWidth + gap + rightWidth,
      height: height,
      largeWidth: largeWidth,
      largeHeight: height,
      smallWidth: smallWidth,
      smallHeight: smallHeight,
      smallCount: smallCount,
    );
  }
}

class _Mosaic extends StatelessWidget {
  const _Mosaic({
    required this.items,
    required this.radius,
    required this.metrics,
  });

  final List<BookingGalleryItem> items;
  final double radius;
  final _MosaicMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final smallRadius = radius > 2 ? 8.0 : radius;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: metrics.largeWidth,
          height: metrics.largeHeight,
          child: _MosaicCell(
            item: items.first,
            radius: radius,
            cover: true,
          ),
        ),
        if (metrics.smallCount > 0) ...[
          const SizedBox(width: _MosaicMetrics.gap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _smallRow(0, smallRadius),
              if (metrics.smallCount > 2) ...[
                const SizedBox(height: _MosaicMetrics.gap),
                _smallRow(2, smallRadius),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _smallRow(int start, double smallRadius) {
    final end = math.min(start + 2, metrics.smallCount);
    return Row(
      children: [
        for (var i = start; i < end; i++) ...[
          if (i > start) const SizedBox(width: _MosaicMetrics.gap),
          SizedBox(
            width: metrics.smallWidth,
            height: metrics.smallHeight,
            child: _slot(i + 1, smallRadius),
          ),
        ],
      ],
    );
  }

  Widget _slot(int index, double smallRadius) {
    final extra = index == 4 && items.length > 5 ? items.length - 5 : 0;
    return _MosaicCell(
      item: items[index],
      radius: smallRadius,
      extraCount: extra,
    );
  }
}

class _MosaicCell extends StatelessWidget {
  const _MosaicCell({
    required this.item,
    required this.radius,
    this.cover = false,
    this.extraCount = 0,
  });

  final BookingGalleryItem item;
  final double radius;
  final bool cover;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: PlannerPalette.disabledFill,
            child: _PhotoImage(item: item),
          ),
          if (cover)
            Positioned(
              left: 8,
              bottom: 8,
              child: _PhotoCaption(
                l10n.partnerFormPhotoMain,
                key: const Key('product-photo-cover'),
              ),
            ),
          if (extraCount > 0)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(child: _PhotoCaption('+$extraCount')),
            ),
        ],
      ),
    );
  }
}

class _EmptyAddBox extends StatelessWidget {
  const _EmptyAddBox({
    required this.height,
    required this.radius,
    required this.label,
    required this.buttonKey,
    this.onTap,
  });

  final double height;
  final double radius;
  final String label;
  final Key buttonKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRectPainter(
        color: PlannerPalette.borderStrong,
        radius: radius,
      ),
      child: Material(
        color: PlannerPalette.card,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: PlannerPalette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCaption extends StatelessWidget {
  const _PhotoCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ManageGallery extends StatelessWidget {
  const _ManageGallery({
    required this.items,
    required this.onRemove,
    required this.onMakeCover,
    required this.attachKey,
    required this.testEnabled,
    this.onAdd,
    this.onTest,
    this.testKey,
  });

  final List<BookingGalleryItem> items;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;
  final VoidCallback? onTest;
  final bool testEnabled;
  final Key attachKey;
  final Key? testKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Theme(
      data: PlannerPalette.theme,
      child: Material(
        color: PlannerPalette.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '모든 사진 관리 (${items.length}장)',
                      style: const TextStyle(
                        color: PlannerPalette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: PlannerPalette.text),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: attachKey,
                    onPressed: onAdd,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 20,
                    ),
                    label: Text(
                      items.isEmpty
                          ? l10n.exploreGalleryAdd
                          : l10n.exploreGalleryAddMore,
                    ),
                  ),
                  if (onTest != null)
                    OutlinedButton(
                      key: testKey,
                      onPressed: testEnabled ? onTest : null,
                      child: Text(l10n.logbookUseTestPhoto),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cover = index == 0;
                  return _ManageTile(
                    key: Key('product-photo-thumb-$index'),
                    item: items[index],
                    cover: cover,
                    onRemove: () => onRemove(index),
                    onMakeCover: cover ? null : () => onMakeCover(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    super.key,
    required this.item,
    required this.cover,
    required this.onRemove,
    this.onMakeCover,
  });

  final BookingGalleryItem item;
  final bool cover;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PlannerPalette.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PlannerPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: PlannerPalette.disabledFill,
                    child: _PhotoImage(item: item),
                  ),
                  if (cover)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: _PhotoCaption(l10n.partnerFormPhotoMain),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                if (onMakeCover != null)
                  Expanded(
                    child: TextButton(
                      key: const Key('product-photo-make-cover'),
                      onPressed: onMakeCover,
                      child: Text(l10n.exploreGalleryMakeCover),
                    ),
                  ),
                Expanded(
                  child: TextButton(
                    key: const Key('product-photo-delete'),
                    onPressed: onRemove,
                    child: Text(l10n.exploreCoverRemove),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.item});

  final BookingGalleryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (item.photo != null && item.photo!.bytes.isNotEmpty) {
      return Image.memory(item.photo!.bytes, fit: BoxFit.cover);
    }
    final url = item.url;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: PlannerPalette.disabledFill,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.workbenchPhotoLoadFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlannerPalette.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Image.asset(
      'assets/images/test_dive_photo.png',
      fit: BoxFit.cover,
      opacity: const AlwaysStoppedAnimation(0.45),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = dark ? scheme.surface : Colors.white;
    final borderColor = dark ? scheme.outline : const Color(0xFFE7E7E7);
    final dividerColor = dark ? scheme.outlineVariant : const Color(0xFFEEEEEE);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: dark
            ? const []
            : const [
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
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: dividerColor),
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
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(stepRadius),
                  ),
                  child: Text(
                    step,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
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
                              ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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
bool bookingGalleryUsesStackedLayout(double width) => true;
