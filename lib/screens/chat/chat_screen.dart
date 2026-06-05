import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatModel chat;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.otherUser,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  bool _isCurrentlyTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser != null && mounted) {
        await ref.read(chatRepositoryProvider).markChatAsRead(
              widget.chat.chatId,
              currentUser.uid,
            );
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref.read(chatRepositoryProvider).setTypingStatus(
            widget.chat.chatId,
            currentUser.uid,
            false,
          );
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() async {
    final text = _messageController.text;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    if (text.trim().isEmpty) {
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        _typingTimer?.cancel();
        await ref.read(chatRepositoryProvider).setTypingStatus(
              widget.chat.chatId,
              currentUser.uid,
              false,
            );
      }
      return;
    }

    if (!_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      await ref.read(chatRepositoryProvider).setTypingStatus(
            widget.chat.chatId,
            currentUser.uid,
            true,
          );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () async {
      if (_isCurrentlyTyping && mounted) {
        _isCurrentlyTyping = false;
        final currUser = ref.read(currentUserProvider).value;
        if (currUser != null) {
          await ref.read(chatRepositoryProvider).setTypingStatus(
                widget.chat.chatId,
                currUser.uid,
                false,
              );
        }
      }
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    _messageController.clear();
    _isCurrentlyTyping = false;
    _typingTimer?.cancel();

    setState(() => _isSending = true);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            chatId: widget.chat.chatId,
            senderId: currentUser.uid,
            receiverId: widget.otherUser.uid,
            text: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _messageController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _confirmDeleteMessage(MessageModel message) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Delete this message for you?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(chatRepositoryProvider).deleteMessageForMe(
                        widget.chat.chatId,
                        message.id,
                        currentUser.uid,
                      );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete message: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messagesAsync =
        ref.watch(messagesStreamProvider(widget.chat.chatId));
    final currentUserAsync = ref.watch(currentUserProvider);

    ref.listen<AsyncValue<List<MessageModel>>>(
      messagesStreamProvider(widget.chat.chatId),
      (prev, next) {
        next.whenData((messages) {
          final currentUser = ref.read(currentUserProvider).value;
          if (currentUser == null) return;
          final hasUnread = messages.any((m) => m.receiverId == currentUser.uid && !m.read);
          if (hasUnread) {
            ref.read(chatRepositoryProvider).markChatAsRead(widget.chat.chatId, currentUser.uid);
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            _ChatAvatar(displayName: widget.otherUser.displayName),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${widget.otherUser.userId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Typing indicator banner below app bar
          ref.watch(chatStreamProvider(widget.chat.chatId)).when(
                data: (chat) {
                   final isTyping =
                       chat?.typingStatus[widget.otherUser.uid] ?? false;
                   if (!isTyping) return const SizedBox.shrink();
                   return Container(
                     width: double.infinity,
                     color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                     padding: const EdgeInsets.symmetric(
                       vertical: 6,
                       horizontal: 16,
                     ),
                     child: Text(
                       '${widget.otherUser.displayName} is typing...',
                       style: TextStyle(
                         fontSize: 12,
                         color: colorScheme.primary,
                         fontStyle: FontStyle.italic,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

          // Messages list
          Expanded(
            child: currentUserAsync.when(
              data: (currentUser) {
                if (currentUser == null) return const SizedBox.shrink();

                return messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _EmptyMessages(
                        otherUser: widget.otherUser,
                      );
                    }
                    _scrollToBottom();
                    return _MessagesList(
                      messages: messages,
                      currentUid: currentUser.uid,
                      scrollController: _scrollController,
                      onDeleteMessage: _confirmDeleteMessage,
                    );
                  },
                  loading: () => const LoadingWidget(message: 'Loading messages...'),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load messages.\n$e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                );
              },
              loading: () => const LoadingWidget(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),

          // Input area
          _MessageInputBar(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ChatAvatar extends StatelessWidget {
  final String displayName;
  const _ChatAvatar({required this.displayName});

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
      width: 38,
      height: 38,
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<MessageModel> messages;
  final String currentUid;
  final ScrollController scrollController;
  final void Function(MessageModel) onDeleteMessage;

  const _MessagesList({
    required this.messages,
    required this.currentUid,
    required this.scrollController,
    required this.onDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final isMine = msg.senderId == currentUid;

        // Show date separator if date changes between messages
        final showDate = i == 0 ||
            !_isSameDay(messages[i - 1].timestamp, msg.timestamp);

        return Column(
          children: [
            if (showDate) _DateSeparator(date: msg.timestamp),
            MessageBubble(
              text: msg.text,
              timestamp: msg.timestamp,
              isSentByMe: isMine,
              onLongPress: () => onDeleteMessage(msg),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252836),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isSending ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSending
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isSending ? Colors.grey.shade700 : null,
                  boxShadow: isSending
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF00BFA5).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  final UserModel otherUser;
  const _EmptyMessages({required this.otherUser});

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.waving_hand_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hi to ${otherUser.displayName}!',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send your first message below.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
