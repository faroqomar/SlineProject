import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/format_price.dart';
import '../models/task_request_model.dart';

// Re-export exceptions for backward compatibility
export '../exceptions/offer_exceptions.dart';

/// Result class for bid replaceability check.
///
/// Contains a boolean indicating if a bid is replaceable
/// and the existing bid if one exists.
class BidReplaceabilityResult {
  /// True if the user can replace their existing bid
  /// (i.e., they have a pending bid that can be withdrawn and replaced).
  final bool isReplaceable;

  /// The existing pending bid if one exists, null otherwise.
  final TaskRequest? existingBid;

  const BidReplaceabilityResult({
    required this.isReplaceable,
    this.existingBid,
  });

  /// Factory for when there is no existing bid (user can submit new bid).
  factory BidReplaceabilityResult.noExistingBid() {
    return const BidReplaceabilityResult(
      isReplaceable: true,
      existingBid: null,
    );
  }

  /// Factory for when there is a pending bid that can be replaced.
  factory BidReplaceabilityResult.canReplace(TaskRequest existingBid) {
    return BidReplaceabilityResult(
      isReplaceable: true,
      existingBid: existingBid,
    );
  }

  /// Factory for when there is a non-pending bid that cannot be replaced.
  factory BidReplaceabilityResult.cannotReplace(TaskRequest existingBid) {
    return BidReplaceabilityResult(
      isReplaceable: false,
      existingBid: existingBid,
    );
  }
}

/// Service for handling task offer/bid operations.
class TaskRequestsService {
  final SupabaseClient _client;

  // Bid expiration duration (24 hours)
  static const Duration _bidExpirationDuration = Duration(hours: 24);

  // Rate limiting: minimum time between submits (2 seconds)
  static const Duration _rateLimitDuration = Duration(seconds: 2);

  // Last submit timestamp for rate limiting
  DateTime? _lastSubmitTime;

  static const String _selectWithProfile = '''
    id, task_id, bidder_id, freelancer_id, price, days, duration_days,
    note, message, status, payment_status, created_at, updated_at, deleted_at,
    payment_deadline,
    profiles!task_requests_freelancer_id_fkey(full_name, avatar_url),
    tasks(title)
  ''';

  TaskRequestsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns the current user's pending offer for the task, if any.
  Future<TaskRequest?> getExistingActiveOfferForCurrentUser(
    String taskId,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      AppLogger.d(
        'Checking existing active offer for task $taskId and user $uid',
        tag: 'Offers',
      );
      final rows = await _client
          .from('task_requests')
          .select()
          .eq('task_id', taskId)
          .eq('freelancer_id', uid)
          .is_('deleted_at', null)
          .eq('status', 'pending')
          .limit(1);
      if (rows.isEmpty) return null;
      return TaskRequest.fromMap(rows.first as Map<String, dynamic>);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to load existing active offer for task $taskId',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Gets the expiration time for a bid (created_at + 24 hours).
  ///
  /// Fetches the bid from the database by [bidId], then returns
  /// the expiration time calculated as created_at + 24 hours.
  /// Returns null if bid not found or user is not authenticated.
  Future<DateTime?> getBidExpirationTime(String bidId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.w(
        'Cannot get expiration time: not authenticated',
        tag: 'Offers',
      );
      return null;
    }

    AppLogger.d('Fetching bid expiration time for bid $bidId', tag: 'Offers');

    try {
      final row = await _client
          .from('task_requests')
          .select('created_at')
          .eq('id', bidId)
          .single();

      final createdAt = DateTime.parse(row['created_at'] as String);
      final expirationTime = createdAt.add(_bidExpirationDuration);

      AppLogger.d(
        'Bid $bidId created at $createdAt, expires at $expirationTime',
        tag: 'Offers',
      );

      return expirationTime;
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to fetch bid expiration time for $bidId',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      return null;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Unexpected error fetching bid expiration time for $bidId',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Checks if a bid has expired (now > created_at + 24 hours).
  ///
  /// Uses the [bid]'s createdAt timestamp and compares against
  /// current time. Returns true if the bid is past its 24-hour window.
  bool isBidExpired(TaskRequest bid) {
    final expirationTime = bid.createdAt.add(_bidExpirationDuration);
    final isExpired = DateTime.now().isAfter(expirationTime);

    AppLogger.d(
      'Checking bid ${bid.id} expiration: created=${bid.createdAt}, '
      'expires=$expirationTime, expired=$isExpired',
      tag: 'Offers',
    );

    return isExpired;
  }

  /// Checks if the current user has an existing pending bid on the task
  /// that can be replaced.
  ///
  /// Returns [BidReplaceabilityResult] containing:
  /// - isReplaceable: true if user has a pending bid (can replace), false otherwise
  /// - existingBid: the existing bid if one exists
  Future<BidReplaceabilityResult> isBidReplaceable(String taskId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.w(
        'Cannot check bid replaceability: not authenticated',
        tag: 'Offers',
      );
      return const BidReplaceabilityResult(
        isReplaceable: false,
        existingBid: null,
      );
    }

    AppLogger.d(
      'Checking bid replaceability for task $taskId and user $uid',
      tag: 'Offers',
    );

    try {
      // Fetch all bids by this user on this task
      final rows = await _client
          .from('task_requests')
          .select(_selectWithProfile)
          .eq('task_id', taskId)
          .eq('freelancer_id', uid)
          .is_('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        AppLogger.d('No existing bid found for task $taskId', tag: 'Offers');
        return BidReplaceabilityResult.noExistingBid();
      }

      final existingBid = TaskRequest.fromMap(
        rows.first as Map<String, dynamic>,
      );

      // Only pending bids are replaceable
      if (existingBid.isPending) {
        AppLogger.d(
          'Found pending bid ${existingBid.id} - can replace',
          tag: 'Offers',
        );
        return BidReplaceabilityResult.canReplace(existingBid);
      }

      // Non-pending bids (accepted, rejected, withdrawn) cannot be replaced
      AppLogger.d(
        'Found non-pending bid ${existingBid.id} with status ${existingBid.status.name} - cannot replace',
        tag: 'Offers',
      );
      return BidReplaceabilityResult.cannotReplace(existingBid);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check bid replaceability for task $taskId',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      return const BidReplaceabilityResult(
        isReplaceable: false,
        existingBid: null,
      );
    }
  }

  /// Checks if rate limiting should block a submit operation.
  ///
  /// Prevents submit if less than 2 seconds have passed since the last submit.
  /// Uses AppLogger to log rate limit events.
  ///
  /// Returns true if the operation should be blocked (rate limited).
  bool _isRateLimited() {
    final now = DateTime.now();

    if (_lastSubmitTime != null) {
      final elapsed = now.difference(_lastSubmitTime!);
      if (elapsed < _rateLimitDuration) {
        final remaining = _rateLimitDuration - elapsed;
        AppLogger.w(
          'Rate limit triggered: ${elapsed.inMilliseconds}ms since last submit, '
          'need to wait ${remaining.inMilliseconds}ms more',
          tag: 'Offers',
        );
        return true;
      }
    }

    // Update last submit time
    _lastSubmitTime = now;
    return false;
  }

