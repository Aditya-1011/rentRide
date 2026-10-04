# Authentication setup and current status

Updated 2026-10-04. Firebase project: `rental-app-ad355`.

## Prepared integration

The user approved **real email and mobile OTP code preparation**, with separate approval required before paid setup or deployment. The current implementation uses Brevo for email and SMS delivery, Firebase Functions for verification, Firebase custom tokens for sessions, and the existing Mumbai Firestore database for profiles and server-only challenges.

See [Brevo setup and activation guide](BREVO_AUTH_SETUP.md) for the complete contract, configuration, costs, and approval steps.

- `/email`: passwordless email OTP sign-in/signup.
- `/phone`: Indian mobile SMS OTP sign-in/signup. No Firebase SMS request is made.
- `/otp`: shared six-digit verification screen with resend, expiry information, and errors.
- Account security: explicit email/phone OTP linking to the signed-in UID. Credentials belonging to another account are rejected.
- New users complete their name/profile. Guest browsing and protected return destinations remain.
- Legacy email/password repository methods and numeric email verification are retained for existing users; the primary UI is passwordless.
- Demo mode now simulates both channels with `123456`, without cloud messages/users/profiles.

## Existing cloud configuration

- Android/iOS registrations and generated Firebase configuration are present.
- Firestore **`rentride`** exists in **Mumbai (`asia-south1`)**, Enterprise Native mode; Google reported `freeTier: true` when created.
- Owner-only profile rules are deployed. Their catch-all denial protects the new server-only challenge/rate collections.
- Android debug SHA1/SHA256 fingerprints are registered. Production signing still needs its certificates.
- On October 4, Google Cloud Console showed an active linked Firebase Payment billing account and no promotional credits. Earlier inactive-billing API results are historical.

## Pending live activation

On 2026-10-04, the user approved computer IP authorization and Firebase email deployment. The computer IP was authorized in Brevo. Both backend secrets are stored in Firebase Secret Manager, all four callable functions are ACTIVE in Mumbai, the runtime has signing permission on its own service account, and the emulator App Check debug token is registered and exchanges successfully. Deployment image cleanup is configured after one day. The first live email request failed because Brevo blocked the Google Cloud outgoing IP `2600:1900:0:3900::a01`; delivery and end-to-end sign-in are not verified. A separate confirmation for the cloud IP/security setting is pending. No SMS credits were purchased; SMS remains disabled.

Flutter `OTP_BACKEND_READY` defaults false. Server `OTP_DELIVERY_ENABLED` and `OTP_SMS_ENABLED` default false. The deployed email flag is now true; SMS remains false. Flutter is run with OTP_BACKEND_READY=true for verification, while its default remains false until provider delivery is resolved. A normal default run opens the app but cannot send codes yet.

Brevo email has a free allowance; Brevo SMS and Firebase backend usage can cost money. Application send caps do not cap all Firebase charges. Read the guide before activating anything.

## Local preview

```sh
flutter run -d emulator-5554 --dart-define=USE_FIREBASE_AUTH=false
```

Both demo channels use `123456`. This is an in-memory preview, not real identity verification.

## Verification boundary

Static code analysis/syntax checks and Android compilation cover the prepared source. Real OTP delivery, custom-token signing, account creation, profile writes, and iOS behavior remain unverified until cloud setup and live delivery checks are approved.

Marketplace listings, bookings, maps, payments, and KYC remain outside this authentication step. The retired Gmail helper must not be used. Never paste API keys, passwords, private keys, or authorization codes into chat.

## Email delivery activation (2026-10-04)

The user disabled Brevo API IP blocking; SMTP IP blocking remains active. The deployed backend accepted a live email OTP request to the user's verified sender address. Brevo API acceptance confirms submission, not inbox delivery. Flutter OTP_BACKEND_READY now defaults true so normal app runs use the deployed backend. The local Pixel 6 App Check debug token is registered. End-to-end code verification and sign-in still await entering the delivered code through the app. SMS remains disabled with zero credits. This status supersedes earlier pending cloud-IP and client-disabled notes.
