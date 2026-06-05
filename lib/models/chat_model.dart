import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_constants.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, bool> typingStatus;

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.createdAt,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.typingStatus = const {},
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      chatId: docId,
      participants: List<String>.from(map[FirestoreConstants.participants] as List),
      createdAt: (map[FirestoreConstants.createdAt] as Timestamp).toDate(),
      lastMessage: map[FirestoreConstants.lastMessage] as String? ?? '',
      lastMessageTime: map[FirestoreConstants.lastMessageTime] != null
          ? (map[FirestoreConstants.lastMessageTime] as Timestamp).toDate()
          : null,
      unreadCount: map[FirestoreConstants.unreadCount] != null
          ? Map<String, int>.from(map[FirestoreConstants.unreadCount] as Map)
          : const {},
      typingStatus: map[FirestoreConstants.typingStatus] != null
          ? Map<String, bool>.from(map[FirestoreConstants.typingStatus] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.participants: participants,
      FirestoreConstants.createdAt: Timestamp.fromDate(createdAt),
      FirestoreConstants.lastMessage: lastMessage,
      FirestoreConstants.lastMessageTime:
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      FirestoreConstants.unreadCount: unreadCount,
      FirestoreConstants.typingStatus: typingStatus,
    };
  }

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, bool>? typingStatus,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      typingStatus: typingStatus ?? this.typingStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModel && runtimeType == other.runtimeType && chatId == other.chatId;

  @override
  int get hashCode => chatId.hashCode;
}
