# iOS and Android files

This source package is intentionally portable across Flutter installations.
Generate the native runner files using the same Flutter SDK that will build
the app:

```bash
cd hourdraft
./tooling/setup_platforms.sh
flutter run
```

The command creates:

- `android/` — Gradle project and Android launcher
- `ios/` — Xcode workspace, Runner target, and iOS launcher

The setup script also installs the platform storage bridge:

- iOS `UserDefaults` in `native/ios/AppDelegate.swift`
- Android native preferences in `native/android/MainActivity.kt`

This app does not use a third-party Flutter plugin for storage, so CocoaPods is
not needed for HourDraft's data persistence.

Generating these folders locally prevents old Gradle/Xcode templates from
conflicting with Flutter 3.16 on macOS 12.7.6. The application code itself is
already in `lib/`, and the language files are in `assets/languages/`.