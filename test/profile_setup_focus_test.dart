import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/auth/screens/profile_setup_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';

import 'helpers/fake_dio.dart';
import 'helpers/fake_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  testWidgets('keyboard Next on name field focuses email field',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pump();

    final nameFieldFinder = find.descendant(
      of: find.byKey(const ValueKey('profile-setup-name-field')),
      matching: find.byType(TextField),
    );
    final emailFieldFinder = find.descendant(
      of: find.byKey(const ValueKey('profile-setup-email-field')),
      matching: find.byType(TextField),
    );

    await tester.tap(nameFieldFinder);
    await tester.pump();
    expect(
        tester.widget<TextField>(nameFieldFinder).focusNode?.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(
      tester.widget<TextField>(emailFieldFinder).focusNode?.hasFocus,
      isTrue,
    );
  });

  testWidgets('profile setup shows existing identity and locks email/phone',
      (tester) async {
    final storage = FakeSecureStorage()
      ..seed(FakeSecureStorage.accessTokenKey, 'token');
    final (dio, _) = fakeDio({
      'GET /api/users/me': (
        200,
        {
          'channel': 'b2c',
          'role': 'customer',
          'name': 'Existing User',
          'phone': '+992000000002',
          'email': 'user@example.com',
          'needsProfileSetup': false,
        }
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          dioClientProvider.overrideWithValue(
            DioClient.withDio(dio, storage: storage),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final nameField = find.descendant(
      of: find.byKey(const ValueKey('profile-setup-name-field')),
      matching: find.byType(TextField),
    );
    final phoneField = find.descendant(
      of: find.byKey(const ValueKey('profile-setup-phone-field')),
      matching: find.byType(TextField),
    );
    final emailField = find.descendant(
      of: find.byKey(const ValueKey('profile-setup-email-field')),
      matching: find.byType(TextField),
    );

    expect(
        tester.widget<TextField>(nameField).controller?.text, 'Existing User');
    expect(
        tester.widget<TextField>(phoneField).controller?.text, '+992000000002');
    expect(tester.widget<TextField>(emailField).controller?.text,
        'user@example.com');
    expect(tester.widget<TextField>(nameField).readOnly, isFalse);
    expect(tester.widget<TextField>(phoneField).readOnly, isTrue);
    expect(tester.widget<TextField>(emailField).readOnly, isTrue);
  });

  testWidgets('new user with no email yet can edit the email field',
      (tester) async {
    final storage = FakeSecureStorage()
      ..seed(FakeSecureStorage.accessTokenKey, 'token');
    final (dio, _) = fakeDio({
      'GET /api/users/me': (
        200,
        {
          'channel': 'b2c',
          'role': 'customer',
          'name': null,
          'phone': '+992000000003',
          'email': null,
          'needsProfileSetup': true,
        }
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          dioClientProvider.overrideWithValue(
            DioClient.withDio(dio, storage: storage),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final emailField = find.descendant(
      of: find.byKey(const ValueKey('profile-setup-email-field')),
      matching: find.byType(TextField),
    );

    // A brand-new user has no email on file yet — the field must stay
    // editable, otherwise they could never complete "знакомство" (regression
    // covered: quick task 260627-i9x made email unconditionally read-only).
    expect(tester.widget<TextField>(emailField).readOnly, isFalse);

    await tester.enterText(emailField, 'newuser@example.com');
    await tester.pump();
    expect(tester.widget<TextField>(emailField).controller?.text,
        'newuser@example.com');
  });
}
