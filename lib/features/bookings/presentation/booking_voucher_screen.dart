import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/booking_public_code.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_voucher_logic.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> openBookingVoucher(BuildContext context, TourBooking booking) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => BookingVoucherScreen(booking: booking),
    ),
  );
}

/// Full-screen travel voucher — open anytime and save to the phone for field use.
class BookingVoucherScreen extends StatefulWidget {
  const BookingVoucherScreen({super.key, required this.booking});

  final TourBooking booking;

  @override
  State<BookingVoucherScreen> createState() => _BookingVoucherScreenState();
}

class _BookingVoucherScreenState extends State<BookingVoucherScreen> {
  final _boundaryKey = GlobalKey();
  var _saving = false;
  TourBooking? _saved;
  DiverStore? _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureShopStatsLoaded());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DiverStoreScope.of(context);
    if (!identical(next, _store)) {
      _store?.removeListener(_onStore);
      _store = next;
      next.addListener(_onStore);
    }
  }

  void _onStore() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_onStore);
    super.dispose();
  }

  static final _money = NumberFormat('#,###', 'en_US');
  static final _day = DateFormat('yyyy.MM.dd');
  static final _clock = DateFormat('HH:mm');

  TourBooking _shown() {
    TourBooking? live;
    for (final item in DiverStoreScope.of(context).bookings) {
      if (item.id == widget.booking.id) {
        live = item;
        break;
      }
    }
    final saved = _saved;
    if (saved != null &&
        (live == null ||
            live.arrivalFlight != saved.arrivalFlight ||
            live.returnFlight != saved.returnFlight ||
            live.arrivalAt != saved.arrivalAt)) {
      return saved;
    }
    return live ?? widget.booking;
  }

  String _partyLine(AppLocalizations l10n, TourBooking booking) {
    final party = booking.hasPartyDetail
        ? l10n.bookingVoucherPartySummary(
            booking.divers,
            booking.nondivers,
            booking.children,
            booking.infants,
          )
        : (booking.partySize > 0 ? '${booking.partySize}' : '');
    if (booking.singleRooms < 1) {
      return party;
    }
    final rooms = l10n.bookingSingleRooms(booking.singleRooms);
    if (party.isEmpty) {
      return rooms;
    }
    return '$party · $rooms';
  }

  String _arrivalValue(TourBooking booking) {
    final at = booking.arrivalAt?.toLocal();
    final clock = at == null ? '' : _clock.format(at);
    final flight = booking.arrivalFlight.trim();
    final body = clock.isNotEmpty && flight.isNotEmpty
        ? '$clock · $flight'
        : (clock.isNotEmpty ? clock : flight);
    if (at == null || _sameCalendarDay(at, booking.scheduledFor)) {
      return body;
    }
    return '${_md(at)} 도착 $body';
  }

  bool _sameCalendarDay(DateTime arrival, DateTime depart) {
    final start = depart.toLocal();
    return arrival.year == start.year &&
        arrival.month == start.month &&
        arrival.day == start.day;
  }

  String _md(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$month.$date';
  }

  Future<void> _tellFlight(TourBooking booking) async {
    final draft = await showModalBottomSheet<_FlightDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FlightSheet(booking: booking),
    );
    if (draft == null || !mounted) {
      return;
    }
    try {
      await DiverStoreScope.of(context).updateBookingFlight(
        bookingId: booking.id,
        arrivalFlight: draft.arrivalFlight,
        arrivalAt: draft.arrivalAt,
        returnFlight: draft.returnFlight,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = booking.copyWith(
          arrivalFlight: draft.arrivalFlight.trim().toUpperCase(),
          arrivalAt: draft.arrivalAt,
          clearArrivalAt: draft.arrivalAt == null,
          returnFlight: draft.returnFlight.trim().toUpperCase(),
        );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _saveToPhone() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        return;
      }
      final png = bytes.buffer.asUint8List();
      final name =
          'dive-travel-voucher-${widget.booking.id}.png'.replaceAll(' ', '_');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: name),
          ],
          fileNameOverrides: [name],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingVoucherSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final booking = _shown();
    final partyLine = _partyLine(l10n, booking);
    final localContact = (DiverStoreScope.of(context)
                .liveStatsFor(booking.shopId)
                ?.localContact ??
            '')
        .trim();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: Text(l10n.bookingVoucherTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E8EC)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIVE TRAVEL',
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ocean,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.bookingVoucherTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          booking.productLabel,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (booking.partyLines.isEmpty &&
                            booking.optionLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            booking.optionLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _row(
                          l10n.bookingVoucherId,
                          bookingPublicLabel(
                            publicCode: booking.publicCode,
                            bookingId: booking.id,
                          ),
                        ),
                        _row(l10n.bookingVoucherShop, booking.shopName),
                        if (localContact.isNotEmpty)
                          _row(l10n.bookingVoucherLocalContact, localContact),
                        _row(
                          l10n.workbenchDepartureDate,
                          _day.format(booking.scheduledFor),
                        ),
                        if (booking.arrivalAt != null ||
                            booking.arrivalFlight.trim().isNotEmpty)
                          _arrivalLine(booking),
                        if (booking.returnFlight.trim().isNotEmpty)
                          _row('오는 편', booking.returnFlight.trim()),
                        if (partyLine.isNotEmpty)
                          _row(l10n.checkoutGuests, partyLine),
                        if (booking.guestDisplayName.trim().isNotEmpty)
                          _row(
                            l10n.checkoutGuestName,
                            booking.guestDisplayName.trim(),
                          ),
                        if (booking.guestContact.trim().isNotEmpty)
                          _row(
                            l10n.checkoutGuestContact,
                            booking.guestContact.trim(),
                          ),
                        _row(
                          l10n.checkoutStepPay,
                          l10n.explorePriceWon(_money.format(booking.price)),
                        ),
                        _row(
                          l10n.bookingVoucherPaymentStatus,
                          l10n.bookingPaymentCaptured,
                        ),
                        if (booking.partyLines.isNotEmpty) ...[
                          const Divider(height: 28),
                          for (final line in booking.partyLines)
                            if (bookingPartyLineLabel(l10n, line).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        bookingPartyLineLabel(l10n, line),
                                      ),
                                    ),
                                    Text(_money.format(line.amount)),
                                  ],
                                ),
                              ),
                          for (final line in bookingVoucherAddonLines(booking))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(line.label)),
                                  Text(_money.format(line.amount)),
                                ],
                              ),
                            ),
                        ] else if (booking.quoteLines.isNotEmpty) ...[
                          const Divider(height: 28),
                          for (final line in booking.quoteLines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(line.label)),
                                  Text(_money.format(line.amount)),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            elevation: 8,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (booking.isActive) ...[
                    OutlinedButton.icon(
                      key: const Key('booking-voucher-flight'),
                      onPressed: () => _tellFlight(booking),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppTheme.navy,
                      ),
                      icon: const Icon(Icons.flight_rounded),
                      label: const Text('내 항공편 알리기'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton.icon(
                key: const Key('booking-voucher-save'),
                onPressed: _saving ? null : _saveToPhone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.bookingVoucherSave),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrivalLine(TourBooking booking) {
    final value = _arrivalValue(booking);
    final at = booking.arrivalAt?.toLocal();
    if (at != null && !_sameCalendarDay(at, booking.scheduledFor)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    return _row('도착', value);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightDraft {
  const _FlightDraft({
    required this.arrivalFlight,
    required this.arrivalAt,
    required this.returnFlight,
  });

  final String arrivalFlight;
  final DateTime? arrivalAt;
  final String returnFlight;
}

class _FlightSheet extends StatefulWidget {
  const _FlightSheet({required this.booking});

  final TourBooking booking;

  @override
  State<_FlightSheet> createState() => _FlightSheetState();
}

class _FlightSheetState extends State<_FlightSheet> {
  late final TextEditingController _arrival;
  late final TextEditingController _returning;
  TimeOfDay? _time;
  var _dayOffset = 0;
  static final _day = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    _arrival = TextEditingController(text: widget.booking.arrivalFlight);
    _returning = TextEditingController(text: widget.booking.returnFlight);
    final at = widget.booking.arrivalAt;
    if (at != null) {
      final local = at.toLocal();
      _time = TimeOfDay(hour: local.hour, minute: local.minute);
      final saved = DateTime(local.year, local.month, local.day);
      _dayOffset = saved.difference(_departDay()).inDays;
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    _returning.dispose();
    super.dispose();
  }

  DateTime _departDay() {
    final day = widget.booking.scheduledFor.toLocal();
    return DateTime(day.year, day.month, day.day);
  }

  DateTime _arrivalDay() => _departDay().add(Duration(days: _dayOffset));

  DateTime? _arrivalAt() {
    final time = _time;
    if (time == null) {
      return null;
    }
    final day = _arrivalDay();
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final clock = _time == null ? '시간 선택' : _time!.format(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '내 항공편 알리기',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '도착일은 출발일부터 이틀 뒤까지 고를 수 있어요.',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _arrival,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(
              labelText: '편명',
              hintText: 'KE629',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var offset = 0; offset < 3; offset++) ...[
                if (offset > 0) const SizedBox(width: 8),
                Expanded(child: _dayChoice(offset)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('booking-flight-time'),
                  onPressed: _pickTime,
                  child: Text('${_day.format(_arrivalDay())} $clock'),
                ),
              ),
              if (_time != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '시간 지우기',
                  onPressed: () => setState(() => _time = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _returning,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(
              labelText: '오는 편',
              hintText: 'KE630',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('booking-flight-save'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.navy,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () {
              Navigator.of(context).pop(
                _FlightDraft(
                  arrivalFlight: _arrival.text,
                  arrivalAt: _arrivalAt(),
                  returnFlight: _returning.text,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _dayChoice(int offset) {
    final selected = _dayOffset == offset;
    final day = _departDay().add(Duration(days: offset));
    final title = offset == 0 ? '출발일' : '+$offset일';
    return OutlinedButton(
      key: Key('booking-flight-day-$offset'),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : AppTheme.navy,
        backgroundColor: selected ? AppTheme.navy : Colors.white,
        side: const BorderSide(color: AppTheme.navy),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      onPressed: () => setState(() => _dayOffset = offset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          Text(
            _day.format(day),
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
