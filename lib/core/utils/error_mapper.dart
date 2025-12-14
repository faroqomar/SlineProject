import 'dart:io';
import 'dart:async';
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

    // Check for wrapped exceptions
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      if (message.contains('not authenticated') ||
          message.contains('sign in')) {
        return 'Please sign in to continue.';
      }
    }

    // Fallback
    return 'An error occurred. Please try again.';
  }

  /// Maps PostgrestException to user-friendly message.
  static String _mapPostgrestError(PostgrestException error) {
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
    if (message.contains('session expired') || message.contains('refresh token')) {
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


