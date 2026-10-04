# Run RentRide on Android

Verified on 2026-10-04 with the existing Pixel 6 emulator (`emulator-5554`, Android API 37, ARM64). The debug APK builds, installs, and reaches `OnboardingScreen`; Android reports the activity resumed and drawn.

## Android Studio

1. Open the project folder `/Users/adityarawat/Documents/ChatGPT/car rental`.
2. Open Device Manager and start **Pixel 6**. If quick boot fails, use **Cold Boot Now** from that device's menu. A cold boot preserves the emulator's data.
3. Select the **main.dart** Flutter run configuration and the Android emulator in the device selector. The device may appear as `sdk gphone16k arm64`.
4. Click Run. Allow the build to finish; rebuilding caches can take several minutes.

The existing run configuration points to `lib/main.dart`. Open the Flutter project root, so Android Studio uses that configuration.

## Terminal

From the project folder, with Pixel 6 running:

```sh
/Users/adityarawat/develop/flutter/bin/flutter devices
/Users/adityarawat/develop/flutter/bin/flutter run -d emulator-5554
```

Use the Android device ID returned by `flutter devices` if it differs from `emulator-5554`.

The cold boot used for this diagnosis was:

```sh
/Users/adityarawat/Library/Android/sdk/emulator/emulator -avd Pixel_6 -no-snapshot-load
```

## Build settings on this Mac

Flutter uses the complete existing JDK at `/Users/adityarawat/Library/Java/JavaVirtualMachines/openjdk-17.0.1/Contents/Home`. This Intel JDK works on this Mac, although compilation is slower than with a complete native ARM JDK. The bundled VS Code Java 21 runtime was tried but lacks `jlink`, so it cannot build the Firebase Android plugins; Flutter's original Java 17 setting was restored.

`android/gradle.properties` now limits Gradle to a 2 GB heap, 768 MB metaspace, two workers, and a 768 MB Kotlin daemon heap. Its previous 8 GB heap plus 4 GB metaspace limits were too high for this 8 GB Mac while the emulator was running.

The current Android API 37 emulator requests 4 GB RAM and warns that 16 GB host RAM is recommended. It booted successfully, but can feel slow under memory pressure. No SDKs, dependencies, or emulator data were removed during this diagnosis.

## Preview the prepared Brevo OTP flow

Real delivery remains disabled until the approved Brevo/backend/App Check setup is complete. For a local preview of both email and phone, add `--dart-define=USE_FIREBASE_AUTH=false` to the main.dart run configuration's additional arguments, or run:

```sh
flutter run -d emulator-5554 --dart-define=USE_FIREBASE_AUTH=false
```

Both demo codes are `123456`; no messages or cloud writes occur. After approved live activation, use `--dart-define=OTP_BACKEND_READY=true` instead. See `BREVO_AUTH_SETUP.md` before changing this flag.

## Scope of verification

`flutter analyze` passed. The Android debug build and app startup were verified with the default Firebase configuration. The subsequent build using the reduced memory settings completed in 46 seconds. This verifies startup; real email OTP, SMS delivery, account creation, and profile writes still require the service setup described in `LIVE_AUTH_SETUP.md`.

The prepared Brevo/App Check Android integration also compiled successfully on October 4 (debug build: 103 seconds), and Dart analysis/JavaScript syntax checks passed. This does not verify live OTP delivery or iOS.
