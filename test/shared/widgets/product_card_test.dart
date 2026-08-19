import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/l10n/tg_material_localizations.dart';
import 'package:pinshop_tj/shared/widgets/product_card.dart';

void main() {
  // en locale so the average uses a plain "." decimal separator in
  // assertions (ru/tj format "4,6" with a comma — see UI-SPEC C-1).
  Widget harness(
    Widget child, {
    Locale locale = const Locale('en'),
    double height = 260,
    double width = 180,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        TgMaterialLocalizationsDelegate(),
        TgCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home:
          Scaffold(body: SizedBox(height: height, width: width, child: child)),
    );
  }

  testWidgets('ratingCount 0 renders no rating row', (tester) async {
    await tester.pumpWidget(
      harness(const ProductCard(
        productId: 'p1',
        name: 'Test product',
        priceTjs: '10.00',
        ratingCount: 0,
      )),
    );
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('ratingCount 12 avgRating 4.6 renders the rating row',
      (tester) async {
    await tester.pumpWidget(
      harness(const ProductCard(
        productId: 'p1',
        name: 'Test product',
        priceTjs: '10.00',
        ratingCount: 12,
        avgRating: 4.6,
      )),
    );
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.textContaining('4.6'), findsOneWidget);
    expect(find.textContaining('(12)'), findsOneWidget);
  });

  testWidgets('two-line product card does not overflow in a 360px phone grid',
      (tester) async {
    const viewportWidth = 360.0;
    const horizontalPadding = 12.0;
    const crossAxisSpacing = 8.0;
    const columnCount = 2;
    const childAspectRatio = 0.68;
    const productName =
        'Extra long product name that must wrap onto exactly two lines';
    const cardWidth =
        (viewportWidth - horizontalPadding * 2 - crossAxisSpacing) /
            columnCount;

    await tester.pumpWidget(
      harness(
        ProductCard(
          productId: 'p1',
          name: productName,
          priceTjs: '10.00',
          ratingCount: 12,
          avgRating: 4.6,
          onAdd: () {},
          addLabel: 'Add to cart',
        ),
        width: cardWidth,
        height: cardWidth / childAspectRatio,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text(productName)).maxLines, 2);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.textContaining('(12)'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
  });

  testWidgets('rating row renders when Flutter locale is Tajik tg',
      (tester) async {
    await tester.pumpWidget(
      harness(
        const ProductCard(
          productId: 'p1',
          name: 'Test product',
          priceTjs: '10.00',
          ratingCount: 12,
          avgRating: 4.6,
        ),
        locale: const Locale('tg'),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });
}
