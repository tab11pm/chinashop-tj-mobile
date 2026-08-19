import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/b2b/screens/b2b_application_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';

import '../helpers/fake_dio.dart';

/// Widget tests for the B2B status self-view, asserting the two SC5 /
/// UI-SPEC-critical branches:
///   (a) rejected → rejectionNote text + «Подать заявку заново» (b2bReapply) CTA
///   (b) suspended → NO re-apply CTA
///
/// The real `applicationProvider` is driven via a FakeAdapter response to
/// GET /api/b2b/application, so the provider + screen are exercised end to end.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  Widget harness(Dio dio) {
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
      ],
      child: const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: B2bApplicationScreen(),
      ),
    );
  }

  testWidgets('rejected → shows rejectionNote + re-apply CTA', (tester) async {
    final (dio, _) = fakeDio({
      'GET /api/b2b/application': (
        200,
        {
          'id': 'app1',
          'status': 'rejected',
          'shopName': 'Дӯкони Сомон',
          'taxId': '123456789',
          'city': 'Душанбе',
          'rejectionNote': 'Недостаточно данных',
        },
      ),
    });

    await tester.pumpWidget(harness(dio));
    await tester.pumpAndSettle();

    // Rejection note verbatim.
    expect(find.text('Недостаточно данных'), findsOneWidget);
    // Re-apply CTA present (b2bReapply ru: «Подать заявку заново»).
    expect(find.text('Подать заявку заново'), findsOneWidget);
  });

  testWidgets('suspended → NO re-apply CTA', (tester) async {
    final (dio, _) = fakeDio({
      'GET /api/b2b/application': (
        200,
        {
          'id': 'app2',
          'status': 'suspended',
          'shopName': 'Дӯкони Сомон',
          'taxId': '123456789',
          'city': 'Душанбе',
        },
      ),
    });

    await tester.pumpWidget(harness(dio));
    await tester.pumpAndSettle();

    // Suspended body present...
    expect(find.text('Доступ приостановлен. Свяжитесь с поддержкой.'),
        findsOneWidget);
    // ...but the re-apply CTA is ABSENT (admin-recoverable, UI-SPEC Assumption 5).
    expect(find.text('Подать заявку заново'), findsNothing);
  });
}
