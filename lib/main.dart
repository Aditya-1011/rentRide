import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var initialLocation = '/onboarding';
  if (AppConfig.useFirebaseAuth) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (AppConfig.otpBackendReady) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload().timeout(const Duration(seconds: 8));
        user = FirebaseAuth.instance.currentUser;
      } on FirebaseAuthException catch (error) {
        if (error.code == 'user-disabled' || error.code == 'user-not-found') {
          await FirebaseAuth.instance.signOut();
          user = null;
        }
      } catch (_) {
        // Keep the cached session when offline; server rules still enforce access.
      }
    }
    if (user != null) {
      if (user.email != null &&
          user.phoneNumber == null &&
          !user.emailVerified) {
        initialLocation = '/verify-email';
      } else {
        initialLocation = '/profile';
        try {
          final profile =
              await FirebaseFirestore.instanceFor(
                    app: Firebase.app(),
                    databaseId: AppConfig.firestoreDatabaseId,
                  )
                  .collection('users')
                  .doc(user.uid)
                  .get()
                  .timeout(const Duration(seconds: 3));
          if (profile.data()?['onboardingCompleted'] == true) {
            initialLocation = '/home';
          }
        } catch (_) {
          // Stay signed in and allow profile completion if the network is offline.
        }
      }
    }
  }

  runApp(ProviderScope(child: RentRideApp(initialLocation: initialLocation)));
}
