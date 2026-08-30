# Why CocoaPods appeared, and how HourDraft avoids it

The earlier build used the `shared_preferences` Flutter plugin. Flutter
plugins that contain iOS native code are normally installed through CocoaPods.
That is why the old build stopped before launching on your Mac.

This HourDraft package no longer declares `shared_preferences`. It stores the
single local JSON document through a built-in Flutter `MethodChannel`:

- iOS: `UserDefaults`
- Android: native app preferences

To replace an older copy that still has the CocoaPods error, use this new
package, then run:

```bash
flutter clean
./tooling/setup_platforms.sh
flutter pub get
flutter run
```

If an old `ios/Pods` folder or `ios/Podfile.lock` exists, it can be removed
before running the setup script. Do not copy the old `pubspec.lock` into this
project.