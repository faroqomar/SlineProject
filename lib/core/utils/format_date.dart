/// What: Utilities to format DateTime values into human-friendly and local-time strings.
/// Why: Standardizes how dates/times appear across the UI and avoids duplicated logic.
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

/// Formats a UTC [startUtc]..[endUtc] range into local time like
/// "YYYY-MM-DD  HH:mm → HH:mm"
String formatRangeUtcToLocal(DateTime startUtc, DateTime endUtc) {
  final s = startUtc.toLocal();
  final e = endUtc.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
  String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
  return '${ymd(s)}  ${hm(s)} → ${hm(e)}';
}

/// Formats a single UTC DateTime to local "YYYY-MM-DD  HH:mm".
String formatUtcToLocal(DateTime utc) {
  final d = utc.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  String ymd(DateTime x) => '${x.year}-${two(x.month)}-${two(x.day)}';
  String hm(DateTime x) => '${two(x.hour)}:${two(x.minute)}';
  return '${ymd(d)}  ${hm(d)}';
}

/// Formats a deadline [date] to a "Time Left" string like "2d 4h left" or "Expired".
String formatTimeLeft(DateTime date) {
  final now = DateTime.now().toUtc();
  final diff = date.difference(now);

  if (diff.isNegative) return 'Expired';
  if (diff.inDays > 0) return '${diff.inDays}d left';
  if (diff.inHours > 0) return '${diff.inHours}h left';
  return '${diff.inMinutes}m left';
}
