# HourDraft localization

The app ships with three language reference files:

- `assets/languages/en.json` — English, LTR
- `assets/languages/ar.json` — Arabic, RTL
- `assets/languages/he.json` — Hebrew, RTL

The runtime strings are kept in `lib/app_localizations.dart` so the app can
switch languages instantly without an asynchronous asset read. The JSON files
are included as an easy-to-download translation handoff and as the source for
future translation updates.

Language switching is available from the menu. Flutter automatically receives
the matching locale and the interface uses the correct RTL or LTR direction.