import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/catalog/screens/home_screen.dart';
import '../features/catalog/screens/catalog_screen.dart';
import '../features/catalog/screens/category_screen.dart';
import '../features/catalog/screens/product_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/cart/screens/checkout_screen.dart';
import '../features/orders/providers/orders_provider.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/order_screen.dart';
import '../features/orders/screens/pickup_code_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/address_form_screen.dart';
import '../features/profile/screens/addresses_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/b2b/screens/b2b_apply_screen.dart';
import '../features/b2b/screens/b2b_application_screen.dart';
import '../features/wholesale/screens/wholesale_catalog_screen.dart';
import '../features/wholesale/screens/wholesale_product_detail_screen.dart';
import '../features/wholesale/screens/wholesale_factories_screen.dart';
import '../features/wholesale/screens/factory_profile_screen.dart';
import '../features/wholesale/screens/wholesale_cart_screen.dart';
import '../features/wholesale/screens/wholesale_checkout_screen.dart';
import '../features/wholesale/screens/wholesale_orders_screen.dart';
import '../features/wholesale/screens/wholesale_order_detail_screen.dart';
import '../features/channel/screens/channel_choice_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/profile_bootstrap_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/payment_receipts/screens/payment_receipt_flow_screen.dart';
import '../features/payment_receipts/providers/payment_receipt_provider.dart';
import '../features/wholesale/providers/wholesale_orders_provider.dart';
import '../features/wholesale/screens/b2b_home_screen.dart';
import '../features/wholesale/screens/b2b_profile_screen.dart';
import '../features/reviews/screens/review_list_screen.dart';
import '../features/reviews/screens/review_form_screen.dart';
import '../features/reviews/screens/photo_gallery_screen.dart';
import '../features/reviews/providers/review_form_provider.dart';
import '../features/reviews/models/review_models.dart';
import 'scaffold_with_nav_bar.dart';
import 'b2b_scaffold_with_nav_bar.dart';

// Root navigator key — full-screen detail routes (product/category/order/...)
// render on this navigator so they cover the bottom nav, while each shell
// branch keeps its own navigator + back stack.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// B2B shell navigator key — must be unique from _rootNavigatorKey and from the
// B2C shell's implicit key. Using a named GlobalKey with debugLabel 'b2bShell'
// prevents the duplicate-key assert when two StatefulShellRoutes are present
// (RESEARCH.md Pitfall 3 / T-15-07).
final _b2bShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'b2bShell');

/// Typed payload passed via GoRouter `extra` to the photo gallery route
/// (`AppRoutes.photoGallery`) — mirrors `PaymentReceiptArgs`/`ReviewFormArgs`'s
/// pattern of keeping non-URL-safe/verbose data out of the path.
class PhotoGalleryArgs {
  final List<ReviewPhoto> photos;
  final int startIndex;

