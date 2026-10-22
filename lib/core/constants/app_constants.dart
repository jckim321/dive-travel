import 'package:flutter/material.dart';

/// 앱 전역 상수. 개발 단계에서는 한국어를 기본 언어로 둡니다.
abstract final class AppConstants {
  static const String appName = '다이브 트래블';
  static const Locale defaultLocale = Locale('ko');
  static const int masterLogTarget = 100;
  static const String adminPin = '9118';

  /// 테스트 동안 로그인 세션을 관리자로 연다. 실서비스 배포 전 false로 되돌리세요.
  static const bool grantAdminToCurrentSession = true;

  /// 테스트 동안 로그인 세션을 파트너(Business)로 연다. 실서비스 배포 전 false로 되돌리세요.
  static const bool grantBusinessToCurrentSession = true;
  static const String defaultPartnerShopId = 'bohol-hideout';

  /// GitHub Pages site root (Flutter web `--base-href /dive-travel/`).
  static const String publicSiteBaseUrl =
      'https://jckim321.github.io/dive-travel';

  /// Public partner-doc landing pages (OG / Kakao link previews).
  static String partnerDocLandingUrl(String documentId) {
    return switch (documentId.trim()) {
      'dive-star-guide-ko' =>
        '$publicSiteBaseUrl/partner-docs/dive-star-guide-ko.html',
      'dive-star-loi-ko' =>
        '$publicSiteBaseUrl/partner-docs/dive-star-loi-ko.html',
      _ => '$publicSiteBaseUrl/partner-docs/',
    };
  }
}

/// 앱 소유자 계정. 회원가입 화면에 미리 채우고 Firestore 프로필 이름으로 씁니다.
abstract final class AppOwner {
  static const String email = 'jckim321@gmail.com';
  static const String displayName = 'Jongcheol Kim';

  static bool isOwnerEmail(String? value) {
    return (value ?? '').trim().toLowerCase() == email.toLowerCase();
  }

  static String resolveDisplayName({
    required String? email,
    required String? displayName,
  }) {
    final typed = (displayName ?? '').trim();
    if (typed.isNotEmpty) {
      return typed;
    }
    if (isOwnerEmail(email)) {
      return AppOwner.displayName;
    }
    final fromEmail = email?.split('@').first.trim() ?? '';
    if (fromEmail.isNotEmpty) {
      return fromEmail;
    }
    return '다이버';
  }
}
