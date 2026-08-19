import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../router/app_router.dart';
import '../providers/wholesale_orders_provider.dart';
import '../providers/wholesale_provider.dart';
import '../widgets/wholesale_product_card.dart';
import './wholesale_locked_screen.dart'; // WholesaleLockedBody — D-09 reuse

// ---------------------------------------------------------------------------
// Money-string summation helper (integer-safe — never double.parse)
// ---------------------------------------------------------------------------

/// Sums a list of money strings like '1500.50' using integer-cents arithmetic.
/// Each string is split on '.' to avoid float parsing entirely.
/// Result is formatted as '%d.%02d' (e.g. '4000.00').
String _sumMoneyStrings(List<String> values) {
  int totalCents = 0;
  for (final v in values) {
    final parts = v.split('.');
    final wholePart = int.tryParse(parts[0]) ?? 0;
    // Handle money strings that may have 0, 1, or 2 decimal digits.
    final fracStr = parts.length > 1 ? parts[1] : '';
    final fracPadded = fracStr.padRight(2, '0').substring(0, 2);
    final fracPart = int.tryParse(fracPadded) ?? 0;
    totalCents += wholePart * 100 + fracPart;
  }
  final whole = totalCents ~/ 100;
  final frac = totalCents % 100;
  return '$whole.${frac.toString().padLeft(2, '0')}';
}

/// B2bHomeScreen — tab 0 of the B2B shell (route: /b2b/home).
///
/// D-05 / D-08 / D-09:
///   - Verified sellers (role == 'wholesale_seller'): shows dark _B2bHeaderBand
///     (logo + channel-switch pill + greeting + search bar + 3 KPI tiles) above
///     the quick-entry section (factory catalog, wholesale orders).
///   - Unverified users (role != 'wholesale_seller'): shows WholesaleLockedBody
///     (UI hint only; WholesaleVerifiedGuard on the server is the real gate).
class B2bHomeScreen extends ConsumerStatefulWidget {
  const B2bHomeScreen({super.key});

  @override
  ConsumerState<B2bHomeScreen> createState() => _B2bHomeScreenState();
}

class _B2bHomeScreenState extends ConsumerState<B2bHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Re-sync role on entry: an admin may have approved the wholesale application
    // since login. authProvider is watched in build(), so the screen unlocks
    // itself the moment the role flips to 'wholesale_seller'.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).refreshFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    // D-09: unverified state — show locked body (role is a UI hint from AuthState).
    // Pull-to-refresh re-checks the role so a freshly-approved seller can unlock
    // without restarting the app.
    if (authState.role != 'wholesale_seller') {
      return Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(authProvider.notifier).refreshFromServer(),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: const WholesaleLockedBody(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Watch wholesaleOrdersProvider to derive KPI values client-side.
    // RESEARCH.md Open Question 1: fetchOrders() has no pagination — safe to
    // filter the full list locally for "this month" KPIs.
    final ordersAsync = ref.watch(wholesaleOrdersProvider);

    // Derive KPI values from the loaded order list.
    // Placeholder '—' shown during loading or error states.
    String ordersThisMonthStr = '—';
    String turnoverThisMonthStr = '—';

    ordersAsync.whenData((orders) {
      final now = DateTime.now();
      final thisMonthOrders = orders.where((o) {
        if (o.createdAt.isEmpty) return false;
        try {
          final dt = DateTime.parse(o.createdAt);
          return dt.year == now.year && dt.month == now.month;
        } catch (_) {
          return false;
        }
      }).toList();

      ordersThisMonthStr = thisMonthOrders.length.toString();
      turnoverThisMonthStr = _sumMoneyStrings(
        thisMonthOrders.map((o) => o.totalTjs).toList(),
      );
    });

    // Verified seller: dark business-band header + content matching demo.
    // No AppBar — _B2bHeaderBand IS the top of the screen (demo structure).
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark business-band header (logo + switch pill + greeting + search + KPIs).
              _B2bHeaderBand(
                onSwitchTap: () =>
                    _showChannelSwitchSheet(context, ref, 'b2c'),
                ordersThisMonth: ordersThisMonthStr,
                turnoverThisMonth: turnoverThisMonthStr,
              ),

              // Factory categories section (demo: .b2b-sech + .fac-row)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _SectionHeader(
                  title: l10n.b2bSectionFactories,
                  linkText: l10n.b2bSectionSeeAll,
                  onLinkTap: () => context.push(AppRoutes.wholesaleFactories),
                ),
              ),
              const SizedBox(height: 10),
              const _FactoryCategoryRow(),

              // Popular wholesale products section (demo: .b2b-sech + .wgrid)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: _SectionHeader(
                  title: l10n.b2bSectionPopular,
                  linkText: l10n.b2bSectionCatalog,
                  onLinkTap: () => context.push(AppRoutes.wholesaleCatalog),
                ),
              ),
              const SizedBox(height: 10),

              // Wholesale product grid
              const _WholesaleProductGrid(),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// _B2bHeaderBand — dark business-band header for verified sellers.
