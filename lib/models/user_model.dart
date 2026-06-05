import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_constants.dart';

class UserModel {
  final String uid;
  final String userId;
  final String displayName;
  final String email;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[FirestoreConstants.uid] as String,
      userId: map[FirestoreConstants.userId] as String,
      displayName: map[FirestoreConstants.displayName] as String,
      email: map[FirestoreConstants.email] as String,
      createdAt: (map[FirestoreConstants.createdAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.uid: uid,
      FirestoreConstants.userId: userId,
      FirestoreConstants.displayName: displayName,
      FirestoreConstants.email: email,
      FirestoreConstants.createdAt: Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? userId,
    String? displayName,
    String? email,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
