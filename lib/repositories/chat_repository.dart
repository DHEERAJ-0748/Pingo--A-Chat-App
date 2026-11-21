import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      final chat = ChatModel.fromMap(existing, chatId);
      if (chat.deletedForUsers.contains(uidA)) {
        await _firestoreService.db
            .collection(FirestoreConstants.chatsCollection)
            .doc(chatId)
            .update({
          FirestoreConstants.deletedForUsers: FieldValue.arrayRemove([uidA]),
        });
        final updatedDeletedFor = List<String>.from(chat.deletedForUsers)..remove(uidA);
        return chat.copyWith(deletedForUsers: updatedDeletedFor);
      }
      return chat;
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
  /// Sends an async push notification to the receiver if their FCM token exists.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
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
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      isDeletedForEveryone: false,
      deletedAt: null,
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
      FirestoreConstants.deletedForUsers: FieldValue.arrayRemove([senderId, receiverId]),
    });

    await batch.commit();

    // Trigger async push notification via Cloudflare Worker
    _sendPushNotificationViaWorker(
      chatId: chatId,
      messageId: messageRef.id,
    );
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

  /// Deletes the chat for the specified user by adding their UID to deletedForUsers,
  /// setting their deletion timestamp to now, and resetting their unread count to 0.
  Future<void> deleteChatForMe(String chatId, String userId) async {
    await _firestoreService.db
        .collection(FirestoreConstants.chatsCollection)
        .doc(chatId)
        .update({
      FirestoreConstants.deletedForUsers: FieldValue.arrayUnion([userId]),
      '${FirestoreConstants.deletedAtForUsers}.$userId': FieldValue.serverTimestamp(),
      '${FirestoreConstants.unreadCount}.$userId': 0,
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

  /// Deletes a message for everyone by marking it in Firestore.
  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    await _firestoreService.db
        .collection(FirestoreConstants.chatsCollection)
        .doc(chatId)
        .collection(FirestoreConstants.messagesSubcollection)
        .doc(messageId)
        .update({
      FirestoreConstants.isDeletedForEveryone: true,
      FirestoreConstants.deletedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Sends a push notification via the Cloudflare Worker.
  /// Fire-and-forget: errors are logged but do not affect message delivery.
  void _sendPushNotificationViaWorker({
    required String chatId,
    required String messageId,
  }) async {
    if (FirestoreConstants.notificationWorkerUrl == 'WORKER_URL_PLACEHOLDER' ||
        FirestoreConstants.notificationWorkerUrl.isEmpty) {
      print('Cloudflare Worker URL is not configured. Skipping push notification.');
      return;
    }

    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        print('No Firebase ID token available. Skipping push notification.');
        return;
      }

      final url = Uri.parse(
        '${FirestoreConstants.notificationWorkerUrl.replaceAll(RegExp(r'/+$'), '')}/send-notification',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'chatId': chatId,
          'messageId': messageId,
        }),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully via worker: ${response.body}');
      } else {
        print('Worker notification failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error sending push notification via worker: $e');
    }
  }

  /// Gets the current user's Firebase ID token.
  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }
}
