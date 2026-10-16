import 'package:dive_travel_app/core/models/shop_product.dart';

class BookingLine {
  const BookingLine({
    required this.label,
    required this.amount,
  });

  final String label;
  final int amount;
}

class BookingQuote {
  const BookingQuote({
    required this.lines,
    required this.total,
    required this.freeDivers,
  });

  final List<BookingLine> lines;
  final int total;
  final int freeDivers;

  static int freeCount({
    required int guests,
    required int focPay,
    required int focFree,
  }) {
    if (guests <= 0 || focPay <= 0 || focFree <= 0) {
      return 0;
    }
    return (guests ~/ (focPay + focFree)) * focFree;
  }

  static int rolePrice({
    required ShopProduct product,
    required GuestRole role,
    required bool professional,
  }) {
    for (final rate in product.resolvedGuestRates) {
      if (rate.role == role) {
        if (!rate.enabled) {
          return 0;
        }
        return professional ? rate.professional : rate.consumer;
      }
    }
    if (role == GuestRole.diver) {
      return professional ? product.professionalPrice : product.consumerPrice;
    }
    return 0;
  }

  static int optionUnit({
    required ShopProductOption option,
    required bool professional,
  }) {
    return professional ? option.professionalPrice : option.consumerPrice;
  }

  static int guestsForRole({
    required GuestRole role,
    required int divers,
    required int nondivers,
    required int children,
    required int infants,
  }) {
    switch (role) {
      case GuestRole.diver:
        return divers;
      case GuestRole.nondiver:
        return nondivers;
      case GuestRole.child:
        return children;
      case GuestRole.infant:
        return infants;
    }
  }

  static BookingQuote compute({
    required ShopProduct product,
    required bool professional,
    required int divers,
    required int nondivers,
    required int children,
    required int infants,
    required bool bookPackage,
    required Set<String> selectedOptionIds,
  }) {
    final lines = <BookingLine>[];
    var total = 0;
    final freeDivers = product.focAppliesTo == GuestRole.diver
        ? freeCount(
            guests: divers,
            focPay: product.focPayCount,
            focFree: product.focFreeCount,
          )
        : 0;

    int billed(GuestRole role, int count) {
      var n = count;
      if (role == product.focAppliesTo) {
        n = count -
            freeCount(
              guests: count,
              focPay: product.focPayCount,
              focFree: product.focFreeCount,
            );
      }
      return n * rolePrice(
        product: product,
        role: role,
        professional: professional,
      );
    }

    if (bookPackage) {
      final packageAmount = billed(GuestRole.diver, divers) +
          billed(GuestRole.nondiver, nondivers) +
          billed(GuestRole.child, children) +
          billed(GuestRole.infant, infants);
      lines.add(BookingLine(label: product.name, amount: packageAmount));
      total += packageAmount;
      for (final option in product.options) {
        if (!option.bookable ||
            option.kind != ProductOptionKind.addon ||
            !selectedOptionIds.contains(option.id)) {
          continue;
        }
        final qty = guestsForRole(
          role: option.guestRole,
          divers: divers,
          nondivers: nondivers,
          children: children,
          infants: infants,
        );
        final amount = qty * optionUnit(option: option, professional: professional);
        lines.add(BookingLine(label: option.name, amount: amount));
        total += amount;
      }
    } else {
      for (final option in product.options) {
        if (!option.bookable ||
            option.kind != ProductOptionKind.individual ||
            !selectedOptionIds.contains(option.id)) {
          continue;
        }
        final qty = guestsForRole(
          role: option.guestRole,
          divers: divers,
          nondivers: nondivers,
          children: children,
          infants: infants,
        );
        final amount = qty * optionUnit(option: option, professional: professional);
        lines.add(BookingLine(label: option.name, amount: amount));
        total += amount;
      }
    }

    return BookingQuote(lines: lines, total: total, freeDivers: freeDivers);
  }
}
