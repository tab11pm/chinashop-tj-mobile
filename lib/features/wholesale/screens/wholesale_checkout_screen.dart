import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wholesale_cart_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/api/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_tokens.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../payment_receipts/providers/payment_receipt_provider.dart';

/// WholesaleCheckoutScreen — two-step checkout→pay flow.
///
/// UI-SPEC §Screen Inventory 2: WholesaleCheckoutScreen (/wholesale/checkout)
/// States: idle / processing / error / success
/// Flow: checkout(addressId) → paymentGroupId → pay(groupId) → /wholesale/orders (replace)
/// MOQ_NOT_MET → error banner with product name/qty + "Вернуться в корзину" button
/// FACTORY_PRODUCT_UNAVAILABLE → банner "Один или несколько товаров недоступны"
/// Address selection mirrors B2C checkout_screen.dart — required before payment
/// (debug/b2b-order-no-address-redirect.md symptom 1: checkout used to accept no
/// delivery address at all).
class WholesaleCheckoutScreen extends ConsumerStatefulWidget {
  const WholesaleCheckoutScreen({super.key});

  @override
  ConsumerState<WholesaleCheckoutScreen> createState() =>
      _WholesaleCheckoutScreenState();
}

class _WholesaleCheckoutScreenState
    extends ConsumerState<WholesaleCheckoutScreen> {
  String? _selectedAddressId;
  bool _isProcessing = false;
  bool _addressMissing = false;
  String? _errorCode;
  Object? _rawError; // Preserve raw error for qty extraction

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchAddresses();
    });
  }

  Future<void> _confirmAndPay() async {
    if (_selectedAddressId == null) {
      setState(() => _addressMissing = true);
      return;
    }
    setState(() {
      _isProcessing = true;
      _addressMissing = false;
      _errorCode = null;
      _rawError = null;
    });

    try {
      // Flush pending qty debounce BEFORE checkout so the server cart is
      // authoritative at order creation (D-03: qty must be up to date).
      await ref.read(wholesaleCartProvider.notifier).flushPending();

      // Step 1: POST /api/wholesale/orders/checkout { addressId } → { paymentGroupId, orders, totalTjs }
      final result = await ref
          .read(wholesaleCartProvider.notifier)
          .checkout(_selectedAddressId!);

      // Step 2: POST /api/wholesale/payment-groups/{groupId}/pay → PaymentInitiation
      final initiation = await ref
          .read(wholesaleCartProvider.notifier)
          .pay(result.paymentGroupId);

      // Step 3: go to the payment-link + receipt flow instead of jumping straight
      // to the wholesale orders list. Opening the dc_link is not confirmation;
      // the receipt upload is the explicit next step (PAYLINK-03). The orders
      // list is reached from there only after a successful upload (Done).
      if (mounted) {
        context.push(
          AppRoutes.paymentReceipt,
          extra: PaymentReceiptArgs(
            initiation: initiation,
            kind: PaymentFlowKind.wholesale,
          ),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() {
        _errorCode = errorCodeOf(e);
        _rawError = e;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cartState = ref.watch(wholesaleCartProvider);
    final profileState = ref.watch(profileProvider);
    final items = cartState.items;

    // Group items by factory
    final Map<String, List<WholesaleCartItem>> byFactory = {};
    for (final item in items) {
      byFactory.putIfAbsent(item.factoryName, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wholesaleCheckoutTitle),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Text(
              l10n.wholesaleOrderSummaryHeading,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.lg),

            // Order summary card grouped by factory
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...byFactory.entries.map((entry) {
                    final factoryName = entry.key;
                    final factoryItems = entry.value;
                    return _FactoryGroup(
                      factoryName: factoryName,
                      items: factoryItems,
                      l10n: l10n,
                      theme: theme,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // Green total block — mirrors checkout_screen.dart L139-165.
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg, vertical: AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.accentPlate.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.accentBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.wholesaleOrderTotalLabel,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  PriceTag(
                    value: _grandTotal(items),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // Address selector — mirrors checkout_screen.dart L169-218 (WR-XX:
            // wholesale checkout previously had no address requirement at all —
            // see debug/b2b-order-no-address-redirect.md).
            Text(l10n.deliveryAddress, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpace.md),

            if (profileState.isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (profileState.addresses.isEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.line),
                ),
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  children: [
                    Text(
                      l10n.noSavedAddresses,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.md),
                    ElevatedButton(
                      onPressed: () => context.push(AppRoutes.addressNew),
                      child: Text(l10n.addAddressCta),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedAddressId,
                hint: Text(l10n.selectAddress),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: profileState.addresses
                    .map(
                      (addr) => DropdownMenuItem(
                        value: addr.id,
                        child: Text(
                          addr.displayLine,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedAddressId = val;
                  _addressMissing = false;
                }),
              ),

            if (_addressMissing) ...[
              const SizedBox(height: AppSpace.sm),
              AppErrorWidget(error: l10n.selectAddress),
            ],

            const SizedBox(height: AppSpace.lg),

            // Error banner
            if (_errorCode != null) _buildErrorBanner(context, l10n, theme),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirmAndPay,
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onAccent,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(l10n.wholesaleCheckoutProcessing),
                      ],
                    )
                  : Text(l10n.wholesaleCheckoutCta),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_errorCode == 'MOQ_NOT_MET') {
      // Extract qty from DomainException.message if available
      final moqMsg = localizedMoqError(context, _rawError);
      return Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              moqMsg ?? l10n.wholesaleCheckoutMoqError(0, ''),
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: Text(l10n.wholesaleCheckoutReturnToCart),
            ),
          ],
        ),
      );
    }

    if (_errorCode == 'FACTORY_PRODUCT_UNAVAILABLE') {
      return Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.wholesaleCheckoutProductUnavailable,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: Text(l10n.wholesaleCheckoutReturnToCart),
            ),
          ],
        ),
      );
    }

    // Generic error
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedError(context, _rawError ?? _errorCode!),
            style:
                theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: _confirmAndPay,
            child: Text(l10n.wholesaleCheckoutRetry),
          ),
        ],
      ),
    );
  }

  /// Grand total from subtotal strings — display preview (server total is authoritative).
  /// Sums via integer minor-units (tiins = 1/100 TJS) — no float accumulation (CR-05).
  String _grandTotal(List<WholesaleCartItem> items) {
    int totalTiins = 0;
    for (final item in items) {
      totalTiins += _parseTiins(item.subtotalTjs);
    }
    return _tiinsToString(totalTiins);
  }
}

