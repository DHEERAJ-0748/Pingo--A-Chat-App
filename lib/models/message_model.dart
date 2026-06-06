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
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final bool isDeletedForEveryone;
  final DateTime? deletedAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.read,
    this.hiddenForUsers = const [],
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.isDeletedForEveryone = false,
    this.deletedAt,
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
      replyToMessageId: map[FirestoreConstants.replyToMessageId] as String?,
      replyToText: map[FirestoreConstants.replyToText] as String?,
      replyToSenderId: map[FirestoreConstants.replyToSenderId] as String?,
      isDeletedForEveryone: map[FirestoreConstants.isDeletedForEveryone] as bool? ?? false,
      deletedAt: map[FirestoreConstants.deletedAt] != null
          ? (map[FirestoreConstants.deletedAt] as Timestamp).toDate()
          : null,
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
      FirestoreConstants.replyToMessageId: replyToMessageId,
      FirestoreConstants.replyToText: replyToText,
      FirestoreConstants.replyToSenderId: replyToSenderId,
      FirestoreConstants.isDeletedForEveryone: isDeletedForEveryone,
      FirestoreConstants.deletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
