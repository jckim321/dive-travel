# Dive Travel

전 세계 다이빙 예약을 위한 다국어 Flutter 앱입니다.
개발 단계에서는 **한국어를 기본 언어**로 사용합니다. 문구 원본은 `lib/l10n/app_ko.arb`입니다.

## 지원 플랫폼

- Android
- iOS
- Web
- Windows
- macOS

## 지원 언어

한국어(기본), 영어, 일본어, 중국어, 스페인어, 태국어, 인도네시아어

## 시작하기

```bash
flutter pub get
flutter run
```

## 프로젝트 구조

```text
lib/
  main.dart
  app.dart
  core/           # 테마, 상수 등 공통 코드
  features/       # 홈, 여행지, 예약, 프로필
  l10n/           # ARB 번역 파일
assets/
  images/
  icons/
```
