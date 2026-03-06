/// Helper utilities for testing role switching functionality
///
/// Provides mocks and helpers for testing the RoleSwitchCoordinator pattern,
/// ViewModel teardown, and complete role switch flows.
///
/// This file provides a mock coordinator implementation and testing utilities
/// that can be used without depending on the actual implementation classes.
///
/// Usage:
/// ```dart
/// import '../helpers/role_switch_helpers.dart';
///
/// void main() {
///   late RoleSwitchCoordinatorMock coordinator;
///
///   setUp(() {
///     coordinator = RoleSwitchCoordinatorMock();
///   });
/// }
/// ```
library;

import 'package:sline_app/core/services/logger_service.dart';

/// Log tag for role switch helper operations
const String _logTag = 'test_fixture';

/// Mixin interface for ViewModels that are role-switch aware
///
/// This mirrors the actual [RoleSwitchAware] mixin that ViewModels implement
abstract class RoleSwitchAware {
  /// Called by the coordinator during role switch to clear cached data
  Future<void> teardownForRoleSwitch();
}

/// Mock implementation of [RoleSwitchAware] for testing
class MockRoleSwitchAware implements RoleSwitchAware {
  bool _wasTeardownCalled = false;
  Exception? _teardownError;

  /// Whether teardownForRoleSwitch was called
  bool get wasTeardownCalled => _wasTeardownCalled;

  /// Set an error to throw when teardown is called
  set teardownError(Exception? error) {
    _teardownError = error;
  }

  /// Reset the mock state for reuse across tests
  void reset() {
    _wasTeardownCalled = false;
    _teardownError = null;
  }

  @override
  Future<void> teardownForRoleSwitch() async {
    _wasTeardownCalled = true;
    AppLogger.d(
      'MockRoleSwitchAware.teardownForRoleSwitch called',
      tag: _logTag,
    );
    if (_teardownError != null) {
      throw _teardownError!;
    }
  }
}

/// Exception thrown when one or more ViewModel teardowns fail
class RoleSwitchTeardownException implements Exception {
  /// List of error messages from failed teardowns
  final List<String> errors;

  RoleSwitchTeardownException(this.errors);

  @override
  String toString() {
    return 'RoleSwitchTeardownException: ${errors.length} ViewModel(s) failed teardown: ${errors.join(', ')}';
  }
}

/// Mock implementation of RoleSwitchCoordinator for testing
///
/// The coordinator manages registration and teardown of ViewModels during role switch.
/// This is a concrete implementation suitable for testing without requiring
/// the actual implementation from the app code.
class RoleSwitchCoordinatorMock {
  final List<RoleSwitchAware> _registeredViewModels = [];
  bool _wasTeardownCalled = false;
  final List<String> _teardownErrors = [];

  /// Whether teardownAll was called
  bool get wasTeardownCalled => _wasTeardownCalled;

  /// List of registered ViewModels
  List<RoleSwitchAware> get registeredViewModels => List.unmodifiable(_registeredViewModels);

  /// List of errors that occurred during teardown
  List<String> get teardownErrors => List.unmodifiable(_teardownErrors);

  /// Factory constructor with default configuration
  RoleSwitchCoordinatorMock() {
    AppLogger.d('Creating RoleSwitchCoordinatorMock', tag: _logTag);
  }

  /// Register a ViewModel with the coordinator
  void register(RoleSwitchAware viewModel) {
    AppLogger.d(
      'Registering ViewModel: ${viewModel.runtimeType}',
      tag: _logTag,
    );
    if (!_registeredViewModels.contains(viewModel)) {
      _registeredViewModels.add(viewModel);
    }
  }

  /// Unregister a ViewModel from the coordinator
  void unregister(RoleSwitchAware viewModel) {
    AppLogger.d(
      'Unregistering ViewModel: ${viewModel.runtimeType}',
      tag: _logTag,
    );
    _registeredViewModels.remove(viewModel);
  }

