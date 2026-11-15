import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';

/// Premium floating header for the chat screen.
/// Shows back button, avatar, contact name, user ID and any existing actions.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.otherUser,
    required this.onBack,
    this.onInfoTap,
  });

  final UserModel otherUser;
  final VoidCallback onBack;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: AppTheme.primaryColor,
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          // Avatar – reuse same style as chat_tile avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              otherUser.displayName.isNotEmpty
                  ? otherUser.displayName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  otherUser.displayName,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${otherUser.userId}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onInfoTap != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              color: AppTheme.primaryColor,
              onPressed: onInfoTap,
            ),
        ],
      ),
    );
  }
}
