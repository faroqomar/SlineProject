/// Unit tests for [WalletService] (getWalletBalance with mocked view).
///
/// Run: `flutter test test/unit/wallet/wallet_service_test.dart`
/// Observability: AppLogger is used by WalletService; tests do not assert on logs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/wallet/services/wallet_service.dart';

import '../../helpers/mock_supabase.dart';

const String _logTag = 'wallet_service_test';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(MockUser());
  });

  group('WalletService.getWalletBalance', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late WalletService service;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-123');
      service = WalletService(mockClient);
      AppLogger.d(
        'WalletService getWalletBalance tests starting',
        tag: _logTag,
      );
    });

    test('returns zero when currentUser is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final balance = await service.getWalletBalance();

      expect(balance.availableBalance, 0);
      expect(balance.heldBalance, 0);
      expect(balance.pendingWithdrawalBalance, 0);
      verifyNever(() => mockClient.from(any()));
      AppLogger.d('Zero balance when no user', tag: _logTag);
    });
  });
}
