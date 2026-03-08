/// Coordinator for cross-ViewModel role switch teardown.
///
/// The coordinator pattern solves the problem of ProfileViewModel needing to
/// clear caches in other ViewModels (Chat, Dashboard, etc.) without violating
/// MVVM boundaries by directly accessing them from the Provider tree.
///
/// ViewModels register themselves during initialization:
/// ```dart
/// class ChatViewModel extends ChangeNotifier with RoleSwitchAware {
///   ChatViewModel() {
///     RoleSwitchCoordinator().register(this);
///   }
/// }
/// ```
///
/// ProfileViewModel triggers teardown via the coordinator:
/// ```dart
/// await RoleSwitchCoordinator().teardownAll();
/// ```
library;

import 'logger_service.dart';
import '../mixins/role_switch_aware.dart';

/// Singleton coordinator for role switch operations.
///
/// This class is a singleton because role switching is a global app event
/// that affects all ViewModels across all features.
class RoleSwitchCoordinator {
  static final RoleSwitchCoordinator _instance =
      RoleSwitchCoordinator._internal();
  factory RoleSwitchCoordinator() => _instance;
  RoleSwitchCoordinator._internal();

  final List<RoleSwitchAware> _registered = [];
  bool _isTearingDown = false;

  /// Register a ViewModel to be notified during role switch.
  ///
  /// ViewModels should call this in their constructor or init method.
  /// The ViewModel will be held as a weak reference conceptually,
  /// but Dart doesn't have weak references, so unregister in dispose().
  void register(RoleSwitchAware viewModel) {
    if (!_registered.contains(viewModel)) {
      _registered.add(viewModel);
      AppLogger.d(
        'coordinator_register',
        tag: 'RoleSwitch',
        json: {'viewModel': viewModel.runtimeType.toString()},
      );
    }
  }

  /// Unregister a ViewModel (call in dispose()).
  void unregister(RoleSwitchAware viewModel) {
    _registered.remove(viewModel);
    AppLogger.d(
      'coordinator_unregister',
      tag: 'RoleSwitch',
      json: {'viewModel': viewModel.runtimeType.toString()},
    );
  }

  /// Execute teardown on all registered ViewModels.
  ///
  /// This method:
  /// 1. Calls [teardownForRoleSwitch] on every registered ViewModel
  /// 2. Collects any errors
  /// 3. Throws [RoleSwitchTeardownException] if any teardowns failed
  ///
  /// Callers should handle the exception by either:
  /// - Retrying the teardown
  /// - Logging out the user (nuclear option)
  /// - Continuing with warnings (if partial cleanup acceptable)
  Future<void> teardownAll() async {
    if (_isTearingDown) {
      AppLogger.w(
        'coordinator_teardown_already_in_progress',
        tag: 'RoleSwitch',
      );
      throw StateError('Teardown already in progress');
    }

    _isTearingDown = true;
    AppLogger.i(
      'coordinator_teardown_begin',
      tag: 'RoleSwitch',
      json: {'registeredCount': _registered.length},
    );

    final errors = <String>[];
    final startTime = DateTime.now();

    for (final vm in _registered) {
      try {
        final vmStart = DateTime.now();
        await vm.teardownForRoleSwitch();
        final vmDuration = DateTime.now().difference(vmStart);

        AppLogger.d(
          'coordinator_teardown_vm_success',
          tag: 'RoleSwitch',
          json: {
            'viewModel': vm.runtimeType.toString(),
            'durationMs': vmDuration.inMilliseconds,
          },
        );
      } catch (e, stackTrace) {
        final errorMsg = '${vm.runtimeType}: $e';
        errors.add(errorMsg);
        AppLogger.e(
          'coordinator_teardown_vm_failed: ${vm.runtimeType}',
          tag: 'RoleSwitch',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    final totalDuration = DateTime.now().difference(startTime);
    _isTearingDown = false;

    if (errors.isNotEmpty) {
      AppLogger.e(
        'coordinator_teardown_errors: ${errors.length} failed',
        tag: 'RoleSwitch',
        error: errors.join(', '),
      );
      throw RoleSwitchTeardownException(errors);
    }

    AppLogger.i(
      'coordinator_teardown_complete: ${_registered.length} ViewModels in ${totalDuration.inMilliseconds}ms',
      tag: 'RoleSwitch',
    );
  }

  /// Clear all registrations (useful for testing).
  void clearForTesting() {
    _registered.clear();
    _isTearingDown = false;
    AppLogger.d('coordinator_cleared_for_testing', tag: 'RoleSwitch');
  }

  /// Get count of registered ViewModels (for debugging/monitoring).
  int get registeredCount => _registered.length;

  /// Check if teardown is currently in progress.
  bool get isTearingDown => _isTearingDown;
}
