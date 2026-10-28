import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';

/// 상품 사진용 평면 윤곽. 책등·금박 입체감은 넣지 않습니다.
class CCardProductFrame extends StatelessWidget {
  const CCardProductFrame({
    super.key,
    required this.child,
    this.radius = 5,
    this.color = const Color(0xFF111111),
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color,
        border: Border.all(color: color, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1.5),
        child: child,
      ),
    );
  }
}

/// Small ⭐ marks for admin Dive Star grade 1–3 (not guest ★ averages).
String diveStarGradeMarks(int grade) {
  final n = grade.clamp(0, 3);
  if (n <= 0) {
    return '';
  }
  return List.filled(n, '⭐').join();
}

class ListingCertBadge extends StatelessWidget {
  const ListingCertBadge({
    super.key,
    required this.label,
    required this.certified,
    this.faded = false,
    this.grade = 0,
  });

  final String label;
  final bool certified;

  /// Expired Dive Star — keep visible but muted.
  final bool faded;

  /// Admin grade 1–3; stars shown only when certified and not faded.
  final int grade;

  @override
  Widget build(BuildContext context) {
    final marks = (!faded && certified) ? diveStarGradeMarks(grade) : '';
    final textStyle = TextStyle(
      color: certified ? AppTheme.navy : AppTheme.gold,
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: certified ? AppTheme.gold : const Color(0xE60B1F33),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: certified ? const Color(0xFFF8EDD0) : AppTheme.gold,
          width: 0.9,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textStyle),
            if (marks.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(marks, style: textStyle.copyWith(letterSpacing: 0)),
            ],
          ],
        ),
      ),
    );
    if (!faded) {
      return badge;
    }
    return Opacity(opacity: 0.45, child: badge);
  }
}
