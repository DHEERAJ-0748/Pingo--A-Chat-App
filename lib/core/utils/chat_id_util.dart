class ChatIdUtil {
  /// Generates a deterministic chat ID by sorting two UIDs and joining with '_'.
  /// This ensures the same chat ID is produced regardless of argument order.
  static String generate(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
