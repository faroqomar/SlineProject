import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/utils/format_date.dart';

String _two(int n) => n.toString().padLeft(2, '0');

void main() {
  group('formatFriendlyTime', () {
    test('returns Now for less than one minute', () {
      final date = DateTime.now().subtract(const Duration(seconds: 10));
      expect(formatFriendlyTime(date), 'Now');
    });

    test('returns minutes for less than one hour', () {
      final date = DateTime.now().subtract(
        const Duration(minutes: 5, seconds: 30),
      );
      expect(formatFriendlyTime(date), '5m ago');
    });

    test('returns hours for less than one day', () {
      final date = DateTime.now().subtract(
        const Duration(hours: 3, minutes: 15),
      );
      expect(formatFriendlyTime(date), '3h ago');
    });

    test('returns Yesterday for one day difference', () {
      final date = DateTime.now().subtract(const Duration(days: 1, minutes: 5));
      expect(formatFriendlyTime(date), 'Yesterday');
    });

    test('returns days for under a week', () {
      final date = DateTime.now().subtract(const Duration(days: 4, hours: 2));
      expect(formatFriendlyTime(date), '4d ago');
    });

    test('returns DD/MM/YYYY for one week or older', () {
      final date = DateTime.now().subtract(const Duration(days: 10));
      expect(
        formatFriendlyTime(date),
        '${date.day}/${date.month}/${date.year}',
      );
    });
  });

  group('UTC to local formatters', () {
    test('formatRangeUtcToLocal renders local start date and local times', () {
      final startUtc = DateTime.utc(2026, 4, 18, 10, 5);
      final endUtc = DateTime.utc(2026, 4, 18, 12, 45);
      final startLocal = startUtc.toLocal();
      final endLocal = endUtc.toLocal();

      final expected =
          '${startLocal.year}-${_two(startLocal.month)}-${_two(startLocal.day)}  '
          '${_two(startLocal.hour)}:${_two(startLocal.minute)} → '
          '${_two(endLocal.hour)}:${_two(endLocal.minute)}';

      expect(formatRangeUtcToLocal(startUtc, endUtc), expected);
    });

    test('formatUtcToLocal renders local YYYY-MM-DD HH:mm', () {
      final utc = DateTime.utc(2026, 6, 1, 8, 9);
      final local = utc.toLocal();
      final expected =
          '${local.year}-${_two(local.month)}-${_two(local.day)}  '
          '${_two(local.hour)}:${_two(local.minute)}';

      expect(formatUtcToLocal(utc), expected);
    });
  });

  group('formatTimeLeft', () {
    test('returns Expired for past times', () {
      final date = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      expect(formatTimeLeft(date), 'Expired');
    });

    test('returns days left when more than one day remains', () {
      final date = DateTime.now().toUtc().add(
        const Duration(days: 2, hours: 3),
      );
      expect(formatTimeLeft(date), '2d left');
    });

    test('returns hours left when less than one day remains', () {
      final date = DateTime.now().toUtc().add(
        const Duration(hours: 5, minutes: 20),
      );
      expect(formatTimeLeft(date), '5h left');
    });

    test('returns minutes left when less than one hour remains', () {
      final date = DateTime.now().toUtc().add(
        const Duration(minutes: 40, seconds: 30),
      );
      expect(formatTimeLeft(date), '40m left');
    });
  });
}
