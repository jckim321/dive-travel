import 'dart:math';

/// Letters and digits that stay distinct when read aloud.
const bookingPublicAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// `DT-MMDD-XXXX` from the device clock used to create the booking.
String bookingPublicCode(DateTime createdAt, {Random? random}) {
  final month = createdAt.month.toString().padLeft(2, '0');
  final day = createdAt.day.toString().padLeft(2, '0');
  final roll = random ?? Random();
  final suffix = StringBuffer();
  for (var i = 0; i < 4; i++) {
    suffix.write(
      bookingPublicAlphabet[roll.nextInt(bookingPublicAlphabet.length)],
    );
  }
  return 'DT-$month$day-$suffix';
}

/// Readable booking number. Old rows without [publicCode] show the document id.
String bookingPublicLabel({
  required String publicCode,
  required String bookingId,
}) {
  final code = publicCode.trim();
  if (code.isNotEmpty) {
    return code;
  }
  if (bookingId.length > 8) {
    return bookingId.substring(0, 8);
  }
  return bookingId;
}
