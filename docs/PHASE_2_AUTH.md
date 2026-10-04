# RentRide — authentication

Updated 2026-10-04.

The app now includes passwordless email OTP and mobile SMS OTP signup/login, a shared code screen, resend cooldown, guest Explore, name-only profile setup, sign-out, protected destinations, and explicit linking of email/phone to one Firebase account.

Brevo delivers both channels. The server verifies codes and issues Firebase custom tokens; Firebase remains the account/session provider. No Brevo keys are embedded in Flutter, and the phone flow no longer requests Firebase SMS. The original email/password repository methods remain for legacy compatibility.

Code preparation is authorized. Paid setup, deployment, and real delivery checks require the user's approval. Live messaging is disabled by default. See [current status](LIVE_AUTH_SETUP.md) and [complete setup guide](BREVO_AUTH_SETUP.md).

Demo mode supports email and phone code `123456` without cloud accounts or messages:

```sh
flutter run --dart-define=USE_FIREBASE_AUTH=false
```

After real activation, new users complete a display name. No renter/host role choice is required. Protected booking/listing routes preserve the intended destination. Account linking requires a recent sign-in and ownership proof; accounts are never merged automatically.

Vehicle listings, availability, maps, booking, payments, and KYC remain future work. Live end-to-end authentication and iOS still require approved setup and verification.
