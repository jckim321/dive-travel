import 'package:dive_travel_app/core/models/seat_life.dart';

/// First local day `seat_events` exist. Earlier days are not in that log.
final seatEventRecordingStart = DateTime(2026, 10, 27);

enum SeatBriefPreset { today, sevenDays, thirtyDays, thisYear, custom }

/// Inclusive [start], exclusive [end]. Both are local midnights.
class SeatBriefWindow {
  const SeatBriefWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
}

DateTime seatBriefDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

SeatBriefWindow seatBriefWindow({
  required SeatBriefPreset preset,
  required DateTime now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final today = seatBriefDateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));
  switch (preset) {
    case SeatBriefPreset.today:
      return SeatBriefWindow(start: today, end: tomorrow);
    case SeatBriefPreset.sevenDays:
      return SeatBriefWindow(
        start: today.subtract(const Duration(days: 6)),
        end: tomorrow,
      );
    case SeatBriefPreset.thirtyDays:
      return SeatBriefWindow(
        start: today.subtract(const Duration(days: 29)),
        end: tomorrow,
      );
    case SeatBriefPreset.thisYear:
      return SeatBriefWindow(start: DateTime(today.year, 1, 1), end: tomorrow);
    case SeatBriefPreset.custom:
      var start = seatBriefDateOnly(customStart ?? today);
      var endDay = seatBriefDateOnly(customEnd ?? today);
      if (endDay.isBefore(start)) {
        final swap = start;
        start = endDay;
        endDay = swap;
      }
      return SeatBriefWindow(
        start: start,
        end: endDay.add(const Duration(days: 1)),
      );
  }
}

/// The window of the same length immediately before [window].
SeatBriefWindow seatBriefPreviousWindow(SeatBriefWindow window) {
  final length = window.end.difference(window.start);
  return SeatBriefWindow(
    start: window.start.subtract(length),
    end: window.start,
  );
}

bool seatBriefBeforeRecording(SeatBriefWindow window) =>
    window.start.isBefore(seatEventRecordingStart);

String seatBriefRangeLabel(SeatBriefWindow window) {
  final last = window.end.subtract(const Duration(days: 1));
  String two(int value) => value.toString().padLeft(2, '0');
  final start =
      '${window.start.year}.${two(window.start.month)}.${two(window.start.day)}';
  final end = window.start.year == last.year
      ? '${two(last.month)}.${two(last.day)}'
      : '${last.year}.${two(last.month)}.${two(last.day)}';
  return '$start ~ $end';
}

class SeatBriefFunnel {
  const SeatBriefFunnel({
    required this.opens,
    required this.views,
    required this.flags,
    required this.pays,
  });

  static const empty = SeatBriefFunnel(opens: 0, views: 0, flags: 0, pays: 0);

  final int opens;
  final int views;
  final int flags;
  final int pays;

  int get viewsPerOpen => opens == 0 ? 0 : views ~/ opens;

  int get flagPercent => views == 0 ? 0 : flags * 100 ~/ views;

  int get payPercent => flags == 0 ? 0 : pays * 100 ~/ flags;
}

SeatBriefFunnel seatBriefFunnel(Iterable<SeatLifeEvent> events) {
  var opens = 0;
  var views = 0;
  var flags = 0;
  var pays = 0;
  for (final event in events) {
    switch (event.kind) {
      case 'open':
        opens += 1;
      case 'view':
        views += 1;
      case 'flag':
        flags += 1;
      case 'pay':
        pays += 1;
    }
  }
  return SeatBriefFunnel(opens: opens, views: views, flags: flags, pays: pays);
}

String seatBriefDeltaLabel(int current, int previous) {
  final delta = current - previous;
  if (delta > 0) {
    return '+$delta';
  }
  return '$delta';
}
