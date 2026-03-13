import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import '../../../core/services/logger_service.dart';
import '../../chat/services/message_service.dart';
import '../../management/models/work_log_scope.dart';
import '../../management/services/work_log_service.dart';
import '../../wallet/services/ledger_service.dart';
import '../models/direct_offer_model.dart';

/// Service for direct offers (chat-to-work). Handles create, accept+pay, reject, deliver, complete.
class DirectOffersService {
  DirectOffersService(this._client)
    : _messageService = MessageService(_client),
      _ledgerService = LedgerService(_client),
      _workLogService = WorkLogService(_client);

  final SupabaseClient _client;
  final MessageService _messageService;
  final LedgerService _ledgerService;
  final WorkLogService _workLogService;

  String? get _uid => _client.auth.currentUser?.id;

  /// Create a direct offer and send an offer message in the conversation.
  /// Returns the created offer. Caller can add the returned message to the chat list.
  Future<DirectOffer> createOffer({
    required String conversationId,
    required String clientId,
    required String freelancerId,
    required String senderId,
    required String receiverId,
    String? taskId,
    String? title,
    String? description,
    required int price,
    required int days,
  }) async {
    final uid = _uid;
    if (uid == null || uid != freelancerId) {
      throw Exception('Only the freelancer can create an offer.');
    }

    final insertMap = <String, dynamic>{
      'conversation_id': conversationId,
      'client_id': clientId,
      'freelancer_id': freelancerId,
      'price': price,
      'days': days,
      'status': 'sent',
      'payment_status': 'unpaid',
    };
    if (taskId != null) insertMap['task_id'] = taskId;
    if (title != null && title.isNotEmpty) insertMap['title'] = title;
    if (description != null && description.isNotEmpty) {
      insertMap['description'] = description;
    }

    final response = await _client
        .from('direct_offers')
        .insert(insertMap)
        .select()
        .single();

    final offer = DirectOffer.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    AppLogger.i(
      '[DirectOffers] created offer=${offer.id} conversation=$conversationId',
    );

    final payload = <String, dynamic>{
      'offer_id': offer.id,
      'price': offer.price,
      'days': offer.days,
      'status': offer.status,
    };
    if (offer.title != null) payload['title'] = offer.title;
    if (offer.description != null) payload['description'] = offer.description;

    await _messageService.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: title?.isNotEmpty == true ? 'Offer: $title' : 'Offer',
      messageType: 'offer',
      payload: payload,
    );

