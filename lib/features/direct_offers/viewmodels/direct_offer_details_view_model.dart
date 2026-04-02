import 'package:flutter/foundation.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import '../models/direct_offer_model.dart';
import '../services/direct_offers_service.dart';

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

  static const _kTag = 'DirectOfferDetails';

  DirectOffer? _offer;
  bool _isLoading = true;
  String? _error;
  bool _payInProgress = false;
  bool _cancelInProgress = false;
  bool _cardPaymentInProgress = false;
  bool _markDeliveredInProgress = false;
  bool _completeInProgress = false;

  DirectOffer? get offer => _offer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get payInProgress => _payInProgress;
  bool get cancelInProgress => _cancelInProgress;
  bool get cardPaymentInProgress => _cardPaymentInProgress;
  bool get markDeliveredInProgress => _markDeliveredInProgress;
  bool get completeInProgress => _completeInProgress;

  bool get canPay =>
      currentUserId != null &&
      _offer != null &&
      _offer!.clientId == currentUserId &&
      _offer!.isAcceptedPendingPayment;
  bool get canCancel =>
      currentUserId != null &&
      _offer != null &&
      _offer!.clientId == currentUserId &&
      _offer!.isAcceptedPendingPayment;

  /// Freelancer can mark work as delivered when offer is active.
  bool get canMarkDelivered =>
      currentUserId != null &&
      _offer != null &&
      _offer!.freelancerId == currentUserId &&
      _offer!.isActive;

  /// Client can approve delivery and release payment when offer is delivered and payment is held.
  bool get canComplete =>
      currentUserId != null &&
      _offer != null &&
      _offer!.clientId == currentUserId &&
      _offer!.isDelivered &&
      _offer!.paymentStatus == 'held';

  /// Conversation ID from constructor or from loaded offer (e.g. when opened via activity deep link).
  String? get effectiveConversationId =>
      conversationId ?? _offer?.conversationId;
  bool get canOpenChat => effectiveConversationId != null;

  Future<void> loadOffer() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _offer = await _directOffersService.getOffer(offerId);
      _error = _offer == null ? 'Offer not found.' : null;
    } on Exception catch (e) {
      AppLogger.e('Failed to load offer=$offerId', error: e, tag: _kTag);
      _error = e.toString();
    } finally {
      _isLoading = false;
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
    if (_offer == null || !canPay || _cardPaymentInProgress) {
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
        amount: _offer!.price.toDouble(),
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
