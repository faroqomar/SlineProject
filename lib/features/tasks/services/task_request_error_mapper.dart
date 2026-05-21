import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/exceptions/offer_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Error mapper for task request (offer/bid) operations.
///
/// Extracted from [TaskRequestsService] to keep the parent service focused
/// on core CRUD and business logic. All Postgrest error → user-friendly
/// message translation lives here.
class TaskRequestErrorMapper {
  const TaskRequestErrorMapper();

  // ============================================================================
  // Public API
  // ============================================================================

  /// Maps any RPC error to a user-friendly message.
  ///
  /// This is a public helper that can be used by ViewModels
  /// to get consistent error messages.
  String mapErrorToUserMessage(Object? error) {
    if (error is PriceMismatchException) {
      return error.userMessage;
    }
    if (error is OfferAlreadyAcceptedException) {
      return error.userMessage;
    }
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();

      // Try specific mappings first
      if (msg.contains('price_mismatch')) {
        return 'The offer price changed. Please review the updated price.';
      }
      if (msg.contains('already_accepted')) {
        return 'This offer has already been accepted.';
      }
      if (msg.contains('only task owner')) {
        return 'Only the task owner can perform this action.';
      }
      if (msg.contains('request not found') || msg.contains('not pending')) {
        return 'This offer is no longer available.';
      }

      // Generic Postgrest mapping
      return mapSubmitOfferError(error);
    }

