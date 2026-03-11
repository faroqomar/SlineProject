/// What: Helpers to format prices (and simple dates) for consistent UI display.
/// Why: Centralizes IQD display rules: K-abbreviation for large amounts, full value for small, currency at end.
/// Single source of truth for all money display across wallet, tasks, booking, work, services, management.
class PriceFormatter {
  /// Format amount in IQD for display.
  /// - Small (< 1,000): full value, e.g. "950 IQD"
  /// - Large (>= 1,000): abbreviated with K, no decimal K, e.g. "75K IQD", "12K IQD"
  static String formatPrice(double amountIqd, {String suffix = 'IQD'}) {
    final abs = amountIqd.abs();
    final rounded = amountIqd.round();
    if (abs < 1000) {
      return '$rounded $suffix';
    }
    final valueK = (rounded.abs() / 1000).truncate();
    final prefix = amountIqd < 0 ? '-' : '';
    return '$prefix${valueK}K $suffix';
  }

  /// Format price range (min - max) using same IQD rules.
  static String formatPriceRange(
    double minPrice,
    double maxPrice, {
    String suffix = 'IQD',
  }) {
    return '${formatPrice(minPrice, suffix: suffix)} - ${formatPrice(maxPrice, suffix: suffix)}';
  }
}

class DateFormatter {
  /// Simple DD/MM/YYYY
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Humanized time ago
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }
}
