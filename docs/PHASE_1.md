# RentRide — Phase 1

Phase 1 provides the Android and iOS Flutter foundation, branded onboarding, phone number sign-in, OTP entry, profile setup, and renter/host role selection. The app can be run immediately in demo mode. Real SMS and profile storage are enabled after configuring Firebase.

## Architecture and folder structure

```text
lib/
  app.dart                                  # go_router routes and Material app
  main.dart                                 # Firebase bootstrap and app entry point
  firebase_options.dart                    # generated for rental-app-ad355 by FlutterFire CLI
  core/
    config/app_config.dart                  # demo / Firebase mode switch
    networking/dio_provider.dart             # shared HTTP client for later APIs
    theme/app_colors.dart
    theme/app_theme.dart
    utils/auth_error_message.dart
    widgets/brand_logo.dart
    widgets/primary_button.dart
  features/
    auth/
      data/demo_auth_repository.dart         # local OTP flow for trying the app
      data/firebase_auth_repository.dart     # Firebase Phone Auth + Firestore profile
      domain/repositories/auth_repository.dart # authentication contract
      presentation/auth_providers.dart
      presentation/otp_route_args.dart
      presentation/screens/
        onboarding_screen.dart
        phone_login_screen.dart
        otp_screen.dart
        profile_setup_screen.dart
    home/
      presentation/screens/setup_complete_screen.dart
firestore.rules                             # private user-profile rules
docs/PHASE_1.md                              # setup, data model, APIs, manual checks
```

The feature folders use `data`, `domain`, and `presentation` boundaries. Phase 1 keeps the domain contract small in `AuthRepository`; vehicle, booking, and payment repositories are added with those later phases.

## Database schema

Phase 1 writes one Firestore document per authenticated account:

`users/{uid}`

| Field | Type | Purpose |
| --- | --- | --- |
| `uid` | string | Firebase Authentication user ID; same as document ID |
| `phoneNumber` | string | Verified E.164 phone number, for example `+919876543210` |
| `displayName` | string | Name shown on the account |
| `roles` | array of strings | `customer`, `host`, or both |
| `onboardingCompleted` | boolean | Whether profile setup has completed |
| `createdAt` | timestamp | Profile creation time |
| `updatedAt` | timestamp | Last profile update time |

`firestore.rules` restricts profile reads and edits to the signed-in owner. Role values are allow-listed, so an account cannot self-assign an `admin` role. Later admin access should use server-managed Firebase custom claims.

Planned collections for later phases (not created by Phase 1):

| Collection | Key fields |
| --- | --- |
| `vehicles/{vehicleId}` | `ownerId`, `type`, `brand`, `model`, `year`, fuel/transmission/seats, hourly and daily rates in INR, deposit, `GeoPoint`, rules, description, `status`, `instantBook` |
| `vehicle_images/{imageId}` | `vehicleId`, `storagePath`, `url`, `sortOrder`, `createdAt` |
| `vehicle_availability/{blockId}` | `vehicleId`, `startAt`, `endAt`, `kind` (`blocked` or `booking`), `bookingId` |
| `bookings/{bookingId}` | `vehicleId`, `ownerId`, `customerId`, start/end timestamps, status, immutable price breakdown, cancellation data |
| `payments/{paymentId}` | `bookingId`, Razorpay order/payment IDs, amount in paise, currency, status, verified webhook metadata |
| `reviews/{reviewId}` | `bookingId`, `vehicleId`, `authorId`, rating, comment, timestamps |
| `kyc_documents/{documentId}` | `userId`, document type, private Storage path, review status, reviewer and timestamps |

The planned platform fee starts at 15% (within your 10–20% range) and will be configurable by admins. Payment amounts should be stored as integer paise. Booking overlap prevention must run in a trusted Cloud Function transaction; Firestore client rules alone cannot safely prevent concurrent overlapping bookings.

## API endpoints

Phase 1 uses Firebase SDKs directly, so there are no custom HTTP endpoints. Dio is configured for later function/API calls but is not needed for the Phase 1 auth requests:

- Firebase Authentication `verifyPhoneNumber` sends the SMS and `signInWithCredential` verifies it.
- Cloud Firestore reads/writes `users/{uid}` under `firestore.rules`.

Later phases can use Firebase Cloud Functions for listing approval, booking overlap checks, Razorpay order creation/webhook verification, KYC review, and admin-only actions. Secret keys stay in server-side functions, never in the Flutter app.

## Run in demo mode

1. Install Flutter and either Android Studio (Android emulator) or Xcode (iOS simulator).
   Firebase requires Android API 23 (Android 6.0) or newer and iOS 15 or newer.
   Install CocoaPods for the iOS Firebase plugins. This Android scaffold uses NDK `30.0.16248370`; Android Studio's SDK Manager can install it under **SDK Tools → NDK (Side by side)** if Gradle does not find it.
2. In this project folder run:

   ```sh
   flutter pub get
   flutter run --dart-define=USE_FIREBASE_AUTH=false
   ```

3. On the welcome screens choose **Get started**.
4. Enter any valid 10-digit Indian mobile number beginning with 6, 7, 8, or 9 and accept the SMS consent.
5. Enter demo OTP **123456**.
6. Choose renter, host, or both, enter a name, and continue.

Demo mode does not send an SMS or store an account. It exists so you can explore Phase 1 without Firebase credentials.

## Connect Firebase Phone Auth

1. Create a Firebase project and register its Android and iOS apps. This Flutter project uses Android application ID `in.rentride.rent_ride` and iOS bundle ID `in.rentride.rentRide`.
2. Install and sign in to the Firebase CLI, then install FlutterFire CLI:

   ```sh
   dart pub global activate flutterfire_cli
   firebase login
   ```

3. From the project folder run `flutterfire configure` and select Android and iOS. It generates platform Firebase settings in `lib/firebase_options.dart` and platform config files.
4. In Firebase Console, enable **Authentication → Phone**. For development, add a Firebase test phone number and fixed test code. For real Android devices, register the signing SHA-1/SHA-256 fingerprints. For iOS, configure APNs for Firebase Phone Auth.
5. Create a Firestore database and publish the rules from this repo's `firestore.rules` (Firebase Console → Firestore → Rules).
6. Run with Firebase enabled:

   ```sh
   flutter run --dart-define=USE_FIREBASE_AUTH=true
   ```

Firebase sends and stores phone numbers for anti-abuse. Ask for the user's consent before starting phone verification; this app includes an explicit SMS consent checkbox. Use Firebase's test phone numbers while developing to avoid sending real SMS messages.

## Manual checks

- The welcome pages advance, the page indicator tracks the active screen, and **Skip** opens phone sign-in.
- Invalid phone numbers and missing SMS consent keep the continue button disabled.
- In demo mode, code `123456` advances to profile setup; another code shows a retry message.
- The resend control unlocks after its countdown.
- At least one role must be selected; renter and host can both be selected for a single account.
- A profile name is required before the completion screen appears.
- With Firebase enabled and valid configuration, a real or Firebase test SMS can complete sign-in and save a private `users/{uid}` profile.

Phase 1 does not yet include vehicle listings, search, maps, booking, payments, KYC, notifications, reviews, or the admin panel. Those remain for their requested later phases.
