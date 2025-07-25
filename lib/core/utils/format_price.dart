/// Utility functions for price formatting
class PriceFormatter {
  /// Format price with currency symbol
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }

  /// Format price range
  static String formatPriceRange(double minPrice, double maxPrice, {String currency = '\$'}) {
    return '${formatPrice(minPrice, currency: currency)} - ${formatPrice(maxPrice, currency: currency)}';
  }
}

/// Utility functions for date formatting
class DateFormatter {
  /// Format date to readable string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format time ago (e.g., "2 hours ago")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