    return offer;
  }

  Future<DirectOffer?> getOffer(String offerId) async {
    final response = await _client
        .from('direct_offers')
        .select()
        .eq('id', offerId)
        .maybeSingle();
    if (response == null) return null;
    return DirectOffer.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Batch fetch direct offers by IDs. Returns map of offerId -> DirectOffer.
  /// Used by ChatViewModel to refresh offer statuses without N+1 queries.
  Future<Map<String, DirectOffer>> getOffersByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final response = await _client
        .from('direct_offers')
        .select()
        .in_('id', ids);
    final list = response as List<dynamic>? ?? [];
    final map = <String, DirectOffer>{};
    for (final row in list) {
      final offer = DirectOffer.fromJson(Map<String, dynamic>.from(row as Map));
      map[offer.id] = offer;
    }
    return map;
  }

  /// Client accepts the offer (no payment). Work item appears in dashboard as Pending Payment.
  Future<void> acceptOfferWithoutPayment(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] acceptOfferWithoutPayment: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.clientId != _uid) {
      throw Exception('Only the client can accept this offer.');
    }
    if (!offer.isSent || offer.paymentStatus != 'unpaid') {
      throw Exception('Offer is not in a state that can be accepted.');
    }

    const defaultCurrency = 'IQD';
    await _client
        .from('direct_offers')
        .update({'status': 'accepted', 'currency': defaultCurrency})
        .eq('id', offerId);
    await _workLogService.logEvent(
      scope: WorkLogScope(entityId: offerId, entityType: 'direct_offer'),
      eventType: 'offer_accepted_waiting_payment',
      description: 'Offer accepted, waiting for payment',
    );
    AppLogger.i(
      '[DirectOffers] acceptOfferWithoutPayment completed offer=$offerId currency=$defaultCurrency',
    );
  }

  /// Client pays from dashboard (escrow hold). Call only when status is accepted and unpaid.
  Future<void> payNow(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] payNow: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.clientId != _uid) {
      throw Exception('Only the client can pay this offer.');
    }
    if (offer.status != 'accepted' || offer.paymentStatus != 'unpaid') {
      throw Exception('Offer must be accepted and unpaid to pay.');
    }

    await _ledgerService.submitPaymentEvent(
      eventType: 'escrow_hold',
      relatedEntityType: 'direct_offer',
      relatedEntityId: offerId,
      amountGross: offer.price,
      meta: {'client_id': offer.clientId, 'freelancer_id': offer.freelancerId},
    );

    await _workLogService.logEvent(
      scope: WorkLogScope(entityId: offerId, entityType: 'direct_offer'),
      eventType: 'offer_accepted',
      description: 'Offer paid & started',
    );
    AppLogger.i('[DirectOffers] payNow completed offer=$offerId');
  }

  /// After QiCard success callback: recover payment state so the offer is marked paid (when webhook didn't run or was delayed).
  Future<void> recoverPaymentAfterCallback(
    String offerId,
    String paymentRequestId,
  ) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] recoverPaymentAfterCallback: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.clientId != _uid) {
      throw Exception('Only the client can recover this offer.');
    }
    final response = await _client.functions.invoke(
      'qicard_payment_recovery_direct_offer',
      body: <String, dynamic>{
        'offer_id': offerId,
        'payment_request_id': paymentRequestId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['ok'] == true) {
        AppLogger.i(
          '[DirectOffers] recoverPaymentAfterCallback completed offer=$offerId',
          tag: 'DirectOffers',
          json: {'offerId': offerId, 'payment_request_id': paymentRequestId},
        );
        return;
      }
      final msg = data['message'] as String? ?? data['code'] as String?;
      if (msg != null) {
        AppLogger.e(
          '[DirectOffers] recoverPaymentAfterCallback failed offer=$offerId: $msg',
          tag: 'DirectOffers',
        );
        throw Exception(msg);
      }
    }
    AppLogger.i(
      '[DirectOffers] recoverPaymentAfterCallback completed offer=$offerId',
      tag: 'DirectOffers',
      json: {'offerId': offerId, 'payment_request_id': paymentRequestId},
    );
  }

  /// Client accepts and pays in one step (legacy / backward compat). Prefer acceptOfferWithoutPayment + payNow from dashboard.
  Future<void> acceptWithPayment(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) throw Exception('Offer not found.');
    if (offer.clientId != _uid) {
      throw Exception('Only the client can accept this offer.');
    }
    if (!offer.isSent || offer.paymentStatus != 'unpaid') {
      throw Exception('Offer is not in a state that can be accepted.');
    }

    await _ledgerService.submitPaymentEvent(
      eventType: 'escrow_hold',
      relatedEntityType: 'direct_offer',
      relatedEntityId: offerId,
      amountGross: offer.price,
      meta: {'client_id': offer.clientId, 'freelancer_id': offer.freelancerId},
    );

    await _workLogService.logEvent(
      scope: WorkLogScope(entityId: offerId, entityType: 'direct_offer'),
      eventType: 'offer_accepted',
      description: 'Offer accepted & started',
    );
    AppLogger.i('[DirectOffers] acceptWithPayment completed offer=$offerId');
  }

  /// Client cancels an accepted-but-unpaid offer (e.g. from details screen).
  Future<void> cancelAcceptedOffer(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] cancelAcceptedOffer: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.clientId != _uid) {
      throw Exception('Only the client can cancel this offer.');
    }
    if (offer.status != 'accepted' || offer.paymentStatus != 'unpaid') {
      throw Exception(
        'Only accepted, unpaid offers can be canceled by the client.',
      );
    }

    await _client
        .from('direct_offers')
        .update({'status': 'canceled'})
        .eq('id', offerId);
    AppLogger.i('[DirectOffers] client canceled accepted offer=$offerId');
  }

  /// Client rejects the offer.
  Future<void> rejectOffer(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] rejectOffer: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.clientId != _uid) {
      throw Exception('Only the client can reject this offer.');
    }
    if (!offer.isSent) {
      throw Exception('Offer cannot be rejected in its current state.');
    }

    await _client
        .from('direct_offers')
        .update({'status': 'rejected'})
        .eq('id', offerId);
    AppLogger.i('[DirectOffers] rejected offer=$offerId');
  }

  /// Freelancer cancels a sent offer.
  Future<void> cancelOffer(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] cancelOffer: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.freelancerId != _uid) {
      throw Exception('Only the freelancer can cancel this offer.');
    }
    if (!offer.isSent) {
      throw Exception('Offer cannot be canceled in its current state.');
    }

    await _client
        .from('direct_offers')
        .update({'status': 'canceled'})
        .eq('id', offerId);
    AppLogger.i('[DirectOffers] canceled offer=$offerId');
  }

  /// Freelancer marks work as delivered. Sets delivered_at and review_expires_at (3 days) for cron auto-release.
  Future<void> markDelivered(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] markDelivered: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.freelancerId != _uid) {
      throw Exception('Only the freelancer can mark delivered.');
    }
    if (!offer.isActive) {
      throw Exception('Offer must be active to mark delivered.');
    }

    final now = DateTime.now().toUtc();
    final reviewExpiresAt = now.add(const Duration(days: 3));
    await _client
        .from('direct_offers')
        .update({
          'status': 'delivered',
          'delivered_at': now.toIso8601String(),
          'review_expires_at': reviewExpiresAt.toIso8601String(),
        })
        .eq('id', offerId);
    await _workLogService.logEvent(
      scope: WorkLogScope(entityId: offerId, entityType: 'direct_offer'),
      eventType: 'delivery_submitted',
      description: 'Work delivered',
    );
    AppLogger.i(
      '[DirectOffers] marked delivered offer=$offerId delivered_at=${now.toIso8601String()} review_expires_at=${reviewExpiresAt.toIso8601String()}',
    );
  }

  /// Client approves and releases payment via rpc_approve_delivery (single exit point for escrow release).
  Future<void> completeOffer(String offerId) async {
    final offer = await getOffer(offerId);
    if (offer == null) {
      AppLogger.w(
        '[DirectOffers] completeOffer: offer not found',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Offer not found.');
    }
    if (offer.clientId != _uid) {
      AppLogger.w(
        'completeOffer: not client',
        tag: 'DirectOffers',
        json: {'offerId': offerId},
      );
      throw Exception('Only the client can complete this offer.');
    }
    if (!offer.isDelivered || offer.paymentStatus != 'held') {
      AppLogger.w(
        'completeOffer: invalid state',
        tag: 'DirectOffers',
        json: {
          'offerId': offerId,
          'delivered': offer.isDelivered,
          'paymentStatus': offer.paymentStatus,
        },
      );
      throw Exception('Offer must be delivered and payment held to complete.');
    }

    AppLogger.i(
      'Completing direct offer (approve delivery)',
      tag: 'DirectOffers',
      json: {'offerId': offerId},
    );
    try {
      await _client.rpc(
        'rpc_approve_delivery',
        params: {'entity_type': 'direct_offer', 'entity_id': offerId},
      );
    } on PostgrestException catch (e, st) {
      final friendly = ErrorMapper.map(e);
      AppLogger.e(
        'completeOffer failed offerId=$offerId',
        tag: 'DirectOffers',
        error: e,
        stackTrace: st,
        json: {'mappedMessage': friendly},
      );
      throw Exception(friendly);
    } catch (e, st) {
      final friendly = ErrorMapper.map(e);
      AppLogger.e(
        'completeOffer failed offerId=$offerId',
        tag: 'DirectOffers',
        error: e,
        stackTrace: st,
        json: {'mappedMessage': friendly},
      );
      throw Exception(friendly);
    }

    await _workLogService.logEvent(
      scope: WorkLogScope(entityId: offerId, entityType: 'direct_offer'),
      eventType: 'completed',
      description: 'Completed',
    );
    AppLogger.i(
      'Direct offer completed',
      tag: 'DirectOffers',
      json: {'offerId': offerId},
    );
  }
}
