import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/core/models/story_html.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Customer product card. [bookingsEnabled] is false on the creator review step.
class ProductOfferBox extends StatelessWidget {
  const ProductOfferBox({
    super.key,
    required this.shop,
    required this.product,
    required this.quote,
    required this.recommended,
    required this.lightest,
    required this.openRooms,
    required this.onBook,
    this.bookingsEnabled = true,
    this.coverBytes,
  });

  final DiveShop shop;
  final ShopProduct product;
  final TourPriceQuote quote;
  final bool recommended;
  final bool lightest;
  final int openRooms;
  final ValueChanged<String> onBook;
  final bool bookingsEnabled;
  final Uint8List? coverBytes;

  static final _price = NumberFormat('#,###', 'en_US');

  bool get _showsCardPrice =>
      product.openEmptySeats ||
      product.listingKind == ProductListingKind.curated ||
      product.listingKind == ProductListingKind.diverPlanned;

  bool get _showsPeakFrom =>
      product.hasPeakSeasons &&
      product.lowestDiverPrice(professional: quote.isProfessional) > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lastCall = shop.departure?.lastCall == true;
    final duration = localizedDurationLabel(
      l10n,
      product.derivedDurationLabel,
    );
    final span = <String>[
      if (duration.isNotEmpty) duration,
      if (product.diveCount > 0) l10n.exploreBoatDives(product.diveCount),
    ].join(' · ');
    final status = <String>[
      if (product.difficulty.trim().isNotEmpty) product.difficulty.trim(),
      if (recommended) l10n.exploreRecommended,
      if (lightest && !recommended) l10n.exploreLightest,
      if (!_showsCardPrice) l10n.exploreAlwaysBookable,
      if (lastCall) l10n.communityKindLast,
    ].join(' · ');

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: lastCall ? const Color(0xFFCF3B18) : const Color(0xFFE3DED3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ListingCoverPhoto(shop: shop, bytes: coverBytes),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.productName,
                        style: const TextStyle(
                          color: Color(0xFF10242F),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      if (span.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          span,
                          style: const TextStyle(
                            color: Color(0xFF5B6B75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Color(0xFF0A6B64),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (_showsCardPrice) ...[
                        const SizedBox(height: 6),
                        _listedPrice(
                          l10n,
                          amount: quote.amount,
                          fromPeak: _showsPeakFrom,
                          style: const TextStyle(
                            color: Color(0xFF10242F),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _OfferFacts(
              product: product,
              book: _hasOptionRows
                  ? null
                  : FilledButton(
                      key: Key('shop-book-${shop.id}'),
                      onPressed: bookingsEnabled ? () => onBook('') : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B2A3C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.exploreBook),
                    ),
            ),
            if (shop.blurb.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                shop.blurb,
                style: const TextStyle(color: Color(0xFF5B6B75), fontSize: 13),
              ),
            ],
            if (shop.departure != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.exploreDepartureLine(
                  shop.departure!.windowLabel,
                  shop.departure!.emptySeats,
                ),
                style: const TextStyle(
                  color: Color(0xFF0A6B64),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
            if (openRooms > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.exploreProductRooms(openRooms),
                style: const TextStyle(color: Color(0xFF5B6B75), fontSize: 12),
              ),
            ],
            if (_hasOptionRows) ...[
              const SizedBox(height: 12),
              _offerRow(
                context,
                title: product.name,
                note: _packageNote,
                price: quote.amount,
                showPrice: _showsCardPrice,
                fromPeak: _showsPeakFrom,
                button: l10n.optionBookPackage,
                buttonKey: Key('shop-book-${shop.id}'),
                onPressed: () => onBook(''),
              ),
              for (final option in _addons) ...[
                const SizedBox(height: 8),
                _offerRow(
                  context,
                  title: option.name,
                  note: option.description,
                  price: _optionPrice(option),
                  showPrice: _showsCardPrice,
                  button: l10n.optionBookAddon,
                  buttonKey: Key('shop-book-addon-${option.id}'),
                  onPressed: () => onBook(option.id),
                ),
              ],
              for (final option in _individuals) ...[
                const SizedBox(height: 8),
                _offerRow(
                  context,
                  title: option.name,
                  note: option.description,
                  price: _optionPrice(option),
                  showPrice: _showsCardPrice,
                  button: l10n.optionBookIndividual,
                  buttonKey: Key('shop-book-individual-${option.id}'),
                  onPressed: () => onBook(option.id),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<ShopProductOption> get _addons => [
    for (final option in product.options)
      if (option.bookable && option.kind == ProductOptionKind.addon) option,
  ];

  List<ShopProductOption> get _individuals => [
    for (final option in product.options)
      if (option.bookable && option.kind == ProductOptionKind.individual)
        option,
  ];

  bool get _hasOptionRows => _addons.isNotEmpty || _individuals.isNotEmpty;

  String get _packageNote {
    final cancel = product.cancellationNote.trim();
    if (cancel.isNotEmpty) {
      return cancel;
    }
    for (final line in product.includes.split('\n')) {
      if (line.trim().isNotEmpty) {
        return line.trim();
      }
    }
    return '';
  }

  int _optionPrice(ShopProductOption option) {
    if (!quote.isProfessional) {
      return option.consumerPrice;
    }
    return TourPricePolicy.shownUnit(
      consumer: option.consumerPrice,
      professional: option.professionalPrice,
    );
  }

  Widget _listedPrice(
    AppLocalizations l10n, {
    required int amount,
    required TextStyle style,
    required bool fromPeak,
  }) {
    if (!fromPeak) {
      return Text(
        l10n.explorePriceWon(_price.format(amount)),
        style: style,
      );
    }
    final lowest = product.lowestDiverPrice(
      professional: quote.isProfessional,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PeakSeasonBadge(label: l10n.explorePeakSeasonBadge),
        const SizedBox(height: 4),
        Text(
          l10n.explorePriceFrom(l10n.explorePriceWon(_price.format(lowest))),
          style: style.copyWith(color: const Color(0xFF0A4A73)),
        ),
      ],
    );
  }

  Widget _offerRow(
    BuildContext context, {
    required String title,
    required String note,
    required int price,
    required bool showPrice,
    bool fromPeak = false,
    required String button,
    required Key buttonKey,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (showPrice)
                  Expanded(
                    child: _listedPrice(
                      l10n,
                      amount: price,
                      fromPeak: fromPeak,
                      style: (theme.textTheme.titleMedium ?? const TextStyle())
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  )
                else
                  const Spacer(),
                FilledButton(
                  key: buttonKey,
                  onPressed: bookingsEnabled ? onPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2A3C),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(button),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeakSeasonBadge extends StatelessWidget {
  const _PeakSeasonBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4EBD3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A5A2B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed trip facts on the resort product card.
class _OfferFacts extends StatefulWidget {
  const _OfferFacts({required this.product, this.book});

  final ShopProduct product;
  final Widget? book;

  @override
  State<_OfferFacts> createState() => _OfferFactsState();
}

class _OfferFactsState extends State<_OfferFacts> {
  var _open = false;

  bool get _hasFacts {
    final product = widget.product;
    return product.derivedDurationLabel.trim().isNotEmpty ||
        product.meetingPoint.trim().isNotEmpty ||
        product.schedule.trim().isNotEmpty ||
        product.storyHtml.trim().isNotEmpty ||
        product.storyBlocks.isNotEmpty ||
        product.includes.trim().isNotEmpty ||
        product.excludes.trim().isNotEmpty ||
        product.cancellationNote.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = widget.product;
    final book = widget.book;
    if (!_hasFacts && book == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_hasFacts)
              TextButton(
                key: Key('product-offer-details-${product.id}'),
                onPressed: () => setState(() => _open = !_open),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.productOfferDetails),
              ),
            if (book != null) ...[
              if (_hasFacts) const SizedBox(width: 8),
              Expanded(child: book),
            ],
          ],
        ),
        if (_open) ...[
          _fact(
            l10n.productOfferNights,
            localizedDurationLabel(l10n, product.derivedDurationLabel),
          ),
          _fact(l10n.productFormMeetingPoint, product.meetingPoint),
          if (product.storyHtml.trim().isNotEmpty)
            _storyHtml(
              l10n.creatorWizardStepSchedule,
              product.storyHtml.trim(),
              Key('product-offer-story-html-${product.id}'),
            )
          else if (product.storyBlocks.isNotEmpty)
            Padding(
              key: Key('product-offer-story-${product.id}'),
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.creatorWizardStepSchedule,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  StoryBlockView(blocks: product.storyBlocks),
                ],
              ),
            )
          else if (product.schedule.trim().isNotEmpty)
            _markdown(
              l10n.creatorWizardStepSchedule,
              product.schedule.trim(),
              Key('product-offer-schedule-${product.id}'),
            ),
          _fact(l10n.productFormIncludes, product.includes),
          _fact(l10n.productFormExcludes, product.excludes),
          _fact(l10n.productFormCancelNote, product.cancellationNote),
        ],
      ],
    );
  }

  Widget _fact(String title, String body) {
    final text = body.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _markdown(String title, String markdown, Key key) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          MarkdownBody(
            data: markdown,
            shrinkWrap: true,
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _storyHtml(String title, String html, Key key) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodySmall;
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          ProductStoryHtmlBody(html: html, textStyle: body),
        ],
      ),
    );
  }
}

/// Guest story HTML body: same video player and http(s) link handling as the
/// product offer box.
class ProductStoryHtmlBody extends StatelessWidget {
  const ProductStoryHtmlBody({
    super.key,
    required this.html,
    this.textStyle,
  });

  final String html;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      textStyle: textStyle,
      customWidgetBuilder: (element) {
        if (element.localName?.toLowerCase() != 'video') {
          return null;
        }
        final src = (element.attributes['src'] ?? '').trim();
        if (src.isEmpty || !isAllowedStoryVideoUrl(src)) {
          return null;
        }
        return StoryBlockView(
          blocks: [
            StoryBlock(kind: StoryBlockKind.video, url: src),
          ],
        );
      },
      onTapUrl: (url) {
        final uri = Uri.tryParse(url.trim());
        if (uri == null) {
          return true;
        }
        final scheme = uri.scheme.toLowerCase();
        if (scheme != 'http' && scheme != 'https') {
          return true;
        }
        unawaited(
          launchUrl(uri, mode: LaunchMode.externalApplication),
        );
        return true;
      },
    );
  }
}

/// Light customer card with booking turned off, for the creator review step.
class ProductOfferPreview extends StatelessWidget {
  const ProductOfferPreview({
    super.key,
    required this.shop,
    required this.product,
    required this.quote,
    this.coverBytes,
  });

  final DiveShop shop;
  final ShopProduct product;
  final TourPriceQuote quote;
  final Uint8List? coverBytes;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: ProductOfferBox(
        shop: shop,
        product: product,
        quote: quote,
        recommended: false,
        lightest: false,
        openRooms: 0,
        onBook: (_) {},
        bookingsEnabled: false,
        coverBytes: coverBytes,
      ),
    );
  }
}
