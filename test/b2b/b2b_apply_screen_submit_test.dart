import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/b2b/screens/b2b_apply_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/router/app_router.dart';

/// Same shape as test/helpers/fake_dio.dart's FakeAdapter, but with a
/// configurable artificial delay before responding — needed to reproduce the
/// autoDispose race: a real network round trip gives Riverpod enough time to
/// tear down an unwatched `autoDispose` notifier between the POST and the
/// notifier's internal follow-up GET.
class _DelayedFakeAdapter implements HttpClientAdapter {
  _DelayedFakeAdapter(this.routes, this.delay);
  final Map<String, (int, Object?)> routes;
  final Duration delay;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(delay);
    final entry = routes['${options.method} ${options.path}'] ?? (200, null);
    final body = entry.$2 == null ? '' : jsonEncode(entry.$2);
    return ResponseBody.fromString(
      body,
      entry.$1,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  Widget harness(Dio dio) {
    final router = GoRouter(
      initialLocation: AppRoutes.b2bApply,
      routes: [
        GoRoute(
          path: AppRoutes.b2bApply,
          builder: (context, state) => const B2bApplyScreen(),
        ),
        GoRoute(
          path: AppRoutes.b2bApplication,
          builder: (context, state) => const Text('APPLICATION_SCREEN_STUB'),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
      'submit: server creates the application but the screen must NOT show '
      'a generic error (b2b-apply-false-error-dup regression)',
      (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = _DelayedFakeAdapter(
      {
        'POST /api/b2b/apply': (
          201,
          {
            'id': 'app1',
            'status': 'pending',
            'shopName': 'Дӯкони Сомон',
            'taxId': '123456789',
            'city': 'Душанбе',
          },
        ),
        'GET /api/b2b/application': (
          200,
          {
            'id': 'app1',
            'status': 'pending',
            'shopName': 'Дӯкони Сомон',
            'taxId': '123456789',
            'city': 'Душанбе',
          },
        ),
      },
      const Duration(milliseconds: 50),
    );

    await tester.pumpWidget(harness(dio));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Дӯкони Сомон',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456789');
    await tester.enterText(find.byType(TextFormField).at(2), 'Душанбе');

    await tester.tap(find.byType(ElevatedButton));
    // Let the delayed POST + internal fetch() complete.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // The server accepted the application (POST returned 201). The screen
    // must not show the generic error banner just because the client's
    // internal post-submit refresh raced with provider disposal.
    expect(
      find.text('Что-то пошло не так. Попробуйте снова.'),
      findsNothing,
      reason: 'Server created the application (201), but the UI showed the '
          'generic error — this is the b2b-apply-false-error-dup bug: '
          'ApplicationNotifier.fetch() sets `state` after an autoDispose '
          'notifier with no active listener was already torn down.',
    );

    // And the happy path actually completes: navigation to the status screen.
    expect(find.text('APPLICATION_SCREEN_STUB'), findsOneWidget);
  });
}
