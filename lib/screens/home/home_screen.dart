import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/loading_widget.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  UserModel? _searchResult;
  bool _userNotFound = false;
  bool _isCreatingChat = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _userNotFound = false;
    });

    final result = await ref.read(userRepositoryProvider).searchByUserId(query);

    if (!mounted) return;

    final currentUser = await ref.read(currentUserProvider.future);

    if (result != null && result.uid == currentUser?.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't chat with yourself.")),
      );
      setState(() => _isSearching = false);
      return;
    }

    setState(() {
      _isSearching = false;
      _searchResult = result;
      _userNotFound = result == null;
      _searchQuery = query;
    });
  }

  Future<void> _openOrCreateChat(UserModel otherUser) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null || !mounted) return;

    setState(() => _isCreatingChat = true);

    try {
      final chat = await ref.read(chatRepositoryProvider).getOrCreateChat(
            currentUser.uid,
            otherUser.uid,
          );

      if (!mounted) return;
      _navigateToChat(chat, otherUser);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreatingChat = false);
    }
  }

  void _navigateToChat(ChatModel chat, UserModel otherUser) {
    _searchController.clear();
    setState(() {
      _searchResult = null;
      _userNotFound = false;
      _searchQuery = '';
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chat: chat, otherUser: otherUser),
      ),
    );
  }

  Future<void> _openChatFromTile(ChatModel chat) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null || !mounted) return;

    final otherUid =
        chat.participants.firstWhere((p) => p != currentUser.uid, orElse: () => '');
    if (otherUid.isEmpty) return;

    final otherUser = await ref.read(otherUserProvider(otherUid).future);
    if (otherUser == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chat: chat, otherUser: otherUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserAsync = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentUserAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Messages'),
              if (user != null)
                Text(
                  '@${user.userId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          loading: () => const Text('Messages'),
          error: (_, _) => const Text('Messages'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Search by user ID...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),
          ),

          // Search result
          if (_searchResult != null)
            _SearchResultCard(
              user: _searchResult!,
              isLoading: _isCreatingChat,
              onTap: () => _openOrCreateChat(_searchResult!),
            )
          else if (_userNotFound)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No user found with ID "@$_searchQuery"',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  'Recent Chats',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Chats list
          Expanded(
            child: chatsAsync.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return _EmptyChatsPlaceholder();
                }
                return _ChatsList(
                  chats: chats,
                  onTap: _openChatFromTile,
                );
              },
              loading: () => const LoadingWidget(message: 'Loading chats...'),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load chats.\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SearchResultCard extends StatelessWidget {
  final UserModel user;
  final bool isLoading;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.user,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: _UserAvatar(displayName: user.displayName),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            '@${user.userId}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: isLoading ? null : onTap,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('Chat', style: TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String displayName;
  const _UserAvatar({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ChatsList extends ConsumerWidget {
  final List<ChatModel> chats;
  final void Function(ChatModel) onTap;

  const _ChatsList({required this.chats, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) return const SizedBox.shrink();

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 82),
          itemBuilder: (_, i) {
            final chat = chats[i];
            final otherUid = chat.participants.firstWhere(
              (p) => p != currentUser.uid,
              orElse: () => '',
            );
            return _ChatTileLoader(
              chat: chat,
              otherUid: otherUid,
              onTap: () => onTap(chat),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, stack) => const SizedBox.shrink(),
    );
  }
}

class _ChatTileLoader extends ConsumerWidget {
  final ChatModel chat;
  final String otherUid;
  final VoidCallback onTap;

  const _ChatTileLoader({
    required this.chat,
    required this.otherUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (otherUid.isEmpty) return const SizedBox.shrink();

    final otherUserAsync = ref.watch(otherUserProvider(otherUid));
    final currentUserAsync = ref.watch(currentUserProvider);

    final currentUid = currentUserAsync.value?.uid ?? '';

    return otherUserAsync.when(
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();
        return ChatTile(
          chat: chat,
          otherUser: otherUser,
          currentUid: currentUid,
          onTap: onTap,
        );
      },
      loading: () => const SizedBox(height: 72),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _EmptyChatsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a user ID above\nto start your first chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
