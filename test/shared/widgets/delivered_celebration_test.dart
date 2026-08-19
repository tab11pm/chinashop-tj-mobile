import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/shared/widgets/delivered_celebration.dart';

void main() {
  Widget harness(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders localized copy in a non-blocking IgnorePointer',
      (tester) async {
    await tester.pumpWidget(
      harness(
        DeliveredCelebration(
          onDismissed: () {},
          duration: const Duration(milliseconds: 200),
        ),
      ),
    );

    expect(find.text('Congratulations on your purchase!'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      ),
      findsOneWidget,
    );
    final celebration = find.byType(DeliveredCelebration);
    expect(
      find.descendant(of: celebration, matching: find.byType(FadeTransition)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: celebration, matching: find.byType(ScaleTransition)),
      findsOneWidget,
    );
  });

  testWidgets('auto dismisses exactly once after configured duration',
      (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      harness(
        DeliveredCelebration(
          onDismissed: () => dismissed++,
          duration: const Duration(milliseconds: 200),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 199));
    expect(dismissed, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(dismissed, 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(dismissed, 1);
  });

  testWidgets('can unmount mid-animation without controller errors',
      (tester) async {
    await tester.pumpWidget(
      harness(
        DeliveredCelebration(
          onDismissed: () {},
          duration: const Duration(milliseconds: 500),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(harness(const SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
