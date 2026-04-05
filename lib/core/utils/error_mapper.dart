import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps technical exceptions to user-friendly error messages.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   final userMessage = ErrorMapper.map(e);
///   // Show userMessage to user
/// }
/// ```
///
/// Reference: .cursor/rules/error-handling.mdc
class ErrorMapper {
  /// Maps any exception to a user-friendly message.
  static String map(dynamic error) {
    if (error is PostgrestException) {
      return _mapPostgrestError(error);
    }

    if (error is AuthException) {
      return _mapAuthError(error);
    }

    if (error is StorageException) {
      return _mapStorageError(error);
    }

    if (error is SocketException) {
      return 'Cannot reach the server. Check your connection and retry.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    if (error is HttpException) {
      return 'Network error occurred. Please try again.';
    }

    // Check for wrapped exceptions (only surface unwrapped text if it looks user-friendly)
    if (error is Exception) {
      final raw = error.toString();
      var unwrapped = raw;
      if (raw.startsWith('Exception: ') && raw.length > 'Exception: '.length) {
        unwrapped = raw.substring('Exception: '.length);
      } else if (raw.startsWith('Bad state: ') &&
          raw.length > 'Bad state: '.length) {
        unwrapped = raw.substring('Bad state: '.length);
      }

      final message = unwrapped.toLowerCase();
      if (message.contains('not authenticated') ||
          message.contains('sign in')) {
        return 'Please sign in to continue.';
      }
      // Only return unwrapped content if it does not look like technical leakage
      if (unwrapped != raw && !_looksLikeTechnicalMessage(unwrapped)) {
        return unwrapped;
      }
    }

    // Fallback
    return 'An error occurred. Please try again.';
  }

  /// Maps PostgrestException to user-friendly message.
  static String _mapPostgrestError(PostgrestException error) {
    final message = error.message;

    if (message.contains(
          'Could not find the function public.rpc_approve_delivery',
        ) &&
        message.contains('schema cache')) {
      return 'This feature is temporarily unavailable. Please try again later or contact support.';
    }
    if (message.contains(
      'release_with_fee only allowed for booking, task_request, or direct_offer entities',
    )) {
      return 'This feature is temporarily unavailable. Please try again later or contact support.';
    }

    // Chat Creation Matrix specific errors (P0001 user-defined exceptions)
    if (message.contains('Freelancers cannot start direct conversations')) {
      return 'Only clients can start conversations with freelancers.';
    }
    if (message.contains('favorites list')) {
      return 'Add this freelancer to your favorites first to start a conversation.';
    }
    if (message.contains('Rate limit exceeded')) {
      return "You've reached the conversation limit. Try again in an hour.";
    }
    if (message.contains('Target user not found')) {
      return 'User not found. They may have deleted their account.';
    }
    if (message.contains('Cannot create conversation with yourself')) {
      return "You can't start a conversation with yourself.";
    }
    if (message.contains('initiated_by must equal current user')) {
      return 'Session expired. Please log in again.';
    }
    if (message.contains(
      'task owner cannot start a task-linked conversation',
    )) {
      return 'You cannot start a conversation on this task.';
    }
    // Work contract revision (rpc_request_revision)
    if (message.contains('Can only request revision on delivered work')) {
      return 'You can only request a revision when the work is delivered.';
    }
    if (message.contains('No revisions remaining')) {
      return 'No revisions remaining. You have used all allowed revision requests.';
    }
    if (message.contains('Only client can request revision')) {
      return 'Only the client can request a revision.';
    }
    // Frozen guard (submit_delivery, request_revision)
    if (message.contains('Cannot submit delivery: dispute in progress')) {
      return 'Cannot submit delivery while a dispute is in progress.';
    }
    if (message.contains('Cannot request revision: dispute in progress')) {
      return 'Cannot request a revision while a dispute is in progress.';
    }
    // Dispute submit (rpc_submit_dispute)
    if (message.contains('Entity not eligible for dispute')) {
      return 'This item is not in a state that allows raising a dispute.';
    }
    if (message.contains('open or active dispute already exists')) {
      return 'A dispute is already open for this item.';
    }
    if (message.contains('Reason is required')) {
      return 'Please provide a reason for the dispute.';
    }
    if (message.contains('Exactly one of task_id or direct_offer_id')) {
      return 'Invalid dispute request.';
    }

    switch (error.code) {
      case '42501': // RLS denied
        return 'Session expired. Please log in again.';
      case '23505': // Unique violation
        return 'This item already exists.';
      case '23503': // Foreign key violation
        return 'Related item does not exist.';
      case '23514': // Check constraint violation
        return 'Invalid data provided.';
      case '22P02': // Invalid input syntax (UUID, etc.)
        return 'Invalid identifier provided.';
      case '42P01': // Table does not exist
        return 'Service unavailable. Please contact support.';
      default:
        return 'Database error occurred. Please try again.';
    }
  }

  /// Maps AuthException to user-friendly message.
  static String _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }
    if (message.contains('email already registered') ||
        message.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('weak password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email address first.';
    }
    if (message.contains('session expired') ||
        message.contains('refresh token')) {
      return 'Session expired. Please log in again.';
    }

    return 'Authentication error. Please try again.';
  }

  /// Maps StorageException to user-friendly message.
  static String _mapStorageError(StorageException error) {
    final statusCode = error.statusCode;
    final message = error.message.toLowerCase();

    if (statusCode == '404' || message.contains('not found')) {
      return 'File not available.';
    }
    if (statusCode == '413' ||
        message.contains('payload too large') ||
        message.contains('size')) {
      return 'File is too large. Please choose a smaller file.';
    }
    if (statusCode == '400' || message.contains('invalid')) {
      return 'Invalid file type. Please choose a different file.';
    }
    if (message.contains('permission') || message.contains('policy')) {
      return 'You do not have permission to access this file.';
    }
    if (message.contains('bucket not found')) {
      return 'Storage is not configured. Please contact support.';
    }

    return 'Upload failed. Please try again.';
  }

  /// Returns true if the message looks like internal/technical content (SQL, paths, codes).
  static bool _looksLikeTechnicalMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('sql') ||
        lower.contains('select ') ||
        lower.contains('insert ') ||
        lower.contains('update ') ||
        lower.contains('column ') ||
        lower.contains('table ') ||
        lower.contains('schema') ||
        lower.contains('migration') ||
        lower.contains('rpc_') ||
        lower.contains('public.') ||
        lower.contains('.dart') ||
        lower.contains(' at ') ||
        lower.contains('line ') ||
        lower.contains('stack') ||
        lower.contains('null') ||
        RegExp(r'\b[0-9]{5}\b').hasMatch(message); // e.g. Postgres error codes
  }

  /// Check if error indicates session expired (for redirect to login).
  static bool isSessionExpired(dynamic error) {
    if (error is PostgrestException && error.code == '42501') {
      return true;
    }
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      return message.contains('session expired') ||
          message.contains('refresh token') ||
          message.contains('jwt expired');
    }
    return false;
  }
}
