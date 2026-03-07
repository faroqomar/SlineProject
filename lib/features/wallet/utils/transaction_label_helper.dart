import '../models/wallet_activity_model.dart';

/// Returns human-readable source (for received) or destination (for spent) from activity.
String getTransactionSourceOrDestination(WalletActivityModel a) {
  final et = a.eventType;
  final rt = a.relatedEntityType ?? '';

  switch (et) {
    case 'release_with_fee':
      switch (rt) {
        case 'booking':
          return 'Payment from booking';
        case 'direct_offer':
          return 'Payment from direct offer';
        case 'task_request':
          return 'Payment from task';
        default:
          return 'Payment received';
      }
    case 'refund':
      switch (rt) {
        case 'booking':
          return 'Refund from booking';
        case 'direct_offer':
          return 'Refund from direct offer';
        case 'task_request':
          return 'Refund from task';
        default:
          return 'Refund';
      }
    case 'deposit':
      return 'Deposit';
    case 'admin_credit':
      return 'Admin credit';
    case 'withdrawal_failed':
      return 'Withdrawal returned';
    case 'escrow_hold':
      switch (rt) {
        case 'booking':
          return 'Booking payment';
        case 'direct_offer':
          return 'Direct offer payment';
        case 'task_request':
          return 'Task payment';
        default:
          return 'Escrow payment';
      }
    case 'gateway_escrow':
      switch (rt) {
        case 'booking':
          return 'Booking payment';
        case 'direct_offer':
          return 'Direct offer payment';
        case 'task_request':
          return 'Tender payment';
        default:
          return 'Payment';
      }
    case 'withdrawal_request':
      return 'Withdrawal request';
    default:
      return et
          .split('_')
          .map((e) => e.isEmpty ? '' : '${e[0].toUpperCase()}${e.substring(1)}')
          .join(' ')
          .trim();
  }
}

/// Returns true if the event represents money received by the user.
bool isReceivedTransaction(WalletActivityModel a) {
  return [
    'release_with_fee',
    'refund',
    'deposit',
    'admin_credit',
    'withdrawal_failed',
  ].contains(a.eventType);
}
