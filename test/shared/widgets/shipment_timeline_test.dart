import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/shared/widgets/shipment_timeline.dart';

void main() {
  group('shipmentStageForOrderStatus (inverse of STAGE_TO_STATUS)', () {
    test('pre-shipment statuses collapse to the awaiting step', () {
      expect(shipmentStageForOrderStatus('created'), 'awaiting');
      expect(shipmentStageForOrderStatus('paid'), 'awaiting');
      expect(shipmentStageForOrderStatus('placed_on_pinduoduo'), 'awaiting');
    });

    test('pipeline statuses map to their matching stage key', () {
      expect(shipmentStageForOrderStatus('at_cn_warehouse'), 'cn_warehouse');
      expect(shipmentStageForOrderStatus('in_transit'), 'in_transit');
      expect(shipmentStageForOrderStatus('at_tj_warehouse'), 'tj_warehouse');
      expect(shipmentStageForOrderStatus('ready'), 'ready');
      expect(shipmentStageForOrderStatus('delivered'), 'delivered');
    });

    test('terminal/unknown statuses fall back to awaiting, never delivered', () {
      expect(shipmentStageForOrderStatus('cancelled'), 'awaiting');
      expect(shipmentStageForOrderStatus('refunded'), 'awaiting');
      expect(shipmentStageForOrderStatus('garbage'), 'awaiting');
    });
  });

  group('ShipmentTimeline widget', () {
    Widget harness(String currentStage) {
      return MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ShipmentTimeline(
              currentStage: currentStage,
              l10n: AppLocalizations.of(context)!,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'in_transit order highlights the "In transit" step (regression: was stuck at Awaiting)',
        (tester) async {
      // Reproduces the reported symptom: order.status = in_transit must render
      // the in_transit step as current, not the first (awaiting) step.
      await tester.pumpWidget(harness(shipmentStageForOrderStatus('in_transit')));
      await tester.pump();

      // The current-step node is the animated pulse dot; there is exactly one.
      final currentNodes = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_PulseDot',
      );
      expect(currentNodes, findsOneWidget);

      // Steps before the active one are marked done (check icons): awaiting +
      // cn_warehouse => 2 done nodes precede in_transit (index 2).
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      // The active label is rendered.
      expect(find.text('In transit'), findsOneWidget);
    });

    testWidgets('created order highlights the first (Awaiting) step',
        (tester) async {
      await tester.pumpWidget(harness(shipmentStageForOrderStatus('created')));
      await tester.pump();

      // No prior steps are done when the very first step is current.
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text('Awaiting'), findsOneWidget);
    });
  });
}
