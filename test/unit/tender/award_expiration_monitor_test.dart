/// Unit tests for AwardExpirationMonitor
///
/// Tests the countdown timer, urgency levels, and proper disposal.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/tasks/viewmodels/award_expiration_monitor.dart';

void main() {
  group('AwardExpirationMonitor', () {
    late AwardExpirationMonitor monitor;

    setUp(() {
      monitor = AwardExpirationMonitor();
    });

    tearDown(() {
      monitor.dispose();
    });

    test('should format countdown correctly for hours and minutes', () {
      // Add a small buffer (5s) to ensure we stay in the same minute during test execution
      final deadline = DateTime.now().add(
        const Duration(hours: 47, minutes: 32, seconds: 5),
      );
      monitor.startMonitoring(deadline);

      expect(monitor.countdownText, '47h 32m');
    });

    test('should show expired when deadline has passed', () {
      final deadline = DateTime.now().subtract(const Duration(hours: 1));
      monitor.startMonitoring(deadline);

      expect(monitor.countdownText, 'Expired');
      expect(monitor.isExpired, true);
    });

    test('should return relaxed urgency when > 24 hours remain', () {
      final deadline = DateTime.now().add(const Duration(hours: 25));
      monitor.startMonitoring(deadline);

      expect(monitor.urgencyLevel, UrgencyLevel.relaxed);
      expect(monitor.shouldPulse, false);
    });

    test('should return urgent urgency when 6-24 hours remain', () {
      final deadline = DateTime.now().add(const Duration(hours: 12));
      monitor.startMonitoring(deadline);

      expect(monitor.urgencyLevel, UrgencyLevel.urgent);
      expect(monitor.shouldPulse, false);
    });

    test('should return critical urgency when < 6 hours remain', () {
      final deadline = DateTime.now().add(
        const Duration(hours: 5, minutes: 30),
      );
      monitor.startMonitoring(deadline);

      expect(monitor.urgencyLevel, UrgencyLevel.critical);
      expect(monitor.shouldPulse, true);
    });

    test('should return expired urgency when deadline passed', () {
      final deadline = DateTime.now().subtract(const Duration(hours: 1));
      monitor.startMonitoring(deadline);

      expect(monitor.urgencyLevel, UrgencyLevel.expired);
      expect(monitor.shouldPulse, true);
    });

    test('should return correct urgency colors', () {
      // Relaxed - green
      monitor.startMonitoring(DateTime.now().add(const Duration(hours: 25)));
      expect(monitor.urgencyColor, 'green');

      // Urgent - orange
      monitor.startMonitoring(DateTime.now().add(const Duration(hours: 12)));
      expect(monitor.urgencyColor, 'orange');

      // Critical - red
      monitor.startMonitoring(DateTime.now().add(const Duration(hours: 5)));
      expect(monitor.urgencyColor, 'red');

      // Expired - grey
      monitor.startMonitoring(
        DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(monitor.urgencyColor, 'grey');
    });

    test('should notify listeners when started', () {
      final deadline = DateTime.now().add(const Duration(hours: 24));

      var notificationCount = 0;
      monitor
        ..addListener(() => notificationCount++)
        ..startMonitoring(deadline);

      // Should notify immediately on start
      expect(notificationCount, greaterThanOrEqualTo(1));
    });

    test('should properly dispose and prevent operations', () {
      final deadline = DateTime.now().add(const Duration(hours: 24));

      monitor.startMonitoring(deadline);
      expect(monitor.isDisposed, false);

      monitor.dispose();

      expect(monitor.isDisposed, true);
      expect(monitor.paymentDeadline, null);
    });

    test('should not crash when operations called on disposed monitor', () {
      monitor.dispose();

      // These should not throw
      final deadline = DateTime.now().add(const Duration(hours: 24));
      monitor.startMonitoring(deadline); // Should log warning but not crash
      expect(monitor.countdownText, null);
    });

    test('should update urgency when deadline changes', () {
      // Start with relaxed
      monitor.startMonitoring(DateTime.now().add(const Duration(hours: 25)));
      expect(monitor.urgencyLevel, UrgencyLevel.relaxed);

      // Update to critical
      monitor.startMonitoring(DateTime.now().add(const Duration(hours: 3)));
      expect(monitor.urgencyLevel, UrgencyLevel.critical);
    });
  });
}
