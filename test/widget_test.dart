import 'package:flutter_test/flutter_test.dart';

import 'package:hourdraft/app_localizations.dart';

void main() {
  test('all supported languages have direction-compatible locales', () {
    expect(AppLocalizations.supportedLocales.length, 3);
    expect(AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
        containsAll(<String>['en', 'ar', 'he']));
  });
}