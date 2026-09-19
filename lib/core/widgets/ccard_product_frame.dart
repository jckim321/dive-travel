import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';

/// 상품 사진용 평면 윤곽. 책등·금박 입체감은 넣지 않습니다.
class CCardProductFrame extends StatelessWidget {
  const CCardProductFrame({
    super.key,
    required this.child,
    this.radius = 14,
  });

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF111111), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1.5),
        child: child,
      ),
    );
  }
}

class ListingCertBadge extends StatelessWidget {
  const ListingCertBadge({
    super.key,
    required this.label,
    required this.certified,
  });

  final String label;
  final bool certified;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
        child: Text(
          label,
          style: TextStyle(
            color: certified ? AppTheme.navy : AppTheme.gold,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
