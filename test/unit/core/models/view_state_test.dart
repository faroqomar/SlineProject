import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/models/app_failure.dart';
import 'package:sline_app/core/models/view_state.dart';

void main() {
  group('ViewState sealed hierarchy', () {
    test('ViewInitial is default state', () {
      const state = ViewInitial<String>();
      expect(state, isA<ViewState<String>>());
      expect(state, isA<ViewInitial<String>>());
    });

    test('ViewLoading represents in-progress operation', () {
      const state = ViewLoading<int>();
      expect(state, isA<ViewState<int>>());
      expect(state, isA<ViewLoading<int>>());
    });

    test('ViewLoaded holds typed data', () {
      const state = ViewLoaded<String>('hello');
      expect(state, isA<ViewState<String>>());
      expect(state.data, 'hello');
    });

    test('ViewLoaded holds complex data', () {
      const state = ViewLoaded<List<int>>([1, 2, 3]);
      expect(state.data, [1, 2, 3]);
    });

    test('ViewFailed holds AppFailure', () {
      const failure = NetworkFailure('No connection');
      const state = ViewFailed<String>(failure);
      expect(state, isA<ViewState<String>>());
      expect(state.failure, isA<NetworkFailure>());
      expect(state.failure.userMessage, 'No connection');
    });

    test('pattern matching is exhaustive', () {
      const ViewState<int> state = ViewLoaded(42);
      final result = switch (state) {
        ViewInitial() => 'initial',
        ViewLoading() => 'loading',
        ViewLoaded(:final data) => 'loaded: $data',
        ViewFailed(:final failure) => 'failed: ${failure.userMessage}',
      };
      expect(result, 'loaded: 42');
    });

    test('pattern matching extracts failure subtype', () {
      const ViewState<String> state = ViewFailed(
        AuthFailure('Session expired', sessionExpired: true),
      );
      final isSessionExpired = switch (state) {
        ViewFailed(failure: final AuthFailure auth) => auth.sessionExpired,
        _ => false,
      };
      expect(isSessionExpired, true);
    });

    test('all states can be created for same type parameter', () {
      final states = <ViewState<String>>[
        const ViewInitial(),
        const ViewLoading(),
        const ViewLoaded('data'),
        const ViewFailed(NetworkFailure('error')),
      ];
      expect(states, hasLength(4));
      expect(states[0], isA<ViewInitial<String>>());
      expect(states[1], isA<ViewLoading<String>>());
      expect(states[2], isA<ViewLoaded<String>>());
      expect(states[3], isA<ViewFailed<String>>());
    });
  });
}
