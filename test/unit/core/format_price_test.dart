import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/utils/format_price.dart';

void main() {
  group('PriceFormatter', () {
    test('formatPrice returns rounded full value for amounts below 1000', () {
      expect(PriceFormatter.formatPrice(950.4), '950 IQD');
      expect(PriceFormatter.formatPrice(-120.6), '-121 IQD');
    });

    test('formatPrice abbreviates to K for amounts >= 1000', () {
      expect(PriceFormatter.formatPrice(12000), '12K IQD');
      expect(PriceFormatter.formatPrice(1999), '1K IQD');
      expect(PriceFormatter.formatPrice(-75555), '-75K IQD');
    });

    test('formatPrice supports custom suffix', () {
      expect(PriceFormatter.formatPrice(1500, suffix: 'USD'), '1K USD');
    });

    test('formatPriceRange formats both values with same rules', () {
      expect(PriceFormatter.formatPriceRange(999, 5500), '999 IQD - 5K IQD');
      expect(
        PriceFormatter.formatPriceRange(1000, 2000, suffix: 'USD'),
        '1K USD - 2K USD',
      );
    });
  });

  group('DateFormatter (in format_price.dart)', () {
    test('formatDate returns DD/MM/YYYY', () {
      expect(DateFormatter.formatDate(DateTime(2026, 4, 18)), '18/4/2026');
    });

    test('timeAgo returns days branch', () {
      final date = DateTime.now().subtract(const Duration(days: 2, hours: 1));
      expect(DateFormatter.timeAgo(date), '2 days ago');
    });

    test('timeAgo returns hours branch', () {
      final date = DateTime.now().subtract(
        const Duration(hours: 3, minutes: 10),
      );
      expect(DateFormatter.timeAgo(date), '3 hours ago');
    });

    test('timeAgo returns minutes branch', () {
      final date = DateTime.now().subtract(
        const Duration(minutes: 12, seconds: 40),
      );
      expect(DateFormatter.timeAgo(date), '12 minutes ago');
    });

    test('timeAgo returns just now branch', () {
      final date = DateTime.now().subtract(const Duration(seconds: 20));
      expect(DateFormatter.timeAgo(date), 'Just now');
    });
  });
}
