import 'package:flutter/material.dart';

/// Two-step calendar: departure, then return. One month at a time with arrows.
///
/// Returns null when either step is cancelled. Cancelling the return step
/// discards the departure pick (callers keep their previous values).
Future<({DateTime start, DateTime end})?> pickPlannerDateRange({
  required BuildContext context,
  DateTime? previousStart,
  DateTime? previousEnd,
}) async {
  final now = DateTime.now().toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final lastDate = DateTime(today.year + 5, 12, 31);
  var initialStart = previousStart ?? today;
  if (initialStart.isBefore(today)) {
    initialStart = today;
  }
  if (initialStart.isAfter(lastDate)) {
    initialStart = lastDate;
  }
  final departure = await showDatePicker(
    context: context,
    locale: const Locale('ko'),
    firstDate: today,
    lastDate: lastDate,
    initialDate: initialStart,
    initialEntryMode: DatePickerEntryMode.calendar,
    helpText: '출발일 선택',
    cancelText: '취소',
    confirmText: '확인',
  );
  if (departure == null || !context.mounted) {
    return null;
  }
  final departureDay = DateTime(
    departure.year,
    departure.month,
    departure.day,
  );
  var initialEnd = previousEnd ?? departureDay;
  if (initialEnd.isBefore(departureDay)) {
    initialEnd = departureDay;
  }
  if (initialEnd.isAfter(lastDate)) {
    initialEnd = lastDate;
  }
  final returnDay = await showDatePicker(
    context: context,
    locale: const Locale('ko'),
    firstDate: departureDay,
    lastDate: lastDate,
    initialDate: initialEnd,
    initialEntryMode: DatePickerEntryMode.calendar,
    helpText: '귀국일 선택',
    cancelText: '취소',
    confirmText: '확인',
  );
  if (returnDay == null || !context.mounted) {
    // Step-2 cancel keeps prior start/end; departure pick is discarded.
    return null;
  }
  return (
    start: departureDay,
    end: DateTime(returnDay.year, returnDay.month, returnDay.day),
  );
}
