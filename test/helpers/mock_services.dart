/// Shared mock service classes for ViewModel tests.
///
/// These mocks are used by multiple test files (WalletVM, ChatVM, DashboardVM).
/// VM-specific mocks (e.g., MockAuthRepository, MockTenderPaymentCoordinator)
/// should stay colocated in their respective test files.
library;

import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/wallet/data/wallet_repository.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/dashboard/data/dashboard_repository.dart';
import 'package:sline_app/core/services/dashboard_cache_service.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockAccountGuardService extends Mock implements AccountGuardService {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockDirectOffersService extends Mock implements DirectOffersService {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockDashboardCacheService extends Mock implements DashboardCacheService {}

class MockBookingService extends Mock implements BookingService {}

class MockTaskService extends Mock implements TaskService {}

class MockTaskRequestsService extends Mock implements TaskRequestsService {}
