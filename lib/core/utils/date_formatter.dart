import 'package:intl/intl.dart';

class DateFormatter {
  static String formatMessageTime(int timestampMs) {
    if (timestampMs == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return DateFormat.Hm().format(date);
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat.Hm().format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE HH:mm').format(date);
    } else {
      return DateFormat('dd.MM.yy HH:mm').format(date);
    }
  }

  static String formatChannelTime(int timestampMs) {
    if (timestampMs == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return DateFormat.Hm().format(date);
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('dd.MM').format(date);
    }
  }

  static String formatDateSeparator(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) return 'Today';
    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, MMMM d').format(date);
  }
}
