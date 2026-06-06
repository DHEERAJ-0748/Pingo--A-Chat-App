import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final VoidCallback? onLongPress;
  final String? replyText;
  final String? replySenderName;
  final VoidCallback? onReplyTap;
  final bool isDeletedForEveryone;

  const MessageBubble({
    super.key,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.onLongPress,
    this.replyText,
    this.replySenderName,
    this.onReplyTap,
    this.isDeletedForEveryone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isDeletedForEveryone ? null : onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isSentByMe ? 64 : 12,
            right: isSentByMe ? 12 : 64,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSentByMe
                ? AppTheme.sentBubbleColor
                : AppTheme.receivedBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isSentByMe
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
              bottomRight: isSentByMe
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDeletedForEveryone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block_flipped,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else ...[
                if (replyText != null && replySenderName != null)
                  GestureDetector(
                    onTap: onReplyTap,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: isSentByMe ? const Color(0xFF00BFA5) : const Color(0xFFFFB300),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            replySenderName!,
                            style: TextStyle(
                              color: isSentByMe ? const Color(0xFF00BFA5) : const Color(0xFFFFB300),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyText!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                DateFormatter.messageTime(timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
