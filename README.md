# RentRide

Flutter app foundation for a car, bike and scooter rental marketplace in India.

## Authentication

Prepared Brevo **email OTP and mobile SMS OTP** signup/login, with Firebase accounts and persistent sessions, profile setup, sign-out, guest Explore, and explicit linking of email/phone to the same account. The backend includes code expiry, attempt limits, resend throttling, send caps, and App Check enforcement. Brevo credentials stay on the server.

**Email OTP backend is active and a live email request was accepted by Brevo.** App Check and backend secrets are configured. Inbox delivery and completing sign-in still need confirmation in the app. SMS has zero credits and remains disabled. Backend hosting can incur charges.

Firebase project: `rental-app-ad355`. Firestore database: **`rentride`**, Mumbai. Android/iOS registrations, profile rules, and Android debug fingerprints are present. Vehicle/booking screens remain placeholders.

- [Current authentication status](docs/LIVE_AUTH_SETUP.md)
- [Brevo setup, configuration, and activation guide](docs/BREVO_AUTH_SETUP.md)
- [Run the app in Android Studio](docs/RUNNING_ANDROID.md)

## Run locally

```sh
flutter run
# Preview both OTP flows with code 123456, without messages/cloud writes:
flutter run --dart-define=USE_FIREBASE_AUTH=false
```

The default Firebase mode now uses the deployed email OTP backend. Set `--dart-define=OTP_BACKEND_READY=false` to turn backend calls off. Never put API keys in Dart defines or Git. The old Gmail helper is retired.

## Email delivery activation (2026-10-04)

The user disabled Brevo API IP blocking; SMTP IP blocking remains active. The deployed backend accepted a live email OTP request to the user's verified sender address. Brevo API acceptance confirms submission, not inbox delivery. Flutter OTP_BACKEND_READY now defaults true so normal app runs use the deployed backend. The local Pixel 6 App Check debug token is registered. End-to-end code verification and sign-in still await entering the delivered code through the app. SMS remains disabled with zero credits. This status supersedes earlier pending cloud-IP and client-disabled notes.
