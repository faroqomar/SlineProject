/// Utility function to format DateTime objects into human-friendly strings.
/// This is used in both conversation list and chat screens to show relative times.
///
/// Examples:
/// - "Now" if less than 1 minute ago
/// - "5m ago" if less than 1 hour ago
/// - "2h ago" if less than 24 hours ago
/// - "Yesterday" if exactly 1 day ago
/// - "3d ago" if less than 7 days ago
/// - "DD/MM/YYYY" for anything older
String formatFriendlyTime(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);

  if (difference.inMinutes < 1) return 'Now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  // Fallback for older dates: show as DD/MM/YYYY
  return '${time.day}/${time.month}/${time.year}';
}