  /// Execute teardown on all registered ViewModels
  Future<void> teardownAll() async {
    AppLogger.d(
      'TeardownAll called for ${_registeredViewModels.length} ViewModels',
      tag: _logTag,
    );
    _wasTeardownCalled = true;
    _teardownErrors.clear();

    final errors = <String>[];

    for (final vm in _registeredViewModels) {
      try {
        await vm.teardownForRoleSwitch();
        AppLogger.d(
          'Teardown succeeded for ${vm.runtimeType}',
          tag: _logTag,
        );
      } catch (e) {
        final errorMsg = '${vm.runtimeType}: $e';
        errors.add(errorMsg);
        _teardownErrors.add(errorMsg);
        AppLogger.e(
          'Teardown failed for ${vm.runtimeType}',
          tag: _logTag,
          error: e,
        );
      }
    }

    if (errors.isNotEmpty) {
      throw RoleSwitchTeardownException(errors);
    }

    AppLogger.i(
      'TeardownAll completed successfully',
      tag: _logTag,
    );
  }

  /// Reset the coordinator state for reuse across tests
  void reset() {
    AppLogger.d('Resetting RoleSwitchCoordinatorMock', tag: _logTag);
    _registeredViewModels.clear();
    _wasTeardownCalled = false;
    _teardownErrors.clear();
  }

  /// Returns true if there are registered ViewModels
  bool get hasRegistrations => _registeredViewModels.isNotEmpty;
}

/// Helper to create a list of mock ViewModels for testing
///
/// [count] - Number of ViewModels to create
List<MockRoleSwitchAware> createMockViewModels(int count) {
  AppLogger.d('Creating $count mock ViewModels', tag: _logTag);
  return List.generate(
    count,
    (index) => MockRoleSwitchAware(),
  );
}

/// Helper to create a realistic test scenario with multiple ViewModels
///
/// Creates mock ViewModels representing: Chat, Dashboard, Tasks, Home, Wallet
List<MockRoleSwitchAware> createStandardViewModelSet() {
  AppLogger.d('Creating standard ViewModel set', tag: _logTag);
  return [
    MockRoleSwitchAware(), // Represents ChatViewModel
    MockRoleSwitchAware(), // Represents DashboardViewModel
    MockRoleSwitchAware(), // Represents TaskViewModel
    MockRoleSwitchAware(), // Represents HomeViewModel
    MockRoleSwitchAware(), // Represents WalletViewModel
  ];
}

/// Verify that all ViewModels in the list had teardown called
bool verifyAllTeardownsCalled(List<MockRoleSwitchAware> viewModels) {
  AppLogger.d(
    'Verifying teardown called for ${viewModels.length} ViewModels',
    tag: _logTag,
  );
  return viewModels.every((vm) => vm.wasTeardownCalled);
}

/// Verify that no ViewModels in the list had teardown called
bool verifyNoTeardownsCalled(List<MockRoleSwitchAware> viewModels) {
  AppLogger.d(
    'Verifying no teardown called for ${viewModels.length} ViewModels',
    tag: _logTag,
  );
  return viewModels.every((vm) => !vm.wasTeardownCalled);
}

/// Extension to make it easier to verify ViewModel teardown state
extension ViewModelTeardownVerification on List<MockRoleSwitchAware> {
  /// Returns true if all ViewModels had teardown called
  bool get allTeardownsCalled => verifyAllTeardownsCalled(this);

  /// Returns true if no ViewModels had teardown called
  bool get noTeardownsCalled => verifyNoTeardownsCalled(this);

  /// Returns count of ViewModels that had teardown called
  int get teardownCallCount => where((vm) => vm.wasTeardownCalled).length;
}

/// Result of a role switch teardown operation
class RoleSwitchTeardownResult {
  /// Whether the teardown was successful
  final bool success;

  /// Error messages if teardown failed
  final List<String> errors;

  RoleSwitchTeardownResult._({required this.success, this.errors = const []});

  /// Create a success result
  factory RoleSwitchTeardownResult.success() {
    return RoleSwitchTeardownResult._(success: true);
  }

  /// Create a failure result with the given errors
  factory RoleSwitchTeardownResult.failure(List<String> errors) {
    return RoleSwitchTeardownResult._(success: false, errors: errors);
  }
}

