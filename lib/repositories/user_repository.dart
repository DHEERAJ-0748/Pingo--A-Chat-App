import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/firestore_constants.dart';

class UserRepository {
  final FirestoreService _firestoreService;

  UserRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Fetch a user by Firebase UID. Returns null if not found.
  Future<UserModel?> getUserByUid(String uid) async {
    final data = await _firestoreService.getDoc(
      FirestoreConstants.usersCollection,
      uid,
    );
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  /// Search for a user by their custom unique userId field.
  /// Returns null if not found.
  Future<UserModel?> searchByUserId(String userId) async {
    final docs = await _firestoreService.queryCollection(
      FirestoreConstants.usersCollection,
      field: FirestoreConstants.userId,
      isEqualTo: userId.trim().toLowerCase(),
      limit: 1,
    );
    if (docs.isEmpty) return null;
    return UserModel.fromMap(docs.first.data());
  }

  /// Create or overwrite a user document.
  Future<void> createUser(UserModel user) async {
    await _firestoreService.setDoc(
      FirestoreConstants.usersCollection,
      user.uid,
      user.toMap(),
    );
  }
}
