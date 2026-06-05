import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Chats list stream
// ---------------------------------------------------------------------------

/// Streams all chats for the currently authenticated user,
/// ordered by most recent message.
final chatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(chatRepositoryProvider).getChatsStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});

// ---------------------------------------------------------------------------
// Messages stream
// ---------------------------------------------------------------------------

final messagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid ?? '';
  return ref.watch(chatRepositoryProvider).getMessagesStream(chatId, uid);
});

// ---------------------------------------------------------------------------
// Other user in a chat
// ---------------------------------------------------------------------------

/// Resolves the other participant's [UserModel] given their UID.
final otherUserProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  return ref.watch(userRepositoryProvider).getUserByUid(uid);
});

// ---------------------------------------------------------------------------
// Single chat stream
// ---------------------------------------------------------------------------

/// Streams a specific chat document by its [chatId] for real-time updates (e.g. typing status).
final chatStreamProvider =
    StreamProvider.family<ChatModel?, String>((ref, chatId) {
  return ref.watch(firestoreServiceProvider).db
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) => doc.exists && doc.data() != null
          ? ChatModel.fromMap(doc.data()!, doc.id)
          : null);
});
