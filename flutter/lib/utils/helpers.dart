import 'package:intl/intl.dart';

// ─── Validators ──────────────────────────────────────────────────────────────
class Validators {
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'This field'}) {
    if (value == null || value.length < min) return '$field must be at least $min characters';
    return null;
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class Helpers {
  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024)          return '$bytes B';
    if (bytes < 1024 * 1024)   return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format duration to MM:SS or HH:MM:SS
  static String formatDuration(Duration d) {
    final hours   = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  /// Format date to readable string
  static String formatDate(DateTime date, {String pattern = 'MMM d, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    if (diff.inDays < 30)     return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays < 365)    return '${(diff.inDays / 30).round()}mo ago';
    return '${(diff.inDays / 365).round()}y ago';
  }

  /// Get media type icon name
  static String mediaTypeLabel(String type) {
    switch (type) {
      case 'video': return 'Video';
      case 'audio': return 'Audio';
      case 'photo': return 'Photo';
      default:      return 'Media';
    }
  }

  /// Generate a unique local ID
  static String generateId() =>
    DateTime.now().millisecondsSinceEpoch.toString();

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
