// Unit tests for the GoRouter redirect logic defined in app_router.dart.
//
// The redirect function reads from _AuthChangeNotifier getters (isAuthenticated,
// channel, channelChosen). We test the pure logic by reproducing the same
// conditions with a FakeAuthChangeNotifier that carries configurable state.
//
// Tests cover the 6 redirect conditions from UI-SPEC §Redirect conditions
// (B2B-08) plus the pre-init null-channel case (Pitfall 1).

import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/router/app_router.dart';

// ---------------------------------------------------------------------------
// Internal redirect helpers (mirror of app_router.dart private functions)
// These are extracted here since the private helpers are not exported.
// We reproduce the redirect logic inline to test all 6 conditions.
// ---------------------------------------------------------------------------

typedef RedirectResult = String?;

/// A simplified version of the redirect function that takes configurable
/// auth parameters — mirrors the logic in app_router.dart's redirect.
RedirectResult testRedirect({
  required bool isAuthenticated,
  bool profileResolved = true,
  required String? channel, // null = pre-init
  required bool channelChosen,
  required String location,
  bool needsProfileSetup = false,
}) {
  // Public routes
  bool isPublicRoute(String l) => l == '/onboarding' || l == '/auth';
  bool isB2cRoute(String l) =>
      l == '/home' ||
      l == '/catalog' ||
      l == '/cart' ||
      l == '/orders' ||
      // Exact match only — the shared /profile/addresses*, /profile/edit
      // sub-routes are reused as-is by the B2B profile screen (15-UI-SPEC.md
      // §Screen4) and must stay reachable regardless of channel. Only the
      // B2C ProfileScreen shell tab itself ('/profile') is B2C-exclusive.
      // See debug/resolved/b2b-order-no-address-redirect.md.
      l == '/profile' ||
      l.startsWith('/category') ||
      l.startsWith('/product') ||
      l.startsWith('/order') ||
      l == '/favorites' ||
      l == '/checkout';
  bool isB2bRoute(String l) =>
      l.startsWith('/b2b/') || l.startsWith('/wholesale');

  if (!isAuthenticated && !isPublicRoute(location)) {
    return '/onboarding';
  }

  if (isAuthenticated && !profileResolved) {
    return location == '/profile-bootstrap' ? null : '/profile-bootstrap';
  }

  if (isAuthenticated && location == '/profile-bootstrap') {
    if (needsProfileSetup) return '/profile-setup';
    if (!channelChosen) return '/channel-choice';
    return channel == 'b2b' ? '/b2b/home' : '/home';
  }

  // Condition 0: channel is null (pre-init) → no redirect
  if (channel == null) return null;

  // Condition 1.5
  if (isAuthenticated &&
      needsProfileSetup &&
      location != '/profile-setup' &&
      location != '/welcome') {
    return '/profile-setup';
  }

  // Condition 1.6
  if (isAuthenticated && !needsProfileSetup && location == '/profile-setup') {
    return '/welcome';
  }

  // Condition 2
  if (isAuthenticated &&
      isPublicRoute(location) &&
      !needsProfileSetup &&
      !channelChosen) {
    return '/channel-choice';
  }

  // Condition 3
  if (isAuthenticated &&
      location == '/channel-choice' &&
      channelChosen &&
      channel == 'b2b') {
    return '/b2b/home';
  }

  // Condition 4
  if (isAuthenticated &&
      (isPublicRoute(location) || location == '/channel-choice') &&
      channelChosen) {
    if (channel == 'b2c') return '/home';
    if (channel == 'b2b') return '/b2b/home';
  }

  // Condition 5
  if (isAuthenticated &&
      isB2cRoute(location) &&
      channel == 'b2b' &&
      channelChosen) {
    return '/b2b/home';
  }

  if (isAuthenticated &&
      channel == 'b2c' &&
      location.startsWith('/profile/addresses')) {
    return '/profile';
  }

  // Condition 6
  if (isAuthenticated && isB2bRoute(location) && channel == 'b2c') {
    return '/home';
  }

  return null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('redirect conditions', () {
    test('condition 1.5: authenticated + incomplete profile routes to setup',
        () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: false,
        location: '/home',
        needsProfileSetup: true,
      );
      expect(result, '/profile-setup');
    });

    test('authenticated unresolved state is gated on profile bootstrap', () {
      final result = testRedirect(
        isAuthenticated: true,
        profileResolved: false,
        channel: 'b2c',
        channelChosen: true,
        location: '/home',
      );

      expect(result, '/profile-bootstrap');
    });

    test('resolved bootstrap exits through existing auth destinations', () {
      expect(
        testRedirect(
          isAuthenticated: true,
          channel: 'b2c',
          channelChosen: false,
          location: '/profile-bootstrap',
        ),
        '/channel-choice',
      );
      expect(
        testRedirect(
          isAuthenticated: true,
          channel: 'b2c',
          channelChosen: true,
          location: '/profile-bootstrap',
          needsProfileSetup: true,
        ),
        '/profile-setup',
      );
      expect(
        testRedirect(
          isAuthenticated: true,
          channel: 'b2b',
          channelChosen: true,
          location: '/profile-bootstrap',
        ),
        '/b2b/home',
      );
    });

    test('condition 1.6: completed setup advances to welcome screen', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: false,
        location: '/profile-setup',
      );
      expect(result, '/welcome');
    });

    // Condition 1 — unauthenticated on a non-public route → /onboarding
    test('condition 1: unauthenticated + non-public → /onboarding', () {
      final result = testRedirect(
        isAuthenticated: false,
        channel: 'b2c',
        channelChosen: false,
        location: '/home',
      );
      expect(result, '/onboarding');
    });

    // Condition 2 — authenticated + public + !channelChosen → /channel-choice
    test(
        'condition 2: authenticated + public + !channelChosen → /channel-choice',
        () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: false,
        location: '/onboarding',
      );
      expect(result, '/channel-choice');
    });

    // Condition 3 — authenticated + /channel-choice + channelChosen + b2b → /b2b/home
    test('condition 3: auth + channel-choice + channelChosen + b2b → /b2b/home',
        () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2b',
        channelChosen: true,
        location: '/channel-choice',
      );
      expect(result, '/b2b/home');
    });

    // Condition 4a — authenticated + public + channelChosen + b2c → /home
    test('condition 4a: auth + public + channelChosen + b2c → /home', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: true,
        location: '/onboarding',
      );
      expect(result, '/home');
    });

    // Condition 5 — authenticated + B2C route + b2b channel → /b2b/home
    test('condition 5: auth + B2C route + channel=b2b → /b2b/home', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2b',
        channelChosen: true,
        location: '/home',
      );
      expect(result, '/b2b/home');
    });

    // Regression test for b2b-order-no-address-redirect: the shared
    // /profile/addresses* and /profile/edit routes are reused by the B2B
    // profile screen (B2bProfileScreen pushes to these exact routes), so a
    // b2b-channel user must NOT be bounced away from them.
    test(
        'condition 5: auth + shared /profile sub-route + channel=b2b → no redirect',
        () {
      for (final loc in const [
        '/profile/addresses',
        '/profile/addresses/new',
        '/profile/addresses/abc123/edit',
        '/profile/edit',
      ]) {
        final result = testRedirect(
          isAuthenticated: true,
          channel: 'b2b',
          channelChosen: true,
          location: loc,
        );
        expect(result, isNull,
            reason: 'b2b user on shared route $loc must NOT be redirected');
      }
    });

    test('retail users cannot deep-link to legacy address creation', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: true,
        location: '/profile/addresses/new',
      );
      expect(result, '/profile');
    });

    // The exact B2C ProfileScreen shell tab itself remains B2C-exclusive.
    test('condition 5: auth + exact /profile + channel=b2b → /b2b/home', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2b',
        channelChosen: true,
        location: '/profile',
      );
      expect(result, '/b2b/home');
    });

    // Condition 6 — authenticated + B2B route + b2c channel → /home
    test('condition 6: auth + B2B route + channel=b2c → /home', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: true,
        location: '/b2b/home',
      );
      expect(result, '/home');
    });

    test('unauthenticated pre-init protected route goes to onboarding', () {
      final result = testRedirect(
        isAuthenticated: false,
        channel: null,
        channelChosen: false,
        location: '/home',
      );
      expect(result, '/onboarding');
    });

    // Authenticated on /home with b2c + channelChosen → no redirect
    test('happy path: auth + /home + b2c + channelChosen → null', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: true,
        location: '/home',
      );
      expect(result, isNull);
    });

    // Authenticated on /b2b/home with b2b + channelChosen → no redirect
    test('happy path: auth + /b2b/home + b2b + channelChosen → null', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2b',
        channelChosen: true,
        location: '/b2b/home',
      );
      expect(result, isNull);
    });

    test('happy path: auth + /b2b/apply + b2b + channelChosen → null', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2b',
        channelChosen: true,
        location: '/b2b/apply',
      );
      expect(result, isNull);
    });

    test('happy path: auth + /wholesale/catalog + b2b + channelChosen → null',
        () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2b',
        channelChosen: true,
        location: '/wholesale/catalog',
      );
      expect(result, isNull);
    });

    test('auth + /b2b/apply + b2c → /home', () {
      final result = testRedirect(
        isAuthenticated: true,
        channel: 'b2c',
        channelChosen: true,
        location: '/b2b/apply',
      );
      expect(result, '/home');
    });
  });

  // Verify AppRoutes constants referenced in redirect conditions
  group('AppRoutes constants', () {
    test('channelChoice is /channel-choice', () {
      expect(AppRoutes.channelChoice, '/channel-choice');
    });

    test('b2bHome is /b2b/home', () {
      expect(AppRoutes.b2bHome, '/b2b/home');
    });

    test('b2bProfile is /b2b/profile', () {
      expect(AppRoutes.b2bProfile, '/b2b/profile');
    });
  });

  group('initial route', () {
    test('authenticated b2c user starts on home, not onboarding', () {
      final route = initialLocationForAuthState(
        const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          channel: 'b2c',
          channelChosen: true,
        ),
      );

      expect(route, AppRoutes.home);
    });

    test('authenticated unresolved user starts on profile bootstrap', () {
      final route = initialLocationForAuthState(
        const AuthState(
          isAuthenticated: true,
          profileResolved: false,
          channel: 'b2c',
          channelChosen: true,
        ),
      );

      expect(route, '/profile-bootstrap');
    });

    test('unauthenticated user starts on onboarding', () {
      final route = initialLocationForAuthState(
        const AuthState(profileResolved: true),
      );

      expect(route, AppRoutes.onboarding);
    });
  });
}