    // Generic fallback
    return 'An error occurred. Please try again.';
  }

  /// Maps PostgrestException to typed exceptions for accept operations.
  Exception mapAcceptError(PostgrestException e) {
    final message = e.message;
    final lowercaseMessage = message.toLowerCase();

    // Check for PRICE_MISMATCH error
    if (lowercaseMessage.contains('price_mismatch')) {
      // Parse the expected and actual prices from error message
      // Format: "PRICE_MISMATCH: Offer price changed from X to Y cents"
      final regex = RegExp(r'from (\d+) to (\d+)');
      final match = regex.firstMatch(message);

      if (match != null) {
        final expectedCents = int.tryParse(match.group(1) ?? '0') ?? 0;
        final actualCents = int.tryParse(match.group(2) ?? '0') ?? 0;

        AppLogger.w(
          'Price mismatch: expected $expectedCents cents, got $actualCents cents',
          tag: 'Offers',
        );

        return PriceMismatchException(
          expectedCents: expectedCents,
          actualCents: actualCents,
        );
      }

      return const PriceMismatchException(expectedCents: 0, actualCents: 0);
    }

    // Check for already accepted (idempotency hit)
    if (lowercaseMessage.contains('already_accepted')) {
      return const OfferAlreadyAcceptedException();
    }

    // Fallback to generic error mapping
    return Exception(mapDecisionError(e));
  }

  // ============================================================================
  // Specific Error Mappers
  // ============================================================================

  /// Maps submitOffer RPC/database errors to user-friendly messages.
  ///
  /// Error conditions from API_CONTRACT.md:
  /// - Duplicate pending offer (unique constraint violation)
  /// - RLS policy denial (task closed or user is owner)
  /// - Invalid input data
  String mapSubmitOfferError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    // Duplicate pending offer (unique constraint)
    if (message.contains('ux_task_requests_pending_per_user') ||
        (message.contains('duplicate key') &&
            message.contains('task_id') &&
            message.contains('bidder_id'))) {
      return 'You already have a pending offer on this task. Update your existing offer instead.';
    }

    // RLS policy denial (42501 = insufficient privilege)
    if (code == '42501' ||
        message.contains('policy') ||
        message.contains('row-level security') ||
        message.contains('new row violates row-level security policy')) {
      return 'You cannot submit an offer. The task might be closed or you are the task owner.';
    }

    // Foreign key violation - task doesn't exist
    if (code == '23503' || message.contains('foreign key')) {
      return 'This task no longer exists or is unavailable.';
    }

    // Check constraint violation
    if (code == '23514' || message.contains('check constraint')) {
      return 'Invalid offer details. Please check your price and delivery time.';
    }

    // Invalid input syntax
    if (code == '22P02' || message.contains('invalid input syntax')) {
      return 'Invalid data provided. Please try again.';
    }

    // Not authenticated (should be caught earlier, but just in case)
    if (message.contains('unauthenticated') || message.contains('auth')) {
      return 'Please sign in to submit an offer.';
    }

    // Task not open
    if (message.contains('task_not_found_or_not_open_or_own_task') ||
        message.contains('not open')) {
      return 'This task is not accepting new offers at this time.';
    }

    // Fallback
    return 'Unable to submit your offer right now. Please try again later.';
  }

  /// Maps replaceOffer RPC errors to user-friendly messages.
  ///
  /// Error conditions from API_CONTRACT.md:
  /// - Only offer owner can replace their offer
  /// - Only freelancers can replace offers
  /// - Task not found, not open, or own task
  String mapReplaceOfferError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    // Function overload ambiguity (p_price integer vs numeric) — not a user role error
    if (message.contains('could not choose the best candidate function') ||
        message.contains('ambiguous')) {
      return 'Unable to update your offer right now. Please try again later.';
    }

    // Offer ownership check
    if (message.contains('only the offer owner can replace') ||
        message.contains('offer owner')) {
      return 'You can only replace your own offers.';
    }

    // Freelancer role requirement (explicit exception text; avoid matching param names like p_freelancer_id)
    if (message.contains('only freelancers can replace offers') ||
        message.contains('you need freelancer access')) {
      return 'You need freelancer access to update offers.';
    }

    // Task not found, not open, or own task
    if (message.contains('task_not_found_or_not_open_or_own_task') ||
        message.contains('not open') ||
        message.contains('own task')) {
      return 'This task is no longer open for offers or you cannot bid on your own task.';
    }

    // No existing offer to replace (RPC raises no_pending_offer_to_replace when UPDATE matches 0 rows)
    if (message.contains('no_pending_offer_to_replace') ||
        message.contains('no pending offer') ||
        message.contains('not found')) {
      return "You don't have an active offer to update on this task.";
    }

    // RLS denial
    if (code == '42501' ||
        message.contains('policy') ||
        message.contains('row-level security')) {
      return 'You cannot update this offer. Please try again later.';
    }

    // Not authenticated
    if (message.contains('unauthenticated') || message.contains('auth')) {
      return 'Please sign in to update your offer.';
    }

    // Fallback
    return 'Unable to update your offer right now. Please try again later.';
  }

  /// Maps reject RPC errors to user-friendly messages.
  ///
  /// Error conditions from API_CONTRACT.md:
  /// - Not authenticated
  /// - Task not found
  /// - Only task owner can reject
  /// - Request not found or already processed
  String mapRejectError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    // Task owner authorization
    if (message.contains('only task owner can reject') ||
        message.contains('forbidden') ||
        message.contains('not authorized')) {
      return 'Only the task owner can reject offers.';
    }

    // Task not found
    if (message.contains('task_not_found') ||
        (message.contains('not found') && message.contains('task'))) {
      return 'This task no longer exists.';
    }

    // Request not found or already processed
    if (message.contains('request not found or already processed') ||
        message.contains('not pending') ||
        message.contains('already processed')) {
      return 'This offer is no longer available for rejection.';
    }

    // Not authenticated
    if (code == 'P0001' && message.contains('unauthenticated')) {
      return 'Please sign in to manage offers.';
    }

    // RLS denial
    if (code == '42501' ||
        message.contains('policy') ||
        message.contains('row-level security')) {
      return "You don't have permission to reject this offer.";
    }

    // Fallback to generic decision error mapping
    return mapDecisionError(error);
  }

  /// Maps generic decision errors (accept/reject) to user-friendly messages.
  String mapDecisionError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('only task owner') || message.contains('forbidden')) {
      return 'Only the task owner can perform this action.';
    }
    if (message.contains('already processed') ||
        message.contains('not pending') ||
        message.contains('request not found')) {
      return 'This offer is no longer available for action.';
    }
    return 'Unable to update the offer right now. Please try again.';
  }
}
