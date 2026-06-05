import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/firestore_constants.dart';
import '../core/utils/chat_id_util.dart';

class ChatRepository {
  final FirestoreService _firestoreService;

  ChatRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Returns existing chat or creates a new one.
  /// Uses a deterministic ID to prevent duplicates.
  Future<ChatModel> getOrCreateChat(String uidA, String uidB) async {
    final chatId = ChatIdUtil.generate(uidA, uidB);
    final existing = await _firestoreService.getDoc(
      FirestoreConstants.chatsCollection,
      chatId,
    );

    if (existing != null) {
      return ChatModel.fromMap(existing, chatId);
    }

    // Create new chat document
    final now = DateTime.now();
    final chat = ChatModel(
      chatId: chatId,
      participants: [uidA, uidB],
      createdAt: now,
      lastMessage: '',
      lastMessageTime: null,
      unreadCount: {uidA: 0, uidB: 0},
      typingStatus: {uidA: false, uidB: false},
    );

    await _firestoreService.setDoc(
      FirestoreConstants.chatsCollection,
      chatId,
      chat.toMap(),
    );

    return chat;
  }

  /// Stream of all chats where the current user is a participant,
  /// ordered by most recent message first.
  Stream<List<ChatModel>> getChatsStream(String uid) {
    return _firestoreService
        .collectionStream(
          FirestoreConstants.chatsCollection,
          field: FirestoreConstants.participants,
          arrayContains: uid,
          orderByField: FirestoreConstants.lastMessageTime,
          descending: true,
        )
        .map(
          (snap) => snap.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Sends a message to [chatId]'s messages subcollection
  /// and updates the chat's lastMessage, lastMessageTime, unreadCount, and typingStatus.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final now = DateTime.now();
    final message = MessageModel(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: now,
      read: false,
      hiddenForUsers: const [],
    );

    final batch = _firestoreService.db.batch();

    // Add message to subcollection
    final messageRef = _firestoreService.db
        .collection(FirestoreConstants.chatsCollection)
        .doc(chatId)
        .collection(FirestoreConstants.messagesSubcollection)
        .doc();

    batch.set(messageRef, message.toMap());

    // Update chat's lastMessage fields
    final chatRef = _firestoreService.db
        .collection(FirestoreConstants.chatsCollection)
        .doc(chatId);

    batch.update(chatRef, {
      FirestoreConstants.lastMessage: text.trim(),
      FirestoreConstants.lastMessageTime: Timestamp.fromDate(now),
      'unreadCount.$receiverId': FieldValue.increment(1),
      'typingStatus.$senderId': false,
    });

    await batch.commit();
  }

  /// Marks all unread messages in [chatId] sent to [userId] as read
  /// and resets the unread count in the chat document.
  Future<void> markChatAsRead(String chatId, String userId) async {
    // Reset unread count in the chat document
    await _firestoreService.updateDoc(
      FirestoreConstants.chatsCollection,
      chatId,
      {'unreadCount.$userId': 0},
    );

    // Query unread messages in this chat sent to userId
    final querySnap = await _firestoreService.db
        .collection(FirestoreConstants.chatsCollection)
        .doc(chatId)
        .collection(FirestoreConstants.messagesSubcollection)
        .where(FirestoreConstants.receiverId, isEqualTo: userId)
        .where(FirestoreConstants.read, isEqualTo: false)
        .get();

    if (querySnap.docs.isEmpty) return;

    final batch = _firestoreService.db.batch();
    for (final doc in querySnap.docs) {
      batch.update(doc.reference, {FirestoreConstants.read: true});
    }
    await batch.commit();
  }

  /// Sets the typing status for [userId] in [chatId].
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    await _firestoreService.updateDoc(
      FirestoreConstants.chatsCollection,
      chatId,
      {'typingStatus.$userId': isTyping},
    );
  }

  /// Locally hides a message for [userId] by adding their UID to hiddenForUsers.
  Future<void> deleteMessageForMe(String chatId, String messageId, String userId) async {
    await _firestoreService.db
        .collection(FirestoreConstants.chatsCollection)
        .doc(chatId)
        .collection(FirestoreConstants.messagesSubcollection)
        .doc(messageId)
        .update({
      FirestoreConstants.hiddenForUsers: FieldValue.arrayUnion([userId]),
    });
  }

  /// Real-time stream of messages in [chatId], ordered by timestamp ascending,
  /// filtering out messages hidden for [currentUid].
  Stream<List<MessageModel>> getMessagesStream(String chatId, String currentUid) {
    return _firestoreService
        .subcollectionStream(
          FirestoreConstants.chatsCollection,
          chatId,
          FirestoreConstants.messagesSubcollection,
          orderByField: FirestoreConstants.timestamp,
          descending: false,
        )
        .map(
          (snap) => snap.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .where((msg) => !msg.hiddenForUsers.contains(currentUid))
              .toList(),
        );
  }
}