///
/// Matches the demo's `.b2b-head` block:
///   - Dark #10241B gradient container
///   - Top row: logo (icon + "ChinaShop Бизнес") + channel-switch pill
///   - Greeting line (localized) with muted subtitle
///   - Search bar (taps → catalog, which now has real search input)
///   - 3 KPI tiles: orders-this-month / turnover-TJS / seller-status
///
/// D-08 / Design Divergence 3: replaces the old cream _ChannelBanner + plain AppBar.
class _B2bHeaderBand extends StatelessWidget {
  final VoidCallback onSwitchTap;
  final String ordersThisMonth;  // pre-computed in parent (has ref)
  final String turnoverThisMonth; // pre-computed in parent (has ref)

  const _B2bHeaderBand({
    required this.onSwitchTap,
    required this.ordersThisMonth,
    required this.turnoverThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      // Demo: linear-gradient(160deg,#10241B,#16332451) OVER background-color:#10241B.
      // The CSS second stop #16332451 = #163324 at ~32% alpha, composited on top of
      // the opaque #10241B base. We pre-composite it here so BOTH stops stay opaque —
      // a translucent stop let the cream page bleed through the band and hid the white
      // KPI / pill text on the right side. Direction approximates the 160deg angle.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.34, -1.0),
          end: const Alignment(0.34, 1.0),
          colors: [
            AppColors.b2bBand,
            Color.alphaBlend(const Color(0x51163324), AppColors.b2bBand),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo + channel-switch pill
          Row(
            children: [
              // Logo: green icon box + text
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.factory,
                  color: AppColors.b2bBand,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.b2bBandLogoLabel,
                style: const TextStyle(
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.onAccent,
                ),
              ),
              const Spacer(),
              // Channel-switch pill — two segments
              _ChannelSwitchPill(onSwitchToBuyerTap: onSwitchTap),
            ],
          ),

          const SizedBox(height: 16),

          // Greeting line
          Text(
            l10n.b2bBandGreeting,
            style: const TextStyle(
              fontFamily: 'Onest',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.onAccent,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.b2bBandGreetingSubtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Color(0xFF8fa89c), // muted on dark — sanctioned one-off for dark-surface chrome
            ),
          ),

          const SizedBox(height: 14),

          // Search entry point — opens catalog, which owns the actual search input
          GestureDetector(
            onTap: () => context.push(AppRoutes.wholesaleCatalog),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.b2bBandSearchHint,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3-tile KPI row matching demo .b2b-kpi
          _KpiRow(
            ordersThisMonth: ordersThisMonth,
            turnoverThisMonth: turnoverThisMonth,
          ),
        ],
      ),
    );
  }
}

/// _KpiRow — 3-tile row inside the dark header band.
///
/// Tiles: orders-this-month count / turnover TJS / seller verification status.
/// Styling matches demo `.b2b-kpi .k`: translucent white bg/border, 13px radius.
class _KpiRow extends StatelessWidget {
  final String ordersThisMonth;
  final String turnoverThisMonth;

  const _KpiRow({
    required this.ordersThisMonth,
    required this.turnoverThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _KpiTile(
          value: ordersThisMonth,
          label: l10n.b2bKpiOrdersLabel,
        ),
        const SizedBox(width: 9),
        _KpiTile(
          // Append 'с' currency suffix for turnover (only when it's a real value)
          value: ordersThisMonth == '—'
              ? '—'
              : '$turnoverThisMonth с',
          label: l10n.b2bKpiTurnoverLabel,
        ),
        const SizedBox(width: 9),
        _KpiTile(
          value: l10n.b2bKpiVerifiedValue,
          label: l10n.b2bKpiSellerStatusLabel,
        ),
      ],
    );
  }
}

/// _KpiTile — single metric tile inside _KpiRow.
class _KpiTile extends StatelessWidget {
  final String value;
  final String label;

