import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/auth/screens/onboarding_screen.dart';
import 'package:pinshop_tj/features/catalog/screens/home_screen.dart';
import 'package:pinshop_tj/features/channel/screens/channel_choice_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/router/app_router.dart';
import 'package:pinshop_tj/shared/widgets/error_widget.dart';

import 'helpers/fake_dio.dart';
import 'helpers/fake_secure_storage.dart';

Widget _routerHarness({
  required AuthState initialState,
  required DioClient client,
  required FakeSecureStorage storage,
}) {
  return ProviderScope(
    overrides: [
      authInitialStateProvider.overrideWithValue(initialState),
      dioClientProvider.overrideWithValue(client),
      secureStorageProvider.overrideWithValue(storage),
    ],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

void main() {
  testWidgets('unresolved authenticated startup renders only bootstrap spinner',
      (tester) async {
    final pendingProfile = Completer<(int, Object?)>();
    addTearDown(() {
      if (!pendingProfile.isCompleted) {
        pendingProfile.complete((500, {'error': 'failed', 'code': 'INTERNAL'}));
      }
    });
    final storage = FakeSecureStorage();
    final (dio, _) = fakeDio(
      const {},
      asyncRoutes: {
        'GET /api/users/me': () => pendingProfile.future,
      },
    );

    await tester.pumpWidget(
      _routerHarness(
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: false,
          channel: 'b2c',
          channelChosen: true,
        ),
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('profile-bootstrap-spinner')), findsOne);
    expect(find.byType(HomeScreen), findsNothing);

    pendingProfile.complete((500, {'error': 'failed', 'code': 'INTERNAL'}));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'bootstrap error exposes retry and exits after successful refresh',
      (tester) async {
    final retryProfile = Completer<(int, Object?)>();
    addTearDown(() {
      if (!retryProfile.isCompleted) {
        retryProfile.complete((500, {'error': 'failed', 'code': 'INTERNAL'}));
      }
    });
    final storage = FakeSecureStorage();
    final (dio, adapter) = fakeDio({
      'GET /api/users/me': (500, {'error': 'failed', 'code': 'INTERNAL'}),
    });

    await tester.pumpWidget(
      _routerHarness(
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: false,
          channel: 'b2c',
          channelChosen: false,
          error: 'PROFILE_LOAD_FAILED',
        ),
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorWidget), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    adapter.asyncRoutes['GET /api/users/me'] = () => retryProfile.future;
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(find.byKey(const ValueKey('profile-bootstrap-spinner')), findsOne);
    expect(find.text('Retry'), findsNothing);

    retryProfile.complete((
      200,
      {
        'channel': 'b2c',
        'role': 'customer',
        'name': 'User',
        'phone': '+992000000002',
        'email': 'user@example.com',
        'needsProfileSetup': false,
      }
    ));
    await tester.pumpAndSettle();

    expect(adapter.requestCount('GET', '/api/users/me'), 2);
    expect(find.byType(ChannelChoiceScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('bootstrap logout exits to onboarding', (tester) async {
    final storage = FakeSecureStorage();
    final (dio, _) = fakeDio({
      'GET /api/users/me': (500, {'error': 'failed', 'code': 'INTERNAL'}),
    });

    await tester.pumpWidget(
      _routerHarness(
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: false,
          error: 'PROFILE_LOAD_FAILED',
        ),
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