  const PhotoGalleryArgs({required this.photos, required this.startIndex});
}

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String profileBootstrap = '/profile-bootstrap';
  static const String profileSetup = '/profile-setup';
  static const String welcome = '/welcome';
  static const String channelChoice = '/channel-choice';
  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String category = '/category/:id';
  static const String product = '/product/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String order = '/order/:id';
  static const String pickupCode = '/order/:id/pickup-code';
  static const String notifications = '/notifications';

  // Reviews — full paginated review list for a product (Phase 24, C-4).
  // productId is not sensitive, so it lives in the URL (unlike paymentReceipt).
  static const String reviewList = '/product/:id/reviews';

  // Reviews — create/edit review form (Phase 24 Plan 03, C-7). The
  // ReviewFormArgs is passed via `extra` (like PaymentReceiptArgs) — NOT in
  // the URL, since it carries the existingReview payload for edit mode.
  static const String reviewForm = '/review-form';

  // Reviews — full-screen photo gallery (Phase 24 Plan 04, C-6). The
  // PhotoGalleryArgs is passed via `extra` — carries the full photo list
  // plus the tapped start index; not URL-safe/meaningful data.
  static const String photoGallery = '/review-photo-gallery';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String b2bApply = '/b2b/apply';
  static const String b2bApplication = '/b2b/application';
  static const String b2bHome = '/b2b/home';
  static const String b2bProfile = '/b2b/profile';
  static const String addresses = '/profile/addresses';
  static const String addressNew = '/profile/addresses/new';
  static const String addressEdit = '/profile/addresses/:id/edit';
  static const String profileEdit = '/profile/edit';

  // Wholesale routes (Phase 13 — accessed by verified sellers via direct URL)
  static const String wholesaleCatalog = '/wholesale/catalog';
  static const String wholesaleProduct = '/wholesale/catalog/:id';
  static const String wholesaleFactories = '/wholesale/factories';
  static const String wholesaleFactory = '/wholesale/factories/:id';

  // Wholesale cart/checkout/orders routes (Phase 14)
  // No router-level guard — 403/SELLER_NOT_VERIFIED handled inline by each screen.
  static const String wholesaleCart = '/wholesale/cart';
  static const String wholesaleCheckout = '/wholesale/checkout';
  static const String wholesaleOrders = '/wholesale/orders';
  static const String wholesaleOrderDetail = '/wholesale/orders/:id';

  // Payment-link + receipt upload flow (Phase 16). The PaymentInitiation is
  // passed via GoRouter `extra` (PaymentReceiptArgs) — NOT in the URL, so the
  // redirect link / paymentId never leak into a shareable path.
  static const String paymentReceipt = '/payment-receipt';

  static String categoryPath(String id) => '/category/$id';
  static String productPath(String id) => '/product/$id';
  static String orderPath(String id) => '/order/$id';
  static String pickupCodePath(String id) => '/order/$id/pickup-code';
  static String reviewListPath(String id) => '/product/$id/reviews';
  static String addressEditPath(String id) => '/profile/addresses/$id/edit';
  static String wholesaleProductPath(String id) => '/wholesale/catalog/$id';
  static String wholesaleFactoryPath(String id) => '/wholesale/factories/$id';
  static String wholesaleOrderDetailPath(String id) => '/wholesale/orders/$id';
}

// ---------------------------------------------------------------------------
// Route helpers — used by the redirect logic to classify a location.
// ---------------------------------------------------------------------------

bool _isPublicRoute(String location) {
  return location == AppRoutes.onboarding || location == AppRoutes.auth;
}

bool _isB2cRoute(String location) {
  return location == AppRoutes.home ||
      location == AppRoutes.catalog ||
      location == AppRoutes.cart ||
      location == AppRoutes.orders ||
      // Exact match only — NOT a prefix match. AppRoutes.profile ('/profile')
      // is the B2C ProfileScreen shell tab and is B2C-exclusive. But the
      // shared sub-routes /profile/addresses, /profile/addresses/new,
      // /profile/addresses/:id/edit and /profile/edit are reused as-is by
      // B2bProfileScreen (15-UI-SPEC.md §Screen4 "reuse as-is") — B2B users
      // legitimately push to those routes, so they must NOT be classified as
      // B2C-only or Condition 5 silently bounces them back to /b2b/home
      // (see debug/b2b-order-no-address-redirect.md).
      location == AppRoutes.profile ||
      location.startsWith('/category') ||
      location.startsWith('/product') ||
      location.startsWith('/order') ||
      location == AppRoutes.notifications ||
      location == AppRoutes.favorites ||
      location == AppRoutes.checkout;
}

bool _isB2bRoute(String location) {
  return location.startsWith('/b2b/') || location.startsWith('/wholesale');
}

String initialLocationForAuthState(AuthState state) {
  if (!state.isAuthenticated) return AppRoutes.onboarding;
  if (!state.profileResolved) return AppRoutes.profileBootstrap;
  if (!state.channelChosen) return AppRoutes.channelChoice;
  if (state.channel == 'b2b') return AppRoutes.b2bHome;
  return AppRoutes.home;
}

