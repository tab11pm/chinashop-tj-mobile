import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/catalog/screens/product_screen.dart';

void main() {
  Widget harness(List<String> imageUrls) => MaterialApp(
        home: SizedBox(
          height: 320,
          child: ProductImageGallery(imageUrls: imageUrls),
        ),
      );

  testWidgets('shows every product image and updates its position indicator',
      (tester) async {
    await tester.pumpWidget(
        harness(['https://img.test/one.jpg', 'https://img.test/two.jpg']));

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Product image 1 of 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    // CachedNetworkImage keeps a loading animation alive in tests, so wait
    // for the page transition directly instead of waiting for every ticker.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Product image 2 of 2'), findsOneWidget);
  });

  testWidgets('keeps the single-image state free of gallery controls',
      (tester) async {
    await tester.pumpWidget(harness(['https://img.test/one.jpg']));

    expect(find.byType(PageView), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
    expect(find.bySemanticsLabel('Product image 1 of 1'), findsOneWidget);
  });
}
