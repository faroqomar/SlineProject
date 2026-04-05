import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/booking/view/booking_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers deep link handlers for booking entity types.
///
/// Handles: 'booking'.
void registerBookingDeepLinks(DeepLinkRegistry registry) {
  registry.register('booking', _handleBooking);
}

Future<void> _handleBooking(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d('Deep link: navigating to booking $entityId', tag: 'DeepLink');
  if (!context.mounted) return;
  _showLoading(context);

  try {
    final bookingService = BookingService(Supabase.instance.client);
    final booking = await bookingService.getBookingById(entityId);
    if (!context.mounted) return;
    _hideLoading(context);

    if (context.mounted) {
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(booking: booking),
          ),
        ),
      );
    }
  } on Exception catch (e) {
    AppLogger.e(
      'Deep link: failed to load booking $entityId: $e',
      tag: 'DeepLink',
    );
    if (!context.mounted) return;
    _hideLoading(context);
    rethrow;
  }
}

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

void _hideLoading(BuildContext context) {
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
