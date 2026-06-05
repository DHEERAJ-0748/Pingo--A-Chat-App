import 'package:intl/intl.dart';

class DateFormatter {
  /// Returns time string for message bubbles (e.g. "3:45 PM").
  static String messageTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  /// Returns a short label for chat list tiles:
  ///  - Today → "3:45 PM"
  ///  - Yesterday → "Yesterday"
  ///  - Older → "Jun 1"
  static String chatTileTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return DateFormat.jm().format(dateTime);
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
