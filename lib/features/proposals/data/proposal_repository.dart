// Proposal data access: list, submit, replace, reject.
// Uses get_proposal_bidder_summaries for owner list (RLS-safe); no direct profiles join.
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/proposals/models/proposal_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Proposal repository: typed proposal list and mutations.
/// Delegates submit/replace/reject to [TaskRequestsService] for compatibility;
/// owner list uses get_proposal_bidder_summaries to avoid direct profiles join.
class ProposalRepository {
  ProposalRepository({
    SupabaseClient? client,
    required TaskRequestsService taskRequestsService,
  }) : _client = client ?? Supabase.instance.client,
       _taskRequestsService = taskRequestsService;

  final SupabaseClient _client;
  final TaskRequestsService _taskRequestsService;

  /// List proposals for a task. For owner view, enriches with bidder names via RPC.
  // ignore: deprecated_member_use_from_same_package
  Future<List<ProposalModel>> listByTask({
    required String taskId,
    int limit = 20,
    DateTime? before,
    bool isOwner = false,
  }) async {
    AppLogger.d('Proposals: listByTask $taskId', tag: 'Proposals');
    try {
      var query = _client
          .from('task_requests')
          .select(
            'id, task_id, bidder_id, freelancer_id, price, days, note, message, status, payment_status, created_at, updated_at, payment_deadline, tasks(title)',
          )
          .eq('task_id', taskId)
          .is_('deleted_at', null);

      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }

      final data =
          await query.order('created_at', ascending: false).limit(limit)
              as List<dynamic>;

      if (data.isEmpty) {
        return [];
      }

      Map<String, Map<String, dynamic>>? bidderSummaries;
      if (isOwner) {
        try {
          final summaries =
              await _client.rpc(
                    'get_proposal_bidder_summaries',
                    params: {'p_task_id': taskId},
                  )
                  as List<dynamic>?;
          if (summaries != null && summaries.isNotEmpty) {
            bidderSummaries = {
              for (final s in summaries)
                (s['id'] as String? ?? ''): s as Map<String, dynamic>,
            };
          }
        } on Object catch (e, _) {
          AppLogger.w(
            'Proposals: get_proposal_bidder_summaries failed, list without names',
            tag: 'Proposals',
            error: e,
          );
        }
      }

      // ignore: deprecated_member_use_from_same_package
      final list = <ProposalModel>[];
      for (final row in data) {
        final map = Map<String, dynamic>.from(row as Map);
        final bidderId =
            map['freelancer_id'] as String? ?? map['bidder_id'] as String?;
        String? bidderName;
        String? bidderAvatar;
        if (bidderId != null && bidderSummaries != null) {
          final p = bidderSummaries[bidderId];
          if (p != null) {
            bidderName = p['full_name'] as String?;
            bidderAvatar = p['avatar_url'] as String?;
          }
        }
        final taskData = map['tasks'] as Map<String, dynamic>?;
        final taskTitle = taskData?['title'] as String?;
        list.add(
          _rowToProposal(
            map,
            bidderName: bidderName,
            bidderAvatar: bidderAvatar,
            taskTitle: taskTitle,
          ),
        );
      }

      AppLogger.i(
        'Proposals: loaded ${list.length} for task $taskId',
        tag: 'Proposals',
      );
      return list;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: listByTask failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ignore: deprecated_member_use_from_same_package
  static ProposalModel _rowToProposal(
    Map<String, dynamic> map, {
    String? bidderName,
    String? bidderAvatar,
    String? taskTitle,
  }) {
    final status = map['status'] as String? ?? 'unknown';
    final paymentStatus = map['payment_status'] as String? ?? 'unpaid';
    // ignore: deprecated_member_use_from_same_package
    return ProposalModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      bidderId:
          (map['freelancer_id'] as String?) ??
          (map['bidder_id'] as String?) ??
          '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      days: (map['days'] as int?) ?? (map['duration_days'] as int?) ?? 0,
      note: (map['note'] ?? map['message']) as String?,
      status: OfferStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OfferStatus.unknown,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == paymentStatus,
        orElse: () => PaymentStatus.unpaid,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      bidderName: bidderName,
      bidderAvatar: bidderAvatar,
      taskTitle: taskTitle,
      paymentDeadline: map['payment_deadline'] != null
          ? DateTime.tryParse(map['payment_deadline'] as String)
          : null,
    );
  }

  Future<TaskRequest> submitOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    AppLogger.i('Proposals: submitOffer task=$taskId', tag: 'Proposals');
    return _taskRequestsService.submitOffer(
      taskId: taskId,
      price: price,
      days: days,
      note: note,
    );
  }

  Future<TaskRequest> replaceOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    AppLogger.i('Proposals: replaceOffer task=$taskId', tag: 'Proposals');
    return _taskRequestsService.replaceOffer(
      taskId: taskId,
      price: price,
      days: days,
      note: note,
    );
  }

  Future<TaskRequest> reject(String requestId, {String? taskId}) async {
    AppLogger.i('Proposals: reject request=$requestId', tag: 'Proposals');
    return _taskRequestsService.reject(requestId, taskId: taskId);
  }
}
