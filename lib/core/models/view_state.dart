import 'package:flutter/foundation.dart';
import 'package:sline_app/core/models/app_failure.dart';

/// Generic view state sealed class for ViewModel state management.
///
/// Replaces the `bool _isLoading` + `String? _error` + `T? _data` pattern
/// with exhaustive type-safe states that views can pattern-match on.
///
/// Usage in ViewModel:
/// ```dart
/// ViewState<MyData> _state = const ViewInitial();
/// ViewState<MyData> get state => _state;
/// ```
///
/// Usage in View:
/// ```dart
/// switch (vm.state) {
///   case ViewInitial():    return SizedBox.shrink();
///   case ViewLoading():    return CircularProgressIndicator();
///   case ViewLoaded(:final data): return MyWidget(data);
///   case ViewFailed(:final failure): return ErrorWidget(failure);
/// }
/// ```
sealed class ViewState<T> {
  const ViewState();
}

/// No operation has been initiated yet.
class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();
}

/// An operation is in progress.
class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

/// Data was successfully loaded.
@immutable
class ViewLoaded<T> extends ViewState<T> {
  const ViewLoaded(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ViewLoaded<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

/// An operation failed with a typed failure.
@immutable
class ViewFailed<T> extends ViewState<T> {
  const ViewFailed(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewFailed<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
