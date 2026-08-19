// Widget tests for the channel-switch bottom sheet (Phase 15, plan 15-03).
//
// Driven through B2bProfileScreen's "switch to B2C" ListTile (D-10 / B2B-02):
//   1. Tapping the tile opens the confirmation bottom sheet.
//   2. Tapping confirm calls AuthNotifier.setChannel('b2c') → PATCH the channel.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/wholesale/screens/b2b_profile_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';

import '../helpers/fake_dio.dart';
import '../helpers/fake_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const ch = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (call) async => null);
  });

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
        home: B2bProfileScreen(),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(B2bProfileScreen)))!;

  group('ChannelSwitchBottomSheet', () {
    testWidgets(
      'channel switch bottom sheet renders on switcher tap',
      (tester) async {
        final storage = FakeSecureStorage();
        final (dio, _) = fakeDio({
          'GET /api/addresses': (200, <dynamic>[]),
        });

        await tester.pumpWidget(harness(dio: dio, storage: storage));
        await tester.pumpAndSettle();

        final l10n = l10nOf(tester);

        // Tap the "switch to B2C" tile (Section 1 of the B2B profile).
        await tester.tap(find.text(l10n.switchToB2cLabel));
        await tester.pumpAndSettle();

        // The confirmation sheet must now be on screen.
        expect(find.text(l10n.switchChannelConfirmButton), findsOneWidget);
        expect(find.text(l10n.switchChannelCancel), findsOneWidget);
      },
    );

    testWidgets(
      'confirm button calls setChannel with target channel',
      (tester) async {
        final storage = FakeSecureStorage();
        final (dio, adapter) = fakeDio({
          'GET /api/addresses': (200, <dynamic>[]),
          'PATCH /api/users/me/channel': (200, {'channel': 'b2c'}),
        });

        await tester.pumpWidget(harness(dio: dio, storage: storage));
        await tester.pumpAndSettle();

        final l10n = l10nOf(tester);

        await tester.tap(find.text(l10n.switchToB2cLabel));
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n.switchChannelConfirmButton));
        await tester.pumpAndSettle();

        // setChannel('b2c') must have fired the PATCH with the target channel
        // and written it through to storage.
        final patch = adapter.requestTo('PATCH', '/api/users/me/channel');
        expect((patch.data as Map)['channel'], 'b2c');
        expect(storage.data[FakeSecureStorage.channelKey], 'b2c');
      },
    );
  });
}
