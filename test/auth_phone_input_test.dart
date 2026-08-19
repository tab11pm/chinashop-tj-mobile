import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/auth/screens/auth_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/l10n/tg_material_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  testWidgets('phone input keeps +992 as a fixed prefix', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            TgMaterialLocalizationsDelegate(),
            TgCupertinoLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('ru'),
            Locale('tg'),
          ],
          home: AuthScreen(),
        ),
      ),
    );
    await tester.pump();

    final phoneField = tester.widget<TextField>(find.byType(TextField));
    final inputFormatters = phoneField.inputFormatters ?? [];

    expect(phoneField.decoration?.prefixText, '+992 ');
    expect(inputFormatters, isNotEmpty);

    await tester.enterText(find.byType(TextField), '+9929012345678abc');
    expect(phoneField.controller?.text, '901234567');
  });
}
