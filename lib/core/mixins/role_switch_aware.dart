/// Mixin for ViewModels that need to participate in role switch teardown.
///
/// Any ViewModel that caches data specific to the user's role should implement
/// this mixin and register with [RoleSwitchCoordinator].
///
/// Example:
/// ```dart
/// class ChatViewModel extends ChangeNotifier with RoleSwitchAware {
///   @override
///   Future<void> teardownForRoleSwitch() async {
///     // Clear caches, disconnect streams, etc.
///   }
/// }
/// ```
library;

// RoleSwitchAware mixin - no imports needed

/// Interface for ViewModels that can be torn down during role switch.
mixin RoleSwitchAware {
  /// Called when the user switches roles (e.g., client -> freelancer).
  ///
  /// Implementations should:
  /// 1. Clear all cached data specific to the previous role
  /// 2. Disconnect from realtime streams/subscriptions
  /// 3. Reset state to initial values
  ///
  /// This method should complete quickly (< 500ms) to ensure smooth UX.
  /// If teardown requires async operations, implement timeouts.
  Future<void> teardownForRoleSwitch();
}

/// Exception thrown when role switch teardown fails.
///
/// Aggregates multiple teardown errors from different ViewModels.
class RoleSwitchTeardownException implements Exception {
  final List<String> errors;

  RoleSwitchTeardownException(this.errors);

  @override
  String toString() => 'RoleSwitchTeardownException: ${errors.join(', ')}';
}
