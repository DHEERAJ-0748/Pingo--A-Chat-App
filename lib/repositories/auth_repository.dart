import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/firestore_constants.dart';
import 'user_repository.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final UserRepository _userRepository;

  AuthRepository({
    required AuthService authService,
    required FirestoreService firestoreService,
    required UserRepository userRepository,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _userRepository = userRepository;

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  User? get currentUser => _authService.currentUser;

  /// Creates a new account.
  /// Validates userId uniqueness before creating the Auth user.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String userId,
  }) async {
    // 1. Validate userId uniqueness
    final existing = await _userRepository.searchByUserId(userId.trim());
    if (existing != null) {
      throw const AuthException(
        'This user ID is already taken. Please choose another.',
      );
    }

    // 2. Create Firebase Auth account
    final credential = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // 3. Create Firestore user document
    final userModel = UserModel(
      uid: uid,
      userId: userId.trim().toLowerCase(),
      displayName: displayName.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );

    await _firestoreService.setDoc(
      FirestoreConstants.usersCollection,
      uid,
      userModel.toMap(),
    );
  }

  /// Signs in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authService.signInWithEmail(email: email, password: password);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
  }
}
