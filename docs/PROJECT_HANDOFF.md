# RentRide project handoff

Updated: 2026-10-04.

## Product and technology
- Client-delivered Indian car, bike and scooter rental marketplace for Android/iOS.
- Flutter, feature-first data/domain/presentation layers, Riverpod, go_router, Dio.
- Backend: Firebase Authentication custom-token sessions and Firestore. The prepared Cloud Functions backend uses Brevo for email and mobile OTP, in Mumbai. Deployment and paid setup require final approval. INR and Razorpay payments later.
- One account can rent and host. Admin approval for listings and KYC.
- Reference design: `/Users/adityarawat/Downloads/Untitled.png`.

## Current state
- Phase 1 code exists: onboarding, phone OTP screen, profile setup, demo and Firebase auth repositories, theme, navigation, rules and documentation.
- Authentication is implemented locally: Brevo email/mobile OTP signup and sign-in, guest Explore, name-only profile completion, explicit phone/email OTP linking, sign-out, and protected destinations that preserve the return path. Email/password repository methods remain for legacy compatibility. See `BREVO_AUTH_SETUP.md`.
- Firebase CLI is signed in and the active project is `rental-app-ad355`. Android app `in.rentride.rent_ride` and iOS app `in.rentride.rentRide` are registered; FlutterFire generated `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.
- `USE_FIREBASE_AUTH` defaults to true and selects a single global repository. Firestore `rentride` (Enterprise Native, Mumbai, `freeTier: true` when created) and owner-only rules are deployed. Android debug SHA1/SHA256 are registered. iOS callback/background modes are configured. Firebase Auth/custom-token setup, Brevo sender/backend deployment, and App Check registration remain. Brevo SMS no longer uses Firebase phone verification or its APNs callback. The October 4 Console showed an active linked Firebase Payment billing account with no promotional credits displayed; earlier inactive-billing API results are historical. Real OTP, email delivery, account creation and profile writes have not been verified. The separate all-demo repository now supports both email and phone. It does not create cloud identities or profiles.
- Vehicle listing, browse results, vehicle details, maps and booking are still pending. Protected booking/listing screens are placeholders to finish the authentication return flow before those features.
- Android debug build, install, and startup to `OnboardingScreen` were verified on 2026-10-04 on Pixel 6 (`emulator-5554`, API 37 ARM64), with default Firebase enabled. Gradle memory and worker limits were reduced for the 8 GB Mac. Flutter's complete Java 17 setting was restored after a bundled native Java 21 runtime failed because it lacks `jlink`. See `RUNNING_ANDROID.md`. This does not verify live authentication. iOS has not been verified.

## Agreed authentication experience
- Guests can browse vehicles using Explore as guest.
- Require login when booking or starting a vehicle listing; preserve intended destination.
- Both email and phone use passwordless six-digit Brevo OTP in the connected mode. Flutter `OTP_BACKEND_READY` and server delivery flags stay off pending approval. All-demo mode uses `123456` for both channels.
- After verified phone sign-in: new users complete a short name/profile setup; returning users go Home or intended destination; incomplete profiles finish setup.
- Any account can become an owner later using List your vehicle. Do not force owner/customer role selection during initial login.
- Driving licence/KYC required when ready to book, not to browse.
- Link phone/email credentials securely to the same signed-in account; do not merge accounts merely because input details match.

## Design preview
- White background, blue primary buttons, navy text, rounded fields; phone/email tabs.
- Phone login with vehicle banner, +91 input, Send OTP, and add Explore as guest.
- OTP: six digits, resend cooldown, change-number link.
- Email: passwordless code request, inbox verification, resend, and change-address link.
- Generated concept: `/Users/adityarawat/.codex/generated_images/01a0fb8e-7a84-7a20-8440-ee9921dee436/exec-9226727b-662d-4b3b-a0d4-3783ca2811c0.png`. Preview only, not implemented or a reusable banner asset.

## Phase boundaries
- Phase 2: Firebase setup/authentication, vehicle add/edit/deactivate, photo and private document uploads, availability blocks, browse home, details and pickup maps.
- Phase 3: search/filters, transactional booking overlap protection, backend pricing/payment verification, notifications.
- Phase 4: KYC/admin interfaces, reviews, verification and release preparation.
- Do not advance to Phase 3 without user instruction.

## Working preferences and next step
- User is a beginner: explain setup one step at a time and use concise progress updates.
- Inspect actual files before editing. Preserve existing work.
- Next: review `BREVO_AUTH_SETUP.md` and obtain approval before paid setup, secret creation, deployment, SMS-credit purchase, or real delivery checks. Brevo sender/API key and App Check are not connected. The Gmail helper is retired. Never request secrets in chat.
- Client should own production Firebase/billing and payment accounts. Real SMS has costs and requires provider/platform setup.
- Run tests only when user requests testing/verification, per current developer instructions; report what was actually verified.
- Do not delete Downloads or development tools as part of app work.


## Brevo OTP preparation (2026-10-04)

User authorized preparing real email and mobile OTP. Both integrations and passwordless email login are now present in the code. No cloud setup or paid actions were performed. The prepared backend remains Firebase Functions in `asia-south1`, targeting Firestore `rentride`; it may incur costs. Brevo SMS is paid. App Check is enforced. Keep `OTP_DELIVERY_ENABLED=false`, `OTP_SMS_ENABLED=false`, and Flutter `OTP_BACKEND_READY=false` until activation is approved. Live delivery and cloud identity/profile behavior remain unverified.

## Approved email deployment status (2026-10-04)

On 2026-10-04, the user approved computer IP authorization and Firebase email deployment. The computer IP was authorized in Brevo. Both backend secrets are stored in Firebase Secret Manager, all four callable functions are ACTIVE in Mumbai, the runtime has signing permission on its own service account, and the emulator App Check debug token is registered and exchanges successfully. Deployment image cleanup is configured after one day. The first live email request failed because Brevo blocked the Google Cloud outgoing IP `2600:1900:0:3900::a01`; delivery and end-to-end sign-in are not verified. A separate confirmation for the cloud IP/security setting is pending. No SMS credits were purchased; SMS remains disabled.

This status supersedes the earlier preparation-only notes above.

## Email delivery activation (2026-10-04)

The user disabled Brevo API IP blocking; SMTP IP blocking remains active. The deployed backend accepted a live email OTP request to the user's verified sender address. Brevo API acceptance confirms submission, not inbox delivery. Flutter OTP_BACKEND_READY now defaults true so normal app runs use the deployed backend. The local Pixel 6 App Check debug token is registered. End-to-end code verification and sign-in still await entering the delivered code through the app. SMS remains disabled with zero credits. This status supersedes earlier pending cloud-IP and client-disabled notes.

## OTP screen and method selection fix (2026-10-04)

Phone/email screens share a single method selector: the selected method is blue and the other is muted. Six entered OTP digits automatically trigger verification; the explicit Verify button remains available. Inputs are disabled while verification is running and the keyboard closes so feedback is visible. Fresh custom-token sign-in no longer waits for redundant user reload/token-refresh requests. Profile routing waits at most eight seconds before opening profile setup, and return destinations cannot send a completed login back to an authentication screen. Source was formatted; no test suite was run for this change.

## Router refresh correction (2026-10-04)

OTP route extras now use an explicit GoRouter codec, preventing custom OtpRouteArgs from being dropped during router state serialization. Missing OTP data no longer renders the phone screen. Session refreshes redirect verified signed-in users from login/OTP to profile setup or their intended in-app destination. Account-linking OTP stays separate. Profile lookup failures fall back to profile setup rather than rejecting the verified session; Firestore rules remain enforced. Both login screens share selected-state styling and labels Phone and Email. No test suite was run for this change.