  const _KpiTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: AppColors.onAccent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8fa89c), // muted on dark — sanctioned one-off
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// _SectionHeader — section title row with "see all" link.
/// Matches demo `.b2b-sech`: title h3 + right-aligned green link.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String linkText;
  final VoidCallback? onLinkTap;

  const _SectionHeader({
    required this.title,
    required this.linkText,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Title is also tappable (same destination as the link) — the whole
        // header reads as one tappable row/chip to users, so "Заводы" alone
        // must navigate too, not just the small "Все ›" text next to it.
        GestureDetector(
          onTap: onLinkTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Onest',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onLinkTap,
          child: Text(
            linkText,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.accentHover,
            ),
          ),
        ),
      ],
    );
  }
}

/// _FactoryCategoryRow — horizontal scroller of factory-category chips
/// (Electronics / Clothing / Home & Garden, ...). Tapping one navigates to
/// WholesaleFactoriesScreen filtered to that category (real Category.id from
/// the API — no hardcoded IDs or placeholder counts).
class _FactoryCategoryRow extends ConsumerWidget {
  const _FactoryCategoryRow();

  static const Map<String, IconData> _iconsBySlug = {
    'wholesale-electronics': Icons.phone_iphone,
    'wholesale-clothing': Icons.checkroom,
    'wholesale-home': Icons.home_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(wholesaleFactoryCategoriesProvider);

    return SizedBox(
      height: 100,
      child: categoriesAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (categories) {
          if (categories.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _FactoryCategoryCard(
                icon: _iconsBySlug[category.slug] ?? Icons.factory_outlined,
                name: category.name,
                count: category.factoryCount,
                onTap: () => context.push(
                  '${AppRoutes.wholesaleFactories}'
                  '?categoryId=${Uri.encodeComponent(category.id)}'
                  '&categoryName=${Uri.encodeComponent(category.name)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// _FactoryCategoryCard — horizontal factory category card.
/// Matches demo `.fac`: icon + name + factory count.
class _FactoryCategoryCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int count;
  final VoidCallback onTap;

  const _FactoryCategoryCard({
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accentPlate,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.accentDeep, size: 18),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              l10n.b2bFactoryCount(count),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// _WholesaleProductGrid — 2-column grid of wholesale product cards.
/// Fetches from wholesaleCatalogProvider and shows up to 4 products.
class _WholesaleProductGrid extends ConsumerWidget {
  const _WholesaleProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(wholesaleCatalogProvider);

    return catalogAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        // Show up to 4 products in 2x2 grid
        final displayProducts = products.take(4).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: displayProducts.length,
            itemBuilder: (context, index) {
              final p = displayProducts[index];
              final imageUrl = p.images.isNotEmpty ? p.images.first : null;
              return WholesaleProductCard(
                productId: p.id,
                name: p.name,
                imageUrl: imageUrl,
                entryPriceTjs: p.entryPriceTjs,
                moq: p.moq,
                entryTierMinQty: p.entryTierMinQty,
                onTap: () => context.push(
                  '/wholesale/catalog/${p.id}',
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// _ChannelSwitchPill — two-segment pill (inactive "Покупатель" / active "Опт B2B").
/// Inactive segment triggers the channel-switch sheet; active segment is non-interactive.
class _ChannelSwitchPill extends StatelessWidget {
  final VoidCallback onSwitchToBuyerTap;

  const _ChannelSwitchPill({required this.onSwitchToBuyerTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inactive B2C segment — tapping switches to buyer mode
          GestureDetector(
            onTap: onSwitchToBuyerTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                l10n.b2bSwitchPillBuyerLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF9fb5aa),
                ),
              ),
            ),
          ),
          // Active B2B segment — highlighted, non-interactive
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              l10n.b2bSwitchPillWholesaleLabel,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF05140b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Channel switch bottom sheet — shared across B2bHomeScreen and B2bProfileScreen.
/// Shows confirmation with cart-preservation note (D-11).
/// On confirm: calls setChannel(targetChannel) → GoRouter refreshListenable → redirect.
Future<void> _showChannelSwitchSheet(
    BuildContext context, WidgetRef ref, String targetChannel) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final sheetL10n = AppLocalizations.of(ctx)!;
      return Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, color: AppColors.accent, size: 40),
            const SizedBox(height: AppSpace.lg),
            Text(
              targetChannel == 'b2c'
                  ? sheetL10n.switchChannelConfirmB2c
                  : sheetL10n.switchChannelConfirmB2b,
              style: Theme.of(ctx).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              sheetL10n.switchChannelCartNote,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              height: AppSpace.xxl + 20, // 52dp touch target
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(sheetL10n.switchChannelConfirmButton),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(sheetL10n.switchChannelCancel),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed == true && context.mounted) {
    try {
      await ref.read(authProvider.notifier).setChannel(targetChannel);
      // GoRouter redirect fires automatically via refreshListenable
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }
}
