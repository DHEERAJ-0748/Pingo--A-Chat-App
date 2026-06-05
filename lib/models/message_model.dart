import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_constants.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool read;
  final List<String> hiddenForUsers;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.read,
    this.hiddenForUsers = const [],
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map[FirestoreConstants.senderId] as String,
      receiverId: map[FirestoreConstants.receiverId] as String,
      text: map[FirestoreConstants.text] as String,
      timestamp: (map[FirestoreConstants.timestamp] as Timestamp).toDate(),
      read: map[FirestoreConstants.read] as bool? ?? false,
      hiddenForUsers: map[FirestoreConstants.hiddenForUsers] != null
          ? List<String>.from(map[FirestoreConstants.hiddenForUsers] as List)
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.senderId: senderId,
      FirestoreConstants.receiverId: receiverId,
      FirestoreConstants.text: text,
      FirestoreConstants.timestamp: Timestamp.fromDate(timestamp),
      FirestoreConstants.read: read,
      FirestoreConstants.hiddenForUsers: hiddenForUsers,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
