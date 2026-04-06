/// Shared mock ViewModel classes for widget tests.
///
/// Type A screens mock the ViewModel directly.
/// Type B screens mock the services the ViewModel depends on.
///
/// Pattern: `Mock with ChangeNotifier implements VM` for ChangeNotifier VMs.
/// PaymentPendingStore is NOT a ChangeNotifier — use plain `Mock implements`.
library;

import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/direct_offers/viewmodels/direct_offer_details_view_model.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/requests_filter_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/submit_request_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';

// --- ChangeNotifier ViewModels (Type A / widget test mocks) ---

class MockBookingViewModel extends Mock
    with ChangeNotifier
    implements BookingViewModel {}

class MockTaskRequestsViewModel extends Mock
    with ChangeNotifier
    implements TaskRequestsViewModel {}

class MockSubmitRequestViewModel extends Mock
    with ChangeNotifier
    implements SubmitRequestViewModel {}

class MockWorkItemDetailsViewModel extends Mock
    with ChangeNotifier
    implements WorkItemDetailsViewModel {}

class MockDirectOfferDetailsViewModel extends Mock
    with ChangeNotifier
    implements DirectOfferDetailsViewModel {}

class MockTaskViewModel extends Mock
    with ChangeNotifier
    implements TaskViewModel {}

class MockRequestsFilterViewModel extends Mock
    with ChangeNotifier
    implements RequestsFilterViewModel {}

class MockAuthSessionViewModel extends Mock
    with ChangeNotifier
    implements AuthSessionViewModel {}

class MockFavoritesViewModel extends Mock
    with ChangeNotifier
    implements FavoritesViewModel {}

class MockChatViewModel extends Mock
    with ChangeNotifier
    implements ChatViewModel {}

class MockDashboardViewModel extends Mock
    with ChangeNotifier
    implements DashboardViewModel {}

class MockSafetyViewModel extends Mock
    with ChangeNotifier
    implements SafetyViewModel {}

// --- Plain classes (NO ChangeNotifier mixin) ---

class MockPaymentPendingStore extends Mock implements PaymentPendingStore {}

class MockDeepLinkService extends Mock implements DeepLinkService {}
