import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/demo_auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebaseAuth) return FirebaseAuthRepository();
  return DemoAuthRepository();
});