/// Helper to simulate a complete role switch in tests
///
/// This orchestrates the full flow: RPC call → session refresh → teardown
class RoleSwitchSimulator {
  final RoleSwitchCoordinatorMock _coordinator;
  final List<MockRoleSwitchAware> _viewModels;

  /// Creates a simulator with the given coordinator and ViewModels
  RoleSwitchSimulator({
    RoleSwitchCoordinatorMock? coordinator,
    List<MockRoleSwitchAware>? viewModels,
  })  : _coordinator = coordinator ?? RoleSwitchCoordinatorMock(),
        _viewModels = viewModels ?? [] {
    AppLogger.d(
      'Creating RoleSwitchSimulator with ${_viewModels.length} ViewModels',
      tag: _logTag,
    );
  }

  /// Register all ViewModels with the coordinator
  void registerAll() {
    AppLogger.d('Registering all ViewModels with coordinator', tag: _logTag);
    for (final vm in _viewModels) {
      _coordinator.register(vm);
    }
  }

  /// Get the coordinator for direct access in tests
  RoleSwitchCoordinatorMock get coordinator => _coordinator;

  /// Get the registered ViewModels
  List<MockRoleSwitchAware> get viewModels => List.unmodifiable(_viewModels);

  /// Simulate a successful role switch flow
  ///
  /// Returns true if the switch was successful, false otherwise
  Future<bool> simulateSuccessfulSwitch({
    required String fromRole,
    required String toRole,
    required Future<bool> Function() rpcCall,
    required Future<void> Function() sessionRefresh,
    required Future<bool> Function() verifyJwtRole,
  }) async {
    AppLogger.i(
      'Simulating role switch: $fromRole -> $toRole',
      tag: _logTag,
    );

    try {
      // Step 1: Call RPC
      AppLogger.d('Step 1: Calling RPC', tag: _logTag);
      final rpcSuccess = await rpcCall();
      if (!rpcSuccess) {
        AppLogger.w('RPC call failed', tag: _logTag);
        return false;
      }

      // Step 2: Refresh session
      AppLogger.d('Step 2: Refreshing session', tag: _logTag);
      await sessionRefresh();

      // Step 3: Verify JWT role
      AppLogger.d('Step 3: Verifying JWT role', tag: _logTag);
      final jwtValid = await verifyJwtRole();
      if (!jwtValid) {
        AppLogger.w('JWT role verification failed', tag: _logTag);
        return false;
      }

      // Step 4: Teardown ViewModels
      AppLogger.d('Step 4: Executing teardown', tag: _logTag);
      await _coordinator.teardownAll();

      AppLogger.i('Role switch simulation completed successfully', tag: _logTag);
      return true;
    } catch (e) {
      AppLogger.e(
        'Role switch simulation failed',
        tag: _logTag,
        error: e,
      );
      return false;
    }
  }

  /// Simulate a role switch that fails due to stale state
  ///
  /// This simulates when the user tries to switch from a role that has
  /// already been changed on another device
  Future<bool> simulateStaleStateSwitch() async {
    AppLogger.w(
      'Simulating stale state role switch',
      tag: _logTag,
    );
    return false;
  }

  /// Simulate a role switch that fails during teardown
  ///
  /// This simulates when ViewModel cleanup fails, requiring recovery
  Future<RoleSwitchTeardownResult> simulateTeardownFailure() async {
    AppLogger.w(
      'Simulating teardown failure scenario',
      tag: _logTag,
    );

    // Configure one ViewModel to fail
    if (_viewModels.isNotEmpty) {
      _viewModels.first.teardownError = Exception('Simulated teardown failure');
    }

    try {
      await _coordinator.teardownAll();
      return RoleSwitchTeardownResult.success();
    } on RoleSwitchTeardownException catch (e) {
      return RoleSwitchTeardownResult.failure(e.errors);
    }
  }

  /// Reset the simulator state
  void reset() {
    AppLogger.d('Resetting RoleSwitchSimulator', tag: _logTag);
    _coordinator.reset();
    for (final vm in _viewModels) {
      vm.reset();
    }
  }
}
