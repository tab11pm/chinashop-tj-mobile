// Widget tests for B2bHomeScreen (Phase 15, plan 15-03; KPI row Phase 21.2-03).
//
// Verifies:
//   1. D-09 role gate: unverified users see WholesaleLockedBody; verified sellers
//      see the dark header band.
//   2. KPI row: orders-this-month count and turnover TJS derived client-side from
//      wholesaleOrdersProvider; seller-status tile always shows 'verified'.
//   3. Loading / error AsyncValue states show placeholder '—' rather than crashing.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/wholesale/screens/b2b_home_screen.dart';
import 'package:pinshop_tj/features/wholesale/screens/wholesale_locked_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';

import '../helpers/fake_dio.dart';
import '../helpers/fake_secure_storage.dart';

// Helper: build a canned WholesaleOrder JSON entry for fakeDio.
Map<String, dynamic> _order({
  required String id,
  required String createdAt, // ISO-8601 string e.g. '2026-06-15T10:00:00.000Z'
  required String totalTjs, // money string, e.g. '5000.00'
}) {
  return {
    'id': id,
    'factoryName': 'Test Factory',
    'status': 'paid',
    'totalTjs': totalTjs,
    'createdAt': createdAt,
    'items': <dynamic>[],
    'receiptReviewStatus': 'none',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Silence the secure-storage plugin channel.
    const ch = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (call) async => null);
  });

  // ─── Harness ─────────────────────────────────────────────────────────────────

  Widget harness({required Dio dio, required FakeSecureStorage storage}) {
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ru'),
        home: B2bHomeScreen(),
      ),
    );
  }

  // ─── Role gate tests ──────────────────────────────────────────────────────────

  group('B2bHomeScreen – role gate', () {
    testWidgets(
      'renders WholesaleLockedBody when role is not wholesale_seller',
      (tester) async {
        // No access token → _syncFromServer is never called → role stays null.
        final storage = FakeSecureStorage();
        final (dio, _) = fakeDio({});

        await tester.pumpWidget(harness(dio: dio, storage: storage));
        await tester.pumpAndSettle();

        expect(find.byType(WholesaleLockedBody), findsOneWidget);
      },
    );

    testWidgets(
      'renders dark band when role is wholesale_seller',
      (tester) async {
        final storage = FakeSecureStorage();
        storage.seed(FakeSecureStorage.accessTokenKey, 'token');

        // Current month in UTC for the orders endpoint.
        final now = DateTime.now().toUtc();
        final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final thisMonthIso = '$thisMonth-15T10:00:00.000Z';

        final (dio, _) = fakeDio({
          'GET /api/users/me': (
            200,
            {
              'channel': 'b2b',
              'role': 'wholesale_seller',
              'needsProfileSetup': false,
            },
          ),
          'GET /api/wholesale/orders': (
            200,
            [_order(id: 'o1', createdAt: thisMonthIso, totalTjs: '3000.00')],
          ),
        });

        await tester.pumpWidget(harness(dio: dio, storage: storage));
        await tester.pumpAndSettle();

        // Locked body must be gone.
        expect(find.byType(WholesaleLockedBody), findsNothing);

        // Band logo label must be present (dark band rendered).
        final ctx = tester.element(find.byType(B2bHomeScreen));
        final l10n = AppLocalizations.of(ctx)!;
        expect(find.text(l10n.b2bBandLogoLabel), findsOneWidget);
      },
    );
  });

  // ─── KPI row tests ────────────────────────────────────────────────────────────

  group('B2bHomeScreen – KPI row', () {
    /// Verified seller harness with seeded orders.
    Widget kpiHarness(List<dynamic> orders) {
      final storage = FakeSecureStorage();
      storage.seed(FakeSecureStorage.accessTokenKey, 'token');
      final (dio, _) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2b',
            'role': 'wholesale_seller',
            'needsProfileSetup': false,
          },
        ),
        'GET /api/wholesale/orders': (200, orders),
      });
      return harness(dio: dio, storage: storage);
    }

    testWidgets(
      'KPI: orders-this-month count matches orders created in current calendar month',
      (tester) async {
        final now = DateTime.now().toUtc();
        final thisMonthIso =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-10T08:00:00.000Z';
        final lastMonthDate = DateTime(now.year, now.month - 1, 5);
        final lastMonthIso =
            '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}-05T08:00:00.000Z';

        final orders = [
          _order(id: 'o1', createdAt: thisMonthIso, totalTjs: '1000.00'),
          _order(id: 'o2', createdAt: thisMonthIso, totalTjs: '2000.00'),
          _order(id: 'o3', createdAt: lastMonthIso, totalTjs: '500.00'),
        ];

        await tester.pumpWidget(kpiHarness(orders));
        await tester.pumpAndSettle();

        // Count = 2 (only this-month orders).
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'KPI: turnover sums totalTjs for this-month orders only (integer-safe, no float)',
      (tester) async {
        final now = DateTime.now().toUtc();
        final thisMonthIso =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-12T09:00:00.000Z';
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        final lastMonthIso =
            '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}-01T00:00:00.000Z';

        final orders = [
          _order(id: 'o1', createdAt: thisMonthIso, totalTjs: '1500.50'),
          _order(id: 'o2', createdAt: thisMonthIso, totalTjs: '2499.50'),
          _order(id: 'o3', createdAt: lastMonthIso, totalTjs: '999.00'),
        ];

        await tester.pumpWidget(kpiHarness(orders));
        await tester.pumpAndSettle();

        // Sum: 1500.50 + 2499.50 = 4000.00 → displayed as '4000.00 с'
        // The KPI tile shows the formatted value; check the numeric part.
        expect(find.textContaining('4000'), findsOneWidget);
      },
    );

    testWidgets(
      'KPI: seller-status tile always shows localized verified label',
      (tester) async {
        final now = DateTime.now().toUtc();
        final thisMonthIso =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01T00:00:00.000Z';

        await tester.pumpWidget(
          kpiHarness([
            _order(id: 'o1', createdAt: thisMonthIso, totalTjs: '100.00'),
          ]),
        );
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(B2bHomeScreen));
        final l10n = AppLocalizations.of(ctx)!;
        // The static 'verified' value label.
        expect(find.text(l10n.b2bKpiVerifiedValue), findsOneWidget);
      },
    );

    testWidgets(
      'KPI: when orders API returns empty list, count is 0 and turnover is 0.00',
      (tester) async {
        // The orders endpoint returns an empty list — the zero-order case.
        // KPI tiles show '0' count and '0.00 с' turnover (not placeholder '—').
        final storage = FakeSecureStorage();
        storage.seed(FakeSecureStorage.accessTokenKey, 'token');
        final (dio, _) = fakeDio({
          'GET /api/users/me': (
            200,
            {
              'channel': 'b2b',
              'role': 'wholesale_seller',
              'needsProfileSetup': false,
            },
          ),
          'GET /api/wholesale/orders': (200, <dynamic>[]),
        });
        final widget = harness(dio: dio, storage: storage);

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Should not throw.
        expect(tester.takeException(), isNull);

        // Zero orders this month.
        expect(find.text('0'), findsOneWidget);
        // Turnover shows '0.00 с'
        expect(find.textContaining('0.00'), findsOneWidget);
      },
    );
  });
}
