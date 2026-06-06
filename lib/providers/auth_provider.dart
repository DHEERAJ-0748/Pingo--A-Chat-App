import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'user_provider.dart';

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Auth state stream
// ---------------------------------------------------------------------------

/// Emits the current Firebase [User] or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Current user model
// ---------------------------------------------------------------------------

/// Resolves the currently signed-in [UserModel] from Firestore.
/// Returns null when unauthenticated or data not yet loaded.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return ref.watch(userRepositoryProvider).getUserByUid(user.uid);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
