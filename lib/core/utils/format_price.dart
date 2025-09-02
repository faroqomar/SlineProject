/// What: Helpers to format prices (and simple dates) for consistent UI display.
/// Why: Centralizes currency/range formatting rules (e.g., IQD without decimals).
/// Utility functions for price and date formatting
class PriceFormatter {
  /// Format price for IQD by default with no decimals (common local display)
  static String formatPrice(double price, {String currency = 'IQD '}) {
    // IQD usually shown without fractional part
    final rounded = price.round();
    return '$currency$rounded';
  }

  /// Format price range (min - max)
  static String formatPriceRange(double minPrice, double maxPrice, {String currency = 'IQD '}) {
    return '${formatPrice(minPrice, currency: currency)} - ${formatPrice(maxPrice, currency: currency)}';
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