  /// List offers for a task with pagination.
  Future<List<TaskRequest>> listByTask({
    required String taskId,
    int limit = 20,
    DateTime? before,
  }) async {
    AppLogger.d('Fetching offers for task $taskId', tag: 'Offers');

    try {
      // Select * from task_requests and join profiles using explicit FK
      var query = _client
          .from('task_requests')
          .select(_selectWithProfile)
          .eq('task_id', taskId)
          .is_('deleted_at', null);

      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final result = (data as List<dynamic>)
          .map((e) => TaskRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      AppLogger.i('Loaded ${result.length} offers', tag: 'Offers');
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to list offers',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Submit a new offer for a task.
  ///
  /// Includes rate limiting to prevent spam (2 second minimum between submits).
  /// Returns the created [TaskRequest] on success.
  ///
  /// Throws [Exception] with user-friendly message on error.
  Future<TaskRequest> submitOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    // Rate limiting check
    if (_isRateLimited()) {
      throw Exception('Please wait a moment before submitting another offer.');
    }

    AppLogger.d(
      'Submitting offer for task $taskId',
      tag: 'Offers',
      json: {
        'taskId': taskId,
        'price': price,
        'days': days,
        'hasNote': note != null && note.isNotEmpty,
      },
    );

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.e('Not authenticated', tag: 'Offers');
      throw Exception('Not authenticated');
    }

    try {
      // No active_role check required; any user can submit an offer.
      final insertData = <String, dynamic>{
        'task_id': taskId,
        'bidder_id': uid,
        'freelancer_id': uid, // Required for RLS
        'price': price,
        'days': days,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final inserted = await _client
          .from('task_requests')
          .insert(insertData)
          .select()
          .single();

      final model = TaskRequest.fromMap(inserted as Map<String, dynamic>);
      AppLogger.i('Offer submitted: ${model.id}', tag: 'Offers');

      return model;
    } on PostgrestException catch (e, st) {
      final userMessage = _mapSubmitOfferError(e);
      AppLogger.e(
        'Failed to submit offer: $userMessage',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(userMessage);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to submit offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Replace an existing offer with new values.
  ///
  /// Includes rate limiting to prevent spam (2 second minimum between submits).
  Future<TaskRequest> replaceOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    // Rate limiting check
    if (_isRateLimited()) {
      throw Exception('Please wait a moment before updating your offer.');
    }

    AppLogger.d(
      'Replacing offer for task $taskId',
      tag: 'Offers',
      json: {
        'taskId': taskId,
        'price': price,
        'days': days,
        'hasNote': note != null && note.isNotEmpty,
      },
    );

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.e('Not authenticated', tag: 'Offers');
      throw Exception('Not authenticated');
    }

    try {
      await _client.rpc(
        'replace_task_request',
        params: {
          'p_task_id': taskId,
          'p_freelancer_id': uid,
          'p_message': note ?? '',
          'p_price': price,
          'p_days': days,
        },
      );

      final model = await getExistingActiveOfferForCurrentUser(taskId);
      if (model == null) {
        throw Exception(
          'Offer was updated, but the refreshed offer could not be loaded.',
        );
      }
      AppLogger.i('Offer replaced: ${model.id}', tag: 'Offers');
      return model;
    } on PostgrestException catch (e, st) {
      final userMessage = _mapReplaceOfferError(e);
      AppLogger.e(
        'Failed to replace offer: $userMessage',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(userMessage);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to replace offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Accept an offer (task owner action).
  ///
  /// [expectedPriceCents] is the price (in cents) the client saw when clicking Accept.
  /// If the freelancer updated their offer since then, a [PriceMismatchException] is thrown.
  Future<TaskRequest> accept(
    String requestId, {
    String? taskId,
    int? expectedPriceCents,
  }) async {
    AppLogger.d(
      'Accepting offer $requestId${expectedPriceCents != null ? ' with expected price: $expectedPriceCents cents' : ''}',
      tag: 'Offers',
    );
    try {
      final resolvedTaskId = taskId ?? await _resolveTaskId(requestId);
      await _client.rpc(
        'accept_task_request',
        params: {
          'p_task_id': resolvedTaskId,
          'p_request_id': requestId,
          if (expectedPriceCents != null)
            'p_expected_price_cents': expectedPriceCents,
        },
      );
      final model = await _fetchRequestById(requestId);
      AppLogger.i('Offer accepted: ${model.id}', tag: 'Offers');

      return model;
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to accept offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw _mapAcceptError(e);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to accept offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(_mapDecisionError(e));
    }
  }

  /// Maps PostgrestException to typed exceptions for better error handling.
  Exception _mapAcceptError(PostgrestException e) {
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

      return PriceMismatchException(expectedCents: 0, actualCents: 0);
    }

    // Check for already accepted (idempotency hit)
    if (lowercaseMessage.contains('already_accepted')) {
      return OfferAlreadyAcceptedException();
    }

    // Fallback to generic error mapping
    return Exception(_mapDecisionError(e));
  }

  /// Reject an offer (task owner action).
  Future<TaskRequest> reject(String requestId, {String? taskId}) async {
    AppLogger.d('Rejecting offer $requestId', tag: 'Offers');
    try {
      final resolvedTaskId = taskId ?? await _resolveTaskId(requestId);
      await _client.rpc(
        'reject_task_request',
        params: {'p_task_id': resolvedTaskId, 'p_request_id': requestId},
      );
      final model = await _fetchRequestById(requestId);
      AppLogger.i('Offer rejected: ${model.id}', tag: 'Offers');

      return model;
    } on PostgrestException catch (e, st) {
      final userMessage = _mapRejectError(e);
      AppLogger.e(
        'Failed to reject offer: $userMessage',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(userMessage);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to reject offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(_mapDecisionError(e));
    }
  }

  Future<String> _resolveTaskId(String requestId) async {
    final row = await _client
        .from('task_requests')
        .select('task_id')
        .eq('id', requestId)
        .single();
    return row['task_id'] as String;
  }

  Future<TaskRequest> _fetchRequestById(String requestId) async {
    final row = await _client
        .from('task_requests')
        .select(_selectWithProfile)
        .eq('id', requestId)
        .single();
    return TaskRequest.fromMap(row as Map<String, dynamic>);
  }

  // ============================================================================
  // Comprehensive Error Mapping (from API_CONTRACT.md)
  // ============================================================================

  /// Maps submitOffer RPC/database errors to user-friendly messages.
  ///
  /// Error conditions from API_CONTRACT.md:
  /// - Duplicate pending offer (unique constraint violation)
  /// - RLS policy denial (task closed or user is owner)
  /// - Invalid input data
  String _mapSubmitOfferError(PostgrestException error) {
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
  String _mapReplaceOfferError(PostgrestException error) {
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
      return 'You don\'t have an active offer to update on this task.';
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
  String _mapRejectError(PostgrestException error) {
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
      return 'You don\'t have permission to reject this offer.';
    }

    // Fallback to generic decision error mapping
    return _mapDecisionError(error);
  }

  String _mapDecisionError(Object error) {
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

  /// Maps any RPC error to a user-friendly message.
  ///
  /// This is a public helper that can be used by ViewModels
  /// to get consistent error messages.
  String mapErrorToUserMessage(dynamic error) {
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
      return _mapSubmitOfferError(error);
    }

    // Generic fallback
    return 'An error occurred. Please try again.';
  }
}

/// Exception thrown when the offer price changed between viewing and accepting.
///
/// This is a security feature to prevent race conditions where a freelancer
/// updates their price milliseconds before the client clicks "Accept".
class PriceMismatchException implements Exception {
  /// The price (in cents) the client expected when clicking Accept.
  final int expectedCents;

  /// The actual current price (in cents) of the offer.
  final int actualCents;

  PriceMismatchException({
    required this.expectedCents,
    required this.actualCents,
  });

  @override
  String toString() =>
      'PriceMismatchException: expected $expectedCents cents, got $actualCents cents';

  /// Returns a user-friendly error message.
  String get userMessage {
    final expectedIqd = PriceFormatter.formatPrice(expectedCents / 100);
    final actualIqd = PriceFormatter.formatPrice(actualCents / 100);
    return 'The freelancer updated their offer from $expectedIqd to $actualIqd. Please review the new price before accepting.';
  }
}

/// Exception thrown when trying to accept an offer that was already accepted.
///
/// This can happen if the user double-clicks the Accept button or if
/// the offer was accepted on another device.
class OfferAlreadyAcceptedException implements Exception {
  OfferAlreadyAcceptedException();

  @override
  String toString() =>
      'OfferAlreadyAcceptedException: This offer has already been accepted';

  /// Returns a user-friendly message.
  String get userMessage => 'This offer has already been accepted.';
}