/// Parse a MoneyString '123.45' into integer tiins (12345). No float involved (CR-05).
///
/// The API contract guarantees scale-2 strings, but if an intermediate-scale
/// value (e.g. '12.999') ever arrives we round the sub-tiin remainder half-up
/// instead of truncating it (WR-06). All-integer arithmetic — no float.
int _parseTiins(String moneyStr) {
  final parts = moneyStr.split('.');
  final whole = int.tryParse(parts[0]) ?? 0;
  if (parts.length <= 1) return whole * 100;
  // Take the first 3 fractional digits and round half-up on the thousandths.
  final frac3 = int.tryParse(parts[1].padRight(3, '0').substring(0, 3)) ?? 0;
  final frac = (frac3 + 5) ~/ 10;
  return whole * 100 + frac;
}

/// Convert integer tiins back to a '123.45' MoneyString. No float involved (CR-05).
String _tiinsToString(int tiins) {
  final tjs = tiins ~/ 100;
  final frac = tiins % 100;
  return '$tjs.${frac.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Per-factory group section in checkout summary
// ---------------------------------------------------------------------------

class _FactoryGroup extends StatelessWidget {
  const _FactoryGroup({
    required this.factoryName,
    required this.items,
    required this.l10n,
    required this.theme,
  });

  final String factoryName;
  final List<WholesaleCartItem> items;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Sum via integer tiins — no float accumulation (CR-05)
    int subtotalTiins = 0;
    for (final item in items) {
      subtotalTiins += _parseTiins(item.subtotalTjs);
    }
    final subtotalStr = _tiinsToString(subtotalTiins);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Factory header: demo .wcart-fac .fh dark business band.
        Container(
          color: AppColors.b2bBand,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          child: Row(
            children: [
              const Icon(Icons.factory_outlined,
                  size: 16, color: AppColors.onAccent),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  factoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.onAccent,
                  ),
                ),
              ),
              Text(
                '${items.length}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8FA89C),
                ),
              ),
            ],
          ),
        ),
        // Item rows
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${l10n.qty}: ${item.qty}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                PriceTag(value: item.unitPriceTjs),
              ],
            ),
          );
        }),
        // Factory subtotal
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.wholesaleFactorySubtotalLabel,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
              PriceTag(
                value: subtotalStr,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
      ],
    );
  }
}
