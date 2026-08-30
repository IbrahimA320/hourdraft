# Native storage bridge

These two files remove the need for `shared_preferences` and CocoaPods:

- `ios/AppDelegate.swift` stores the app JSON in iOS `UserDefaults`.
- `android/MainActivity.kt` stores the app JSON in Android native preferences.

`tooling/setup_platforms.sh` copies them into the correct folders after
`flutter create` generates the iOS and Android runners.