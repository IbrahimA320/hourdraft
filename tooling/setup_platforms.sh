#!/usr/bin/env bash
set -euo pipefail

# Generate native runner files using the Flutter SDK installed on the machine.
# This keeps the Android Gradle and iOS Xcode templates matched to that SDK.
flutter create --platforms=ios,android --project-name hourdraft \
  --org com.hourdraft .
mkdir -p android/app/src/main/kotlin/com/hourdraft
cp native/android/MainActivity.kt \
  android/app/src/main/kotlin/com/hourdraft/MainActivity.kt
cp native/ios/AppDelegate.swift ios/Runner/AppDelegate.swift
flutter pub get
echo "Platform files created. Run: flutter run"