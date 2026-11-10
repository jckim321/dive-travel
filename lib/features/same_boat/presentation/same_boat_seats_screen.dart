import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seat_open_fields.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Creator UI: open leftover seats on a product (base package and/or individual SKUs).
/// An open seat is listed immediately. Hidden and rejected seats keep their status.
class SameBoatSeatsScreen extends StatefulWidget {
  const SameBoatSeatsScreen({
    super.key,
    required this.product,
    this.adminBypassApproval = false,
    this.basePackageOnly = false,
    this.partnerLiveCopy = false,
  });

  final ShopProduct product;

  /// Admin curated/specials can publish straight to the board.
  final bool adminBypassApproval;

  /// Partner open-seats path: hide option/individual slots; edit package only.
  final bool basePackageOnly;

  /// Partner H1a copy (빈자리 열기) instead of approval-request strings.
  final bool partnerLiveCopy;

  @override
  State<SameBoatSeatsScreen> createState() => _SameBoatSeatsScreenState();
}

class _SameBoatSeatsScreenState extends State<SameBoatSeatsScreen> {
  SameBoatSeatOpenController? _seats;
  ShopProduct? _freshProduct;
  var _saving = false;
  var _loadingFresh = false;

  ShopProduct get _blockProduct => _freshProduct ?? widget.product;

  bool _approvedLive(ShopProduct product) {
    return !product.hasPendingSameBoat &&
        product.sameBoatStatus == SameBoatStatus.approved &&
        product.listsOnSameBoat;
  }

  bool get _partnerBlocked {
    if (widget.adminBypassApproval) {
      return false;
    }
    final product = _blockProduct;
    if (widget.partnerLiveCopy && _approvedLive(product)) {
      return false;
    }
    return SameBoatSeatOpenLogic.blocksPartnerRequest(product);
  }

  String? get _partnerBlockReason {
    if (!widget.partnerLiveCopy || !_partnerBlocked) {
      return null;
    }
    if (_blockProduct.hasPendingSameBoat) {
      return '승인 대기 중이라 수정할 수 없어요';
    }
    return '이미 열려 있어 수정할 수 없어요';
  }

  bool _isCreatorSeatOpen(DiverStore store) {
    if (widget.adminBypassApproval || widget.partnerLiveCopy) {
      return false;
    }
    final uid = store.uid ?? '';
    return uid.isNotEmpty && widget.product.submittedByUid == uid;
  }

  List<SameBoatOptionSeatSlot> _slotsFor(ShopProduct product) {
    final slots = <SameBoatOptionSeatSlot>[];
    if (widget.basePackageOnly) {
      return slots;
    }
    for (final o in product.options) {
      if (o.kind == ProductOptionKind.individual ||
          o.kind == ProductOptionKind.basePackage ||
          o.openEmptySeats ||
          o.sameBoatStatus != SameBoatStatus.closed) {
        slots.add(SameBoatOptionSeatSlot(id: o.id, name: o.name));
      }
    }
    final seen = {for (final s in slots) s.id};
    for (final o in product.options) {
      if (o.kind == ProductOptionKind.individual && !seen.contains(o.id)) {
        slots.add(SameBoatOptionSeatSlot(id: o.id, name: o.name));
      }
    }
    return slots;
  }

  SameBoatSeatOpenController _controllerFor(ShopProduct product) {
    return SameBoatSeatOpenController(
      existing: product,
      optionSlots: _slotsFor(product),
      isAdmin: widget.adminBypassApproval,
      partnerLiveEdit: widget.partnerLiveCopy && _approvedLive(product),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.partnerLiveCopy) {
      _loadingFresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_loadFresh());
      });
      return;
    }
    _seats = _controllerFor(widget.product);
  }

  Future<void> _loadFresh() async {
    if (!mounted) {
      return;
    }
    var source = widget.product;
    try {
      source = await DiverStoreScope.of(context).requireFreshShopProduct(
        shopId: widget.product.shopId,
        productId: widget.product.id,
      );
    } catch (_) {
      source = widget.product;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _freshProduct = source;
      _seats = _controllerFor(source);
      _loadingFresh = false;
    });
  }

  @override
  void dispose() {
    _seats?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final seats = _seats;
    if (seats == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (_partnerBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product.hasPendingSameBoat
                ? l10n.sameBoatSeatsAlreadyPending
                : l10n.sameBoatSeatsAlreadyLive,
          ),
        ),
      );
      return;
    }
    seats.isAdmin = widget.adminBypassApproval;
    final early = seats.validate(l10n, now: DateTime.now());
    if (early != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(early)));
      return;
    }

    setState(() => _saving = true);
    try {
      final base = await store.requireFreshShopProduct(
        shopId: widget.product.shopId,
        productId: widget.product.id,
      );
      final error = seats.validate(l10n, now: DateTime.now(), countsFrom: base);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
      final next = seats.applyToProduct(base);
      final creatorOpen = _isCreatorSeatOpen(store);
      if (creatorOpen) {
        await store.openCreatorSeats(product: next);
      } else {
        await store.saveShopProduct(
          shopId: next.shopId,
          product: next,
          intent: ProductSaveIntent.preserveListing,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creatorOpen
                ? l10n.creatorOpenSeatsSnack
                : widget.partnerLiveCopy
                    ? l10n.partnerSeatsOpenedSnack
                    : widget.adminBypassApproval
                        ? l10n.sameBoatSeatsPublished
                        : l10n.sameBoatSeatsSubmitted,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final waiting = _partnerBlocked && widget.product.hasPendingSameBoat;
    final partnerCopy = widget.partnerLiveCopy;
    final creatorOpen = _isCreatorSeatOpen(store);
    final seats = _seats;
    if (partnerCopy && ( _loadingFresh || seats == null)) {
      return _partnerChrome(
        context,
        Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0B1F33),
            surfaceTintColor: Colors.white,
            leading: const PartnerBackButton(),
            title: Text(l10n.partnerOpenSeatsTitle),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final ready = seats!;
    final fields = IgnorePointer(
      ignoring: _partnerBlocked,
      child: Opacity(
        opacity: _partnerBlocked ? 0.55 : 1,
        child: SameBoatSeatOpenFields(
          controller: ready,
          partnerChrome: partnerCopy,
          onChanged: () => setState(() {}),
        ),
      ),
    );
    final submit = FilledButton(
      key: const Key('same-boat-seats-submit'),
      style: partnerCopy
          ? FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B2A3C),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            )
          : null,
      onPressed: (_saving || _partnerBlocked) ? null : _submit,
      child: Text(
        waiting
            ? l10n.sameBoatSeatsWaiting
            : partnerCopy
                ? l10n.partnerSeatsOpenButton
                : creatorOpen
                    ? l10n.creatorOpenSeatsButton
                    : widget.adminBypassApproval
                        ? l10n.sameBoatSeatsPublish
                        : l10n.sameBoatSeatsSubmit,
      ),
    );
    final page = Scaffold(
      backgroundColor: partnerCopy ? const Color(0xFFF4F6F9) : null,
      appBar: AppBar(
        backgroundColor: partnerCopy ? Colors.white : null,
        foregroundColor: partnerCopy ? const Color(0xFF0B1F33) : null,
        surfaceTintColor: partnerCopy ? Colors.white : null,
        leading: partnerCopy ? const PartnerBackButton() : null,
        title: Text(
          partnerCopy ? l10n.partnerOpenSeatsTitle : l10n.sameBoatSeatsTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_partnerBlockReason != null) ...[
            Text(
              _partnerBlockReason!,
              style: const TextStyle(
                color: Color(0xFF0B1F33),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            partnerCopy ? l10n.partnerSeatsOpenHint : l10n.sameBoatSeatsHint,
            style: partnerCopy
                ? const TextStyle(color: Color(0xFF52606D), fontSize: 13)
                : Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: partnerCopy
                ? const TextStyle(
                    color: Color(0xFF0B1F33),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (!partnerCopy) ...[
            fields,
            const SizedBox(height: 24),
            submit,
          ] else
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                final form = <Widget>[
                  fields,
                  const SizedBox(height: 24),
                  submit,
                ];
                final aside = <Widget>[
                  _PartnerSeatPreview(
                    product: widget.product,
                    shopName: store.shopLabelFor(widget.product.shopId),
                    seats: ready,
                  ),
                  const SizedBox(height: 20),
                  _PartnerSeatHistory(
                    products: store.productsForShop(widget.product.shopId),
                    now: DateTime.now(),
                  ),
                ];
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...form, const SizedBox(height: 20), ...aside],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: form,
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 380,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: aside,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
    if (!partnerCopy) {
      return page;
    }
    return _partnerChrome(context, page);
  }
}

Widget _partnerChrome(BuildContext context, Widget child) {
  return Theme(
    data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0B1F33),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF0B1F33),
        displayColor: const Color(0xFF0B1F33),
      ),
    ),
    child: child,
  );
}

class _PartnerSeatPreview extends StatelessWidget {
  const _PartnerSeatPreview({
    required this.product,
    required this.shopName,
    required this.seats,
  });

  final ShopProduct product;
  final String shopName;
  final SameBoatSeatOpenController seats;

  static final _price = NumberFormat('#,###', 'en_US');
  static const _days = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final departure = seats.packageDeparture;
    final flag = seats.packageFlagClose;
    final capacity = int.tryParse(seats.packageCapacity.text.trim()) ?? 0;
    final booked = seats.packageReferenceBooked;
    final open = capacity - booked;
    final openSeats = open < 0 ? 0 : open;
    String monthDay(DateTime date) => '${date.month}/${date.day}';
    String withWeekday(DateTime date) =>
        '${monthDay(date)} (${_days[date.weekday - 1]})';
    final dep = departure == null ? '출발일 없음' : '${withWeekday(departure)} 출발';
    final flagLine = flag == null ? '깃발 마감일 없음' : '깃발 마감 ${monthDay(flag)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '손님에게 보이는 카드',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0B1F33),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '리조트 빈자리 구역에 이렇게 보여요',
                style: TextStyle(fontSize: 12, color: Color(0xFF52606D)),
              ),
              const SizedBox(height: 6),
              if (shopName.isNotEmpty)
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A6B64),
                  ),
                ),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1F33),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₩${_price.format(product.consumerPrice)}~',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1F33),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dep,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1F33),
                ),
              ),
              Text(
                booked > 0
                    ? '결제 $booked · 빈자리 $openSeats개'
                    : '빈자리 $openSeats개',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A6B64),
                ),
              ),
              Text(
                flagLine,
                style: const TextStyle(fontSize: 12, color: Color(0xFF52606D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartnerSeatHistory extends StatelessWidget {
  const _PartnerSeatHistory({required this.products, required this.now});

  final List<ShopProduct> products;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String tag})>[];
    for (final product in products) {
      final tag = _historyTag(product, now);
      if (tag == null) {
        continue;
      }
      rows.add((label: _historyLabel(product), tag: tag));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '내 빈자리 기록',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0B1F33),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          child: rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    '지난 빈자리 기록이 없어요',
                    style: TextStyle(fontSize: 13, color: Color(0xFF52606D)),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: i == rows.length - 1
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: Color(0xFFDDE3EA)),
                                ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                rows[i].label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B1F33),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2F6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                rows[i].tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF52606D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String? _historyTag(ShopProduct product, DateTime now) {
  final touched = product.openEmptySeats ||
      product.sameBoatOpenedAt != null ||
      product.bookedSeats > 0;
  if (!touched) {
    return null;
  }
  final full = product.capacity > 0 && product.bookedSeats >= product.capacity;
  if (full) {
    return '마감';
  }
  final departure = product.departureStart;
  final today = DateTime(now.year, now.month, now.day);
  final past = departure != null &&
      DateTime(departure.year, departure.month, departure.day).isBefore(today);
  final stopped = !product.openEmptySeats ||
      product.sameBoatStatus == SameBoatStatus.closed ||
      product.sameBoatStatus == SameBoatStatus.hidden ||
      product.sameBoatStatus == SameBoatStatus.rejected;
  if (past || stopped) {
    return '종료';
  }
  return null;
}

String _historyLabel(ShopProduct product) {
  final departure = product.departureStart;
  final when = departure == null
      ? product.name
      : '${departure.month}/${departure.day} 출발';
  if (product.capacity > 0 && product.bookedSeats >= product.capacity) {
    return '$when · ${product.capacity}자리 모두 참';
  }
  if (product.bookedSeats > 0 && product.capacity > 0) {
    return '$when · ${product.capacity}자리 중 ${product.bookedSeats} 참';
  }
  if (product.capacity > 0) {
    return '$when · ${product.capacity}자리';
  }
  return when;
}
