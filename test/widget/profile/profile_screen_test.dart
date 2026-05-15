/// Widget tests for the Amber Dusk profile screen shell.
///
/// These tests protect safe-area behavior and keep account settings out of the
/// profile overview because settings now live in the dedicated Settings route.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/profile/view/profile_screen.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockProfileViewModel extends Mock
    with ChangeNotifier
    implements ProfileViewModel {}

void main() {
  late _MockProfileViewModel profileVm;

  setUp(() {
    profileVm = _MockProfileViewModel();
    when(() => profileVm.isLoadingProfile).thenReturn(false);
    when(() => profileVm.profileError).thenReturn(null);
    when(() => profileVm.loadUserData()).thenAnswer((_) async {});
    when(() => profileVm.fullName).thenReturn('Farooq Omar');
    when(() => profileVm.loadedBio).thenReturn('Product designer');
    when(() => profileVm.loadedEmail).thenReturn('farooq@example.com');
    when(() => profileVm.avatarUrl).thenReturn(null);
    when(() => profileVm.badges).thenReturn(const ['AVAILABLE']);
    when(() => profileVm.rating).thenReturn(null);
    when(() => profileVm.skills).thenReturn(const []);
    when(() => profileVm.portfolioItems).thenReturn(const [
      {
        'title': 'Test 2',
        'description': 'Portfolio proof',
        'created_at': '2026-01-01T00:00:00Z',
      },
    ]);
  });

  testWidgets('uses top safe area and keeps settings out of profile body', (
    tester,
  ) async {
    await pumpApp(
      tester,
      ChangeNotifierProvider<ProfileViewModel>.value(
        value: profileVm,
        child: const Scaffold(body: ProfileScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.text('SERVICES'), findsOneWidget);
    expect(find.text('PORTFOLIO'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Logout'), findsNothing);
    expect(find.text('My Services'), findsNothing);
    verify(() => profileVm.loadUserData()).called(1);
  });
}