// ---------------------------------------------------------------------------
// Auth change notifier — bridges Riverpod auth state to GoRouter's
// refreshListenable so the router re-evaluates redirects without being
// recreated.  The GoRouter instance itself stays stable for the lifetime of
// the ProviderScope.
// ---------------------------------------------------------------------------

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    // Listen to authProvider and notify GoRouter whenever it changes.
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool get isAuthenticated => _ref.read(authProvider).isAuthenticated;

  bool get profileResolved => _ref.read(authProvider).profileResolved;

  /// Returns the current channel ('b2c' | 'b2b'), or null during initial load
  /// (before _initialize completes). A null channel means GoRouter should not
  /// redirect — avoids shell flash (RESEARCH.md Pitfall 1).
  String? get channel {
    final state = _ref.read(authProvider);
    // During _initialize, the state is the const default value.
    // We can't distinguish "initialised to b2c" from "still loading" purely
    // from the channel field, so we use the isLoading=false + !isAuthenticated
    // default as the "pre-init" signal. However, since _initialize sets state
    // before any UI frame renders (it runs in the constructor via unawaited),
    // the very first read can race. We treat the initial const default state
    // (isAuthenticated=false, isLoading=false) as "channel may not be loaded
    // yet" and return null only when neither token nor channel has been read.
    // The simplest correct approach: return state.channel unconditionally since
    // _initialize always populates it synchronously from SecureStorage. The
    // `channelChosen` flag is the real gate for the redirect, not nullability.
    return state.channel;
  }

  bool get channelChosen => _ref.read(authProvider).channelChosen;

  bool get needsProfileSetup => _ref.read(authProvider).needsProfileSetup;

  String? get name => _ref.read(authProvider).name;
}

