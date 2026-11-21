class FirestoreConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';

  // User fields
  static const String uid = 'uid';
  static const String userId = 'userId';
  static const String displayName = 'displayName';
  static const String email = 'email';
  static const String createdAt = 'createdAt';
  static const String fcmToken = 'fcmToken';

  // Chat fields
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageTime = 'lastMessageTime';
  static const String unreadCount = 'unreadCount';
  static const String typingStatus = 'typingStatus';
  static const String deletedForUsers = 'deletedForUsers';
  static const String deletedAtForUsers = 'deletedAtForUsers';

  // Message fields
  static const String senderId = 'senderId';
  static const String receiverId = 'receiverId';
  static const String text = 'text';
  static const String timestamp = 'timestamp';
  static const String read = 'read';
  static const String hiddenForUsers = 'hiddenForUsers';
  static const String replyToMessageId = 'replyToMessageId';
  static const String replyToText = 'replyToText';
  static const String replyToSenderId = 'replyToSenderId';
  static const String isDeletedForEveryone = 'isDeletedForEveryone';
  static const String deletedAt = 'deletedAt';

  // Cloudflare Worker URL for push notifications
  static const String notificationWorkerUrl = 'https://pingo-notification-worker.dheerajsribashyam.workers.dev';
}
