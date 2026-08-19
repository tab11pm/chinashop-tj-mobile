import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/payment_receipts/providers/payment_receipt_provider.dart';
import 'package:pinshop_tj/features/payment_receipts/screens/payment_receipt_flow_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';

/// Widget tests for PaymentReceiptFlowScreen (Phase 16 Plan 04, Task 2).
///
/// Proves the phase invariant at the UI layer:
///   - The receipt step is shown BEFORE any upload (awaitingReceipt initial state):
///     the user is asked to upload a receipt, with gallery + camera options.
///   - Opening the payment link is NOT confirmation — the explicit
///     `paymentLinkOpenedNote` ("Opening the link does NOT confirm payment...")
///     is always visible. There is NO "paid"/success copy on the initial screen;
///     "Receipt received" (awaitingReview) only appears AFTER a successful upload.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  Widget harness(PaymentInitiation initiation) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaymentReceiptFlowScreen(
          initiation: initiation,
          onDone: (_) {},
        ),
      ),
    );
  }

  const initiation = PaymentInitiation(
    paymentId: 'pay1',
    externalId: 'dc-link-pay-pay1',
    redirectUrl: 'http://pay.dc.tj/?a=992900000000&s=20&c=&f1=124&f2=&f3=',
    status: 'pending',
    amountTjs: '20.00',
  );

  testWidgets('shows the receipt step before upload (awaiting receipt)',
      (tester) async {
    await tester.pumpWidget(harness(initiation));
    await tester.pumpAndSettle();

    // The amount is rendered verbatim (money string, no float parse).
    // PriceTag is a RichText (value + 'с' сомони suffix), so findRichText: true.
    expect(find.text('20.00 с', findRichText: true), findsOneWidget);

    // Initial state = awaitingReceipt: the upload step is visible with both
    // gallery and camera options. (receiptStepTitle = "Upload your receipt")
    expect(find.text('Upload your receipt'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsWidgets);
    expect(find.text('Take a photo'), findsWidgets);
  });

  testWidgets(
      'opening the link is explicitly NOT confirmation — no paid copy before upload',
      (tester) async {
    await tester.pumpWidget(harness(initiation));
    await tester.pumpAndSettle();

    // The open-link CTA is present...
    expect(find.text('Open payment link'), findsOneWidget);

    // ...accompanied by the EXPLICIT no-confirmation note.
    expect(
      find.text(
        'Opening the link does NOT confirm payment. '
        'After paying, upload your receipt below.',
      ),
      findsOneWidget,
    );

    // CRITICAL: the "Receipt received" (awaitingReview) copy must NOT be present
    // before any upload — opening the link never fakes a confirmed/paid state.
    expect(find.text('Receipt received'), findsNothing);
    // The "Done" CTA only appears in the awaitingReview state — not yet.
    expect(find.text('Done'), findsNothing);
  });
}
