import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_tokens.dart';
import '../l10n/app_localizations.dart';
import '../features/wholesale/providers/wholesale_provider.dart';
import '../features/wholesale/providers/wholesale_cart_provider.dart';
import '../features/wholesale/providers/wholesale_orders_provider.dart';
import '../features/profile/providers/profile_provider.dart';

/// B2bScaffoldWithNavBar — the shell for the five B2B primary tabs.
///
/// Hosts a persistent [BottomNavigationBar] that stays visible across
/// b2b-home / wholesale-catalog / wholesale-cart / wholesale-orders / b2b-profile,
/// and renders the active branch's navigator as the body. Each branch keeps its
/// own independent back stack (StatefulShellRoute.indexedStack).
///
/// On each tab switch, refreshes the destination tab's data so stale state is
/// not shown from first load.
class B2bScaffoldWithNavBar extends ConsumerWidget {
  const B2bScaffoldWithNavBar({super.key, required this.navigationShell});

  /// The navigation shell + indexed-stack of the five branch navigators.
  final StatefulNavigationShell navigationShell;

  void _onTap(WidgetRef ref, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    _refreshTab(ref, index);
  }

  /// Fetch fresh data for the tab the user just switched to.
  void _refreshTab(WidgetRef ref, int index) {
    switch (index) {
      case 0: // b2b home — no extra fetch needed
        break;
      case 1: // wholesale catalog
        ref.read(wholesaleCatalogProvider.notifier).fetch();
        break;
      case 2: // wholesale cart
        ref.read(wholesaleCartProvider.notifier).fetchCart();
        break;
      case 3: // wholesale orders
        ref.read(wholesaleOrdersProvider.notifier).fetchOrders();
        break;
      case 4: // b2b profile
        ref.read(profileProvider.notifier).fetchAddresses();
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.inkFaint,
        onTap: (index) => _onTap(ref, index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: l10n.b2bNavHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.factory_outlined),
            activeIcon: const Icon(Icons.factory),
            label: l10n.b2bNavCatalog,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_basket_outlined),
            activeIcon: const Icon(Icons.shopping_basket),
            label: l10n.b2bNavCart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: l10n.b2bNavOrders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.b2bNavProfile,
          ),
        ],
      ),
    );
  }
}
