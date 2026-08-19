import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_tokens.dart';
import '../l10n/app_localizations.dart';
import '../features/catalog/providers/catalog_provider.dart';
import '../features/cart/providers/cart_provider.dart';
import '../features/orders/providers/orders_provider.dart';
import '../features/profile/providers/profile_provider.dart';

/// ScaffoldWithNavBar — the shell for the five primary tabs.
///
/// Hosts a persistent [BottomNavigationBar] that stays visible across
/// home / catalog / cart / orders / profile, and renders the active branch's
/// navigator as the body. Each branch keeps its own independent back stack
/// (StatefulShellRoute.indexedStack).
///
/// Because indexedStack keeps every branch alive, a screen's `initState` (which
/// loads its data) runs only once. So on each tab switch we refetch the
/// destination tab's data — otherwise tabs show stale data from first load.
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  /// The navigation shell + indexed-stack of the five branch navigators.
  final StatefulNavigationShell navigationShell;

  void _onTap(WidgetRef ref, int index) {
    // Tapping the active tab again resets it to its initial location;
    // tapping a different tab switches to it preserving its stack.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    _refreshTab(ref, index);
  }

  /// Fetch fresh data for the tab the user just switched to.
  void _refreshTab(WidgetRef ref, int index) {
    switch (index) {
      case 0: // home
        ref.read(catalogProvider.notifier).fetchProducts(page: 1);
        ref.read(catalogProvider.notifier).fetchCategories();
        break;
      case 1: // catalog
        ref.read(catalogProvider.notifier).fetchProducts(page: 1);
        break;
      case 2: // cart
        ref.read(cartProvider.notifier).fetchCart();
        break;
      case 3: // orders
        ref.read(ordersProvider.notifier).fetchOrders();
        break;
      case 4: // profile
        ref.read(profileProvider.notifier).fetchAddresses();
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = navigationShell.currentIndex;

    // Custom .m-nav footer: cream surface, hairline top border, active tab
    // shows the icon inside a green-soft rounded plate + green-hover label.
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: l10n.homeTitle,
                  selected: current == 0,
                  onTap: () => _onTap(ref, 0),
                ),
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  label: l10n.catalogTitle,
                  selected: current == 1,
                  onTap: () => _onTap(ref, 1),
                ),
                _NavItem(
                  icon: Icons.shopping_cart_outlined,
                  label: l10n.cartTitle,
                  selected: current == 2,
                  onTap: () => _onTap(ref, 2),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.ordersTitle,
                  selected: current == 3,
                  onTap: () => _onTap(ref, 3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: l10n.profileTitle,
                  selected: current == 4,
                  onTap: () => _onTap(ref, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.m-nav a` — single bottom-nav tab: icon (in a green-soft plate when
/// active) above a small label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentHover : AppColors.inkMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accentPlate : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
