import 'package:flutter/foundation.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/models/app_failure.dart';
import 'package:sline_app/core/models/view_state.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';

/// ViewModel for the direct offer details screen (client: view, pay, cancel, complete; freelancer: mark delivered; open chat).
class DirectOfferDetailsViewModel extends ChangeNotifier {
  DirectOfferDetailsViewModel({
    required this.offerId,
    this.conversationId,
    this.currentUserId,
    required DirectOffersService directOffersService,
    required PaymentService paymentService,
  }) : _directOffersService = directOffersService,
       _paymentService = paymentService;

  final String offerId;
  final String? conversationId;

  /// Current logged-in user id; used to show role-specific actions (pay/cancel vs mark delivered/complete).
  final String? currentUserId;
  final DirectOffersService _directOffersService;
  final PaymentService _paymentService;

  static const _kTag = 'DirectOfferDetailsVM';

  // ── Primary state ──────────────────────────────────────────────────
  ViewState<DirectOffer> _state = const ViewLoading();
  ViewState<DirectOffer> get state => _state;

  // ── Action-specific progress flags ─────────────────────────────────
  bool _payInProgress = false;
  bool _cancelInProgress = false;
  bool _cardPaymentInProgress = false;
  bool _markDeliveredInProgress = false;
  bool _completeInProgress = false;

  // ── Backward-compatible convenience getters (used by view) ─────────
  bool get isLoading =>
      _state is ViewLoading<DirectOffer> || _state is ViewInitial<DirectOffer>;
  String? get error => switch (_state) {
    ViewFailed(:final failure) => failure.userMessage,
    _ => null,
  };
  DirectOffer? get offer => switch (_state) {
    ViewLoaded(:final data) => data,
    _ => null,
  };

  bool get payInProgress => _payInProgress;
  bool get cancelInProgress => _cancelInProgress;
  bool get cardPaymentInProgress => _cardPaymentInProgress;
  bool get markDeliveredInProgress => _markDeliveredInProgress;
  bool get completeInProgress => _completeInProgress;

  bool get canPay =>
      currentUserId != null &&
      offer != null &&
      offer!.clientId == currentUserId &&
      offer!.isAcceptedPendingPayment;
  bool get canCancel =>
      currentUserId != null &&
      offer != null &&
      offer!.clientId == currentUserId &&
      offer!.isAcceptedPendingPayment;

  /// Freelancer can mark work as delivered when offer is active.
  bool get canMarkDelivered =>
      currentUserId != null &&
      offer != null &&
      offer!.freelancerId == currentUserId &&
      offer!.isActive;

  /// Client can approve delivery and release payment when offer is delivered and payment is held.
  bool get canComplete =>
      currentUserId != null &&
      offer != null &&
      offer!.clientId == currentUserId &&
      offer!.isDelivered &&
      offer!.paymentStatus == 'held';

  /// Conversation ID from constructor or from loaded offer (e.g. when opened via activity deep link).
  String? get effectiveConversationId =>
      conversationId ?? offer?.conversationId;
  bool get canOpenChat => effectiveConversationId != null;

  Future<void> loadOffer() async {
    _state = const ViewLoading();
    AppLogger.d('State: $_state', tag: _kTag);
    notifyListeners();

    try {
      final loaded = await _directOffersService.getOffer(offerId);
      if (loaded == null) {
        _state = const ViewFailed(
          BusinessFailure('Offer not found.', code: 'OFFER_NOT_FOUND'),
        );
      } else {
        _state = ViewLoaded(loaded);
      }
    } on Exception catch (e) {
      AppLogger.e('Failed to load offer=$offerId', error: e, tag: _kTag);
      _state = ViewFailed(
        BusinessFailure(
          ErrorMapper.map(e),
          code: 'LOAD_FAILED',
          debugMessage: '$e',
        ),
      );
    } finally {
      AppLogger.d('State: $_state', tag: _kTag);
      notifyListeners();
    }
  }

  /// Pay with wallet (escrow hold). Call only when [canPay].
  Future<void> payNow() async {
    if (!canPay || _payInProgress) return;
    _payInProgress = true;
    notifyListeners();

    try {
      await _directOffersService.payNow(offerId);
      await loadOffer();
    } on Exception catch (e) {
      AppLogger.e('payNow failed offer=$offerId', error: e, tag: _kTag);
      rethrow;
    } finally {
      _payInProgress = false;
      notifyListeners();
    }
  }

  /// Cancel accepted-but-unpaid offer. Call only when [canCancel].
  Future<void> cancelOffer() async {
    if (!canCancel || _cancelInProgress) return;
    _cancelInProgress = true;
    notifyListeners();

    try {
      await _directOffersService.cancelAcceptedOffer(offerId);
      await loadOffer();
    } on Exception catch (e) {
      AppLogger.e('cancelOffer failed offer=$offerId', error: e, tag: _kTag);
      rethrow;
    } finally {
      _cancelInProgress = false;
      notifyListeners();
    }
  }

  /// After QiCard success redirect: recover payment so the offer is marked paid (when webhook didn't run).
  Future<void> recoverPaymentAfterCallback(String paymentRequestId) async {
    await _directOffersService.recoverPaymentAfterCallback(
      offerId,
      paymentRequestId,
    );
    await loadOffer();
  }

  /// Freelancer marks work as delivered. Call only when [canMarkDelivered].
  Future<void> markDelivered() async {
    if (!canMarkDelivered || _markDeliveredInProgress) return;
    _markDeliveredInProgress = true;
    notifyListeners();

    try {
      await _directOffersService.markDelivered(offerId);
      await loadOffer();
    } on Exception catch (e) {
      AppLogger.e('markDelivered failed offer=$offerId', error: e, tag: _kTag);
      rethrow;
    } finally {
      _markDeliveredInProgress = false;
      notifyListeners();
    }
  }

  /// Client approves delivery and releases payment. Call only when [canComplete].
  Future<void> completeOffer() async {
    if (!canComplete || _completeInProgress) return;
    _completeInProgress = true;
    notifyListeners();

    try {
      await _directOffersService.completeOffer(offerId);
      await loadOffer();
    } on Exception catch (e) {
      AppLogger.e('completeOffer failed offer=$offerId', error: e, tag: _kTag);
      rethrow;
    } finally {
      _completeInProgress = false;
      notifyListeners();
    }
  }

  /// Create QiCard payment for this offer. Returns result with [formUrl] when successful.
  Future<QiCardDirectOfferPaymentResult> createPaymentForCard() async {
    final currentOffer = offer;
    if (currentOffer == null || !canPay || _cardPaymentInProgress) {
      return QiCardDirectOfferPaymentResult(
        offerId: offerId,
        error: 'Offer not ready for payment.',
        errorCode: 'INVALID_STATE',
      );
    }
    _cardPaymentInProgress = true;
    notifyListeners();

    try {
      final finishUrl = buildQiCardFinishUrlForRuntime();
      final result = await _paymentService.createPaymentForDirectOffer(
        offerId: offerId,
        amount: currentOffer.price.toDouble(),
        finishUrl: finishUrl,
      );
      return result;
    } finally {
      _cardPaymentInProgress = false;
      notifyListeners();
    }
  }

  /// Stream payment_intents.status for realtime resolution (e.g. in PaymentWebViewScreen).
  Stream<String> streamPaymentIntentStatus(String intentId) =>
      _paymentService.streamPaymentIntentStatus(intentId);
}
