import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