// ---------------------------------------------------------------------------
// Router provider
//
// Uses keepAlive so the GoRouter instance is never disposed and recreated
// when authProvider changes.  The refreshListenable triggers redirect
// re-evaluation without rebuilding the router.
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  // Dispose the ChangeNotifier when the provider is disposed.
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocationForAuthState(ref.read(authProvider)),
    // refreshListenable triggers redirect re-evaluation when auth changes,
    // without tearing down and recreating the GoRouter instance.
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final profileResolved = authNotifier.profileResolved;
      final channel = authNotifier.channel;
      final channelChosen = authNotifier.channelChosen;
      final location = state.matchedLocation;

      // Condition 1: Not authenticated + not on a public route → onboarding.
      if (!isAuthenticated && !_isPublicRoute(location)) {
        return AppRoutes.onboarding;
      }

      // Authenticated sessions cannot render protected content until the
      // backend profile contract has been resolved.
      if (isAuthenticated && !profileResolved) {
        return location == AppRoutes.profileBootstrap
            ? null
            : AppRoutes.profileBootstrap;
      }

      // Once bootstrap resolves, leave the gate through the same profile and
      // channel decisions used by the normal authenticated flow.
      if (isAuthenticated && location == AppRoutes.profileBootstrap) {
        if (authNotifier.needsProfileSetup) return AppRoutes.profileSetup;
        if (!channelChosen) return AppRoutes.channelChoice;
        return channel == 'b2b' ? AppRoutes.b2bHome : AppRoutes.home;
      }

      // Condition 0: channel is null — _initialize still running; do not
      // redirect so GoRouter waits (prevents shell flash, Pitfall 1).
      if (channel == null) return null;

      // Condition 1.5: Authenticated + backend reports profile setup required
      //                + not already on profile-setup/welcome → profile setup.
      // Runs before channel-choice per design: phone → OTP → знакомство →
      // channel-choice/magazine.
      if (isAuthenticated &&
          authNotifier.needsProfileSetup &&
          location != AppRoutes.profileSetup &&
          location != AppRoutes.welcome) {
        return AppRoutes.profileSetup;
      }

      // Condition 1.6: Authenticated + just finished "знакомство" while sitting
      //                on /profile-setup → advance to /welcome. Without this,
      //                no other condition ever routes away from /profile-setup
      //                (it isn't a "public"/B2C/B2B route), so the screen would
      //                be a dead end after a successful submit.
      if (isAuthenticated &&
          !authNotifier.needsProfileSetup &&
          location == AppRoutes.profileSetup) {
        return AppRoutes.welcome;
      }

      // Condition 2: Authenticated + public route + channel not yet chosen
      //              → channel choice screen (shown once after first login).
      if (isAuthenticated &&
          _isPublicRoute(location) &&
          !authNotifier.needsProfileSetup &&
          !channelChosen) {
        return AppRoutes.channelChoice;
      }

      // Condition 3: Authenticated + on channel-choice screen + channelChosen
      //              + channel='b2b' → redirect to B2B home.
      if (isAuthenticated &&
          location == AppRoutes.channelChoice &&
          channelChosen &&
          channel == 'b2b') {
        return AppRoutes.b2bHome;
      }

      // Condition 4: Authenticated + public route + channelChosen + channel='b2c'
      //              → redirect to B2C home.
      if (isAuthenticated &&
          (_isPublicRoute(location) || location == AppRoutes.channelChoice) &&
          channelChosen) {
        if (channel == 'b2c') return AppRoutes.home;
        if (channel == 'b2b') return AppRoutes.b2bHome;
      }

      // Condition 5: Authenticated + B2C route + channel='b2b' → B2B home.
      if (isAuthenticated &&
          _isB2cRoute(location) &&
          channel == 'b2b' &&
          channelChosen) {
        return AppRoutes.b2bHome;
      }

      // Address forms remain shared wholesale infrastructure, but a retail
      // customer cannot open them from a direct/deep link.
      if (isAuthenticated &&
          channel == 'b2c' &&
          location.startsWith('/profile/addresses')) {
        return AppRoutes.profile;
      }

      // Condition 6: Authenticated + B2B route + channel='b2c' → B2C home.
      if (isAuthenticated && _isB2bRoute(location) && channel == 'b2c') {
        return AppRoutes.home;
      }

      return null; // no redirect
    },
    routes: [
      // ---- Public ----
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileBootstrap,
        name: 'profileBootstrap',
        builder: (context, state) => const ProfileBootstrapScreen(),
      ),

      // ---- Profile setup ("знакомство") + welcome — full-screen, outside any shell ----
      GoRoute(
        path: AppRoutes.profileSetup,
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // ---- Channel choice — full-screen, outside any shell ----
      GoRoute(
        path: AppRoutes.channelChoice,
        name: 'channelChoice',
        builder: (context, state) => const ChannelChoiceScreen(),
      ),

      // ---- B2C Authenticated shell: persistent bottom nav across 5 tabs ----
      // StatefulShellRoute.indexedStack keeps an independent Navigator (and
      // back stack) per branch, so switching tabs preserves history and the
      // bottom bar stays visible on every tab.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                name: 'catalog',
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                name: 'cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                name: 'orders',
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ---- B2B Authenticated shell: persistent bottom nav across 5 B2B tabs ----
      // Uses a unique _b2bShellNavigatorKey to avoid the duplicate-navigatorKey
      // assert (RESEARCH.md Pitfall 3 / T-15-07).
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            B2bScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _b2bShellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.b2bHome,
                name: 'b2bHome',
                builder: (context, state) => const B2bHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wholesaleCatalog,
                name: 'wholesaleCatalog',
                builder: (context, state) => const WholesaleCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wholesaleCart,
                name: 'wholesaleCart',
                builder: (context, state) => const WholesaleCartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wholesaleOrders,
                name: 'wholesaleOrders',
                builder: (context, state) => const WholesaleOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.b2bProfile,
                name: 'b2bProfile',
                builder: (context, state) => const B2bProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ---- Full-screen detail routes (pushed over the shell, with back) ----
      GoRoute(
        path: AppRoutes.category,
        name: 'category',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CategoryScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.product,
        name: 'product',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.order,
        name: 'order',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.pickupCode,
        name: 'pickupCode',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PickupCodeScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.reviewList,
        name: 'reviewList',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReviewListScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      // B2B wholesale onboarding — full-screen detail over the shell, reached
      // from Profile (back → Profile per UI-SPEC Assumption 1). The entry-point
      // trigger (channel-choice) ships in Phase 15.
      GoRoute(
        path: AppRoutes.addresses,
        name: 'addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressNew,
        name: 'addressNew',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressEdit,
        name: 'addressEdit',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final addresses = ref.read(profileProvider).addresses;
          final initial = addresses.where((a) => a.id == id).firstOrNull;
          return AddressFormScreen(addressId: id, initial: initial);
        },
      ),
      GoRoute(
        path: AppRoutes.b2bApply,
        name: 'b2bApply',
        builder: (context, state) => const B2bApplyScreen(),
      ),
      GoRoute(
        path: AppRoutes.b2bApplication,
        name: 'b2bApplication',
        builder: (context, state) => const B2bApplicationScreen(),
      ),

      // Wholesale detail routes (Phase 13/14) — full-screen, accessible from
      // B2B shell's catalog/orders branches.
      GoRoute(
        path: AppRoutes.wholesaleProduct,
        name: 'wholesaleProduct',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WholesaleProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.wholesaleFactories,
        name: 'wholesaleFactories',
        builder: (context, state) => WholesaleFactoriesScreen(
          categoryId: state.uri.queryParameters['categoryId'],
          categoryTitle: state.uri.queryParameters['categoryName'],
        ),
      ),
      GoRoute(
        path: AppRoutes.wholesaleFactory,
        name: 'wholesaleFactory',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return FactoryProfileScreen(factoryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.wholesaleCheckout,
        name: 'wholesaleCheckout',
        builder: (context, state) => const WholesaleCheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.wholesaleOrderDetail,
        name: 'wholesaleOrderDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WholesaleOrderDetailScreen(orderId: id);
        },
      ),

      // Payment-link + receipt upload flow (Phase 16). The PaymentReceiptArgs is
      // passed via `extra`; Done navigates back to the order (retail) or the
      // wholesale orders list. If args are missing (deep-link with no state),
      // fall back to home rather than crash.
      GoRoute(
        path: AppRoutes.paymentReceipt,
        name: 'paymentReceipt',
        builder: (context, state) {
          final args = state.extra;
          if (args is! PaymentReceiptArgs) {
            return const _MissingPaymentArgsScreen();
          }
          return Consumer(
            builder: (context, ref, _) => PaymentReceiptFlowScreen(
              initiation: args.initiation,
              onDone: (ctx) {
                if (args.kind == PaymentFlowKind.wholesale) {
                  ref.invalidate(wholesaleOrdersProvider);
                  ctx.go(AppRoutes.wholesaleOrders);
                } else if (args.orderId != null && args.orderId!.isNotEmpty) {
                  // Invalidate so the orders list picks up the new order,
                  // then navigate to the orders tab inside the shell.
                  ref.invalidate(ordersProvider);
                  ctx.go(AppRoutes.orders);
                } else {
                  ctx.go(AppRoutes.orders);
                }
              },
            ),
          );
        },
      ),

      // Review create/edit form (Phase 24 Plan 03). The ReviewFormArgs is
      // passed via `extra`; if args are missing (cold deep-link with no
      // state), fall back to a missing-args screen rather than crash.
      GoRoute(
        path: AppRoutes.reviewForm,
        name: 'reviewForm',
        builder: (context, state) {
          final args = state.extra;
          if (args is! ReviewFormArgs) {
            return const _MissingReviewArgsScreen();
          }
          return ReviewFormScreen(
            productId: args.productId,
            productName: args.productName,
            productImageUrl: args.productImageUrl,
            orderItemId: args.orderItemId,
            existingReview: args.existingReview,
          );
        },
      ),

      // Full-screen photo gallery (Phase 24 Plan 04, C-6). The
      // PhotoGalleryArgs is passed via `extra`; if args are missing (cold
      // deep-link with no state), fall back to a missing-args screen rather
      // than crash.
      GoRoute(
        path: AppRoutes.photoGallery,
        name: 'photoGallery',
        builder: (context, state) {
          final args = state.extra;
          if (args is! PhotoGalleryArgs) {
            return const _MissingGalleryArgsScreen();
          }
          return PhotoGalleryScreen(
            photos: args.photos,
            startIndex: args.startIndex,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

/// Shown when the payment-receipt route is reached without its PaymentReceiptArgs
/// (e.g. a cold deep-link). We never fake a payment — just send the user home.
class _MissingPaymentArgsScreen extends StatelessWidget {
  const _MissingPaymentArgsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Home'),
          ),
        ),
      ),
    );
  }
}

/// Shown when the review-form route is reached without its ReviewFormArgs
/// (e.g. a cold deep-link). We never fake a review target — just send the
/// user home.
class _MissingReviewArgsScreen extends StatelessWidget {
  const _MissingReviewArgsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Home'),
          ),
        ),
      ),
    );
  }
}

/// Shown when the photo-gallery route is reached without its
/// PhotoGalleryArgs (e.g. a cold deep-link). We never fake a photo set —
/// just send the user home.
class _MissingGalleryArgsScreen extends StatelessWidget {
  const _MissingGalleryArgsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Home'),
          ),
        ),
      ),
    );
  }
}
