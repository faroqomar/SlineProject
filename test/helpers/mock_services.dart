/// Shared mock service classes for ViewModel tests.
///
/// These mocks are used by multiple test files across the test suite.
/// Expanded in Phase E to cover all 27 ViewModels.
library;

import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/services/dashboard_cache_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/categories/data/categories_repository.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:sline_app/features/chat/services/message_service.dart';
import 'package:sline_app/features/dashboard/data/dashboard_repository.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/portfolio/data/portfolio_repository.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/safety/services/dispute_service.dart';
import 'package:sline_app/features/safety/services/report_service.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
import 'package:sline_app/features/search/services/search_service.dart';
import 'package:sline_app/features/services/data/services_repository.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/wallet/data/wallet_repository.dart';
import 'package:sline_app/features/work/services/work_management_service.dart';

// --- Existing mocks (Phase C/D) ---
class MockWalletRepository extends Mock implements WalletRepository {}

class MockAccountGuardService extends Mock implements AccountGuardService {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockDirectOffersService extends Mock implements DirectOffersService {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockDashboardCacheService extends Mock implements DashboardCacheService {}

class MockBookingService extends Mock implements BookingService {}

class MockTaskService extends Mock implements TaskService {}

class MockTaskRequestsService extends Mock implements TaskRequestsService {}

// --- Phase E additions ---
class MockAuthRepository extends Mock implements AuthRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockPortfolioRepository extends Mock implements PortfolioRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockMessageService extends Mock implements MessageService {}

class MockReportService extends Mock implements ReportService {}

class MockDisputeService extends Mock implements DisputeService {}

class MockSavedTasksService extends Mock implements SavedTasksService {}

class MockSearchService extends Mock implements SearchService {}

class MockServicesRepository extends Mock implements ServicesRepository {}

class MockWorkManagementService extends Mock implements WorkManagementService {}

class MockPaymentService extends Mock implements PaymentService {}
