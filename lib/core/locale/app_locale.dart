import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';

const _kAppLocaleKey = 'app_locale';

/// One language the user can pick. Add a row here to offer another later.
class AppLanguageChoice {
  const AppLanguageChoice({
    required this.locale,
    required this.nativeName,
    required this.shortLabel,
  });

  final Locale locale;
  final String nativeName;
  final String shortLabel;
}

const kAppLanguageChoices = <AppLanguageChoice>[
  AppLanguageChoice(
    locale: Locale('ko'),
    nativeName: '한국어',
    shortLabel: '한',
  ),
  AppLanguageChoice(
    locale: Locale('en'),
    nativeName: 'English',
    shortLabel: 'EN',
  ),
];

/// Device language. Missing or unknown saved codes stay [AppConstants.defaultLocale].
class AppLocaleController extends ChangeNotifier {
  AppLocaleController({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;
  Locale _locale = AppConstants.defaultLocale;

  Locale get locale => _locale;

  Future<SharedPreferences> _ready() async {
    if (_prefs != null) {
      return _prefs!;
    }
    if (_prefsOverride != null) {
      return _prefs = _prefsOverride;
    }
    try {
      return _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // flutter_test without setMockInitialValues
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(const {});
      return _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> load() async {
    final prefs = await _ready();
    final code = prefs.getString(_kAppLocaleKey)?.trim() ?? '';
    final next = _choice(code)?.locale ?? AppConstants.defaultLocale;
    if (next.languageCode == _locale.languageCode) {
      return;
    }
    _locale = next;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final choice = _choice(locale.languageCode);
    if (choice == null || choice.locale.languageCode == _locale.languageCode) {
      return;
    }
    _locale = choice.locale;
    notifyListeners();
    final prefs = await _ready();
    await prefs.setString(_kAppLocaleKey, choice.locale.languageCode);
  }

  AppLanguageChoice? _choice(String languageCode) {
    for (final choice in kAppLanguageChoices) {
      if (choice.locale.languageCode == languageCode) {
        return choice;
      }
    }
    return null;
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }
}
