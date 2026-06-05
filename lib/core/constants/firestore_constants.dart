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

  // Chat fields
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageTime = 'lastMessageTime';
  static const String unreadCount = 'unreadCount';
  static const String typingStatus = 'typingStatus';

  // Message fields
  static const String senderId = 'senderId';
  static const String receiverId = 'receiverId';
  static const String text = 'text';
  static const String timestamp = 'timestamp';
  static const String read = 'read';
  static const String hiddenForUsers = 'hiddenForUsers';
}
