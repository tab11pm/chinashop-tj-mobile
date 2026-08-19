import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/shared/widgets/price_tag.dart';
import 'package:pinshop_tj/shared/widgets/empty_state.dart';

void main() {
  testWidgets('PriceTag renders the API money string verbatim (no float parse)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PriceTag(value: '1234.50')),
    ));
    final rich = tester.widget<RichText>(find.byType(RichText).first);
    expect(rich.text.toPlainText(), '1234.50 с');
  });

  testWidgets('EmptyState shows title and fires CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Empty cart',
          actionLabel: 'Shop',
          onAction: () => tapped = true,
        ),
      ),
    ));
    expect(find.text('Empty cart'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);

    await tester.tap(find.text('Shop'));
    expect(tapped, isTrue);
  });
}
