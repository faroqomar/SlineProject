import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_request_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final TaskRequestErrorMapper _errorMapper;

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

  TaskRequestsService({
    SupabaseClient? client,
    TaskRequestErrorMapper errorMapper = const TaskRequestErrorMapper(),
  }) : _client = client ?? Supabase.instance.client,
       _errorMapper = errorMapper;

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
          .isFilter('deleted_at', null)
          .eq('status', 'pending')
          .limit(1);
      if (rows.isEmpty) return null;
      return TaskRequest.fromMap(rows.first);
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
          .isFilter('deleted_at', null)
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
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        AppLogger.d('No existing bid found for task $taskId', tag: 'Offers');
        return BidReplaceabilityResult.noExistingBid();
      }

      final existingBid = TaskRequest.fromMap(rows.first);

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
          .isFilter('deleted_at', null);

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

      final model = TaskRequest.fromMap(inserted);
      AppLogger.i('Offer submitted: ${model.id}', tag: 'Offers');

      return model;
    } on PostgrestException catch (e, st) {
      final userMessage = _errorMapper.mapSubmitOfferError(e);
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
      await _client.rpc<dynamic>(
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
      final userMessage = _errorMapper.mapReplaceOfferError(e);
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
      await _client.rpc<dynamic>(
        'accept_task_request',
        params: {
          'p_task_id': resolvedTaskId,
          'p_request_id': requestId,
          'p_expected_price_cents': ?expectedPriceCents,
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
      throw _errorMapper.mapAcceptError(e);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to accept offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(_errorMapper.mapDecisionError(e));
    }
  }

  /// Reject an offer (task owner action).
  Future<TaskRequest> reject(String requestId, {String? taskId}) async {
    AppLogger.d('Rejecting offer $requestId', tag: 'Offers');
    try {
      final resolvedTaskId = taskId ?? await _resolveTaskId(requestId);
      await _client.rpc<dynamic>(
        'reject_task_request',
        params: {'p_task_id': resolvedTaskId, 'p_request_id': requestId},
      );
      final model = await _fetchRequestById(requestId);
      AppLogger.i('Offer rejected: ${model.id}', tag: 'Offers');

      return model;
    } on PostgrestException catch (e, st) {
      final userMessage = _errorMapper.mapRejectError(e);
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
      throw Exception(_errorMapper.mapDecisionError(e));
    }
  }

  Future<String> _resolveTaskId(String requestId) async {
    final row = await _client
        .from('task_requests')
        .select('task_id')
        .eq('id', requestId)
        .isFilter('deleted_at', null)
        .single();
    return row['task_id'] as String;
  }

  Future<TaskRequest> _fetchRequestById(String requestId) async {
    final row = await _client
        .from('task_requests')
        .select(_selectWithProfile)
        .eq('id', requestId)
        .single();
    return TaskRequest.fromMap(row);
  }

  /// Maps any RPC error to a user-friendly message.
  ///
  /// This is a public helper that can be used by ViewModels
  /// to get consistent error messages. Delegates to [TaskRequestErrorMapper].
  String mapErrorToUserMessage(dynamic error) =>
      _errorMapper.mapErrorToUserMessage(error);
}
