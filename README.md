# HourDraft

HourDraft is a local-first Flutter app for recording hours. It follows the
attached Pathway-style design: warm background, green accent, compact metric
cards, calendar, recent logs, and an approval tracker.

## Included

- Add hour entries for Indoor, Outdoor, or Group work.
- Every saved entry is stored locally through the platform's native key-value storage.
- Tap any calendar date or history row to edit that entry.
- Selecting **Group** immediately asks whether the hours are approved.
- Approval status is visible in the entry, history, and Approval tab.
- English, Arabic, and Hebrew translations.
- Automatic LTR for English and RTL for Arabic/Hebrew.
- Responsive scrolling layouts that remain safe when the device rotates.
- Weekly limits and a small analytics view.

## Your Flutter version

Flutter 3.16.0 and Dart 3.2.0 match the SDK constraints in this project.
The project intentionally avoids newer Flutter APIs.

## External packages

No third-party Dart package is required for storage. HourDraft uses a Flutter
`MethodChannel` and the native key-value stores already available on iOS and
Android.

`flutter_localizations` is part of the Flutter SDK and does not need a
separate installation. There are no API keys, databases, or cloud services.
For iOS, you need Xcode. CocoaPods is not required by this version of
HourDraft because it has no third-party Flutter plugin. Android needs Android
Studio's SDK and Build-Tools.

## Run in VS Code

From this folder:

```bash
flutter pub get
flutter analyze
flutter run
```

Open the `hourdraft` folder in VS Code, select an iOS Simulator, Android
emulator, or connected device, then press `F5`. Use the included
`tooling/setup_platforms.sh` script once so the native storage handlers are
installed into the generated runner folders.

## Generate the iOS and Android runner folders

The Dart source and configuration are already included. If the platform
runner folders are not present in the ZIP, run this once from the project
root:

```bash
./tooling/setup_platforms.sh
flutter run
```

The script runs the official Flutter generator, then installs the small native
storage handlers from `native/`. It creates the iOS and Android files using
the Flutter SDK installed on your Mac.

### iOS on macOS 12.7.6

- Install Xcode from the newest version supported by macOS 12.7.6.
- Open Xcode once and accept its license.
- Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- Run `flutter doctor` and fix any item marked with an error.
- For a physical iPhone, set a unique Bundle Identifier and select a signing
  Team in Xcode under `ios/Runner.xcworkspace`.

### Android

- Install Android Studio and an Android SDK.
- In Android Studio, install an SDK Platform and SDK Build-Tools.
- Accept licenses with `flutter doctor --android-licenses`.
- Start an emulator or connect an Android phone with USB debugging enabled.

No additional app code is required for rotation; Flutter rebuilds the
responsive views when the available width changes.

## Storage note

Entries are local to the device. iOS stores them in `UserDefaults`; Android
stores them in the app's native preferences. Uninstalling the app or clearing
app data removes them. The sample entries only appear on the first install;
after the first save, the app persists your own data.