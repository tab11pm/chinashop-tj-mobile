import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../router/app_router.dart';
import '../../b2b/providers/b2b_provider.dart';
import '../../b2b/widgets/application_status_chip.dart';
import '../providers/wholesale_orders_provider.dart';

/// B2bProfileScreen — profile screen for B2B shell (route: /b2b/profile).
///
/// D-06 / B2B-02:
///   Section 0 — Hero card: avatar/name/phone + edit-profile CTA (ported from B2C).
///   Section 0.5 — Stats row: orders count / addresses count (ported from B2C).
///   Section 1 — Channel: ListTile to switch back to B2C (D-10).
///   Section 2 — Application status: ApplicationStatusChip + tap to /b2b/application.
///   Section 3 — Language: identical to B2C profile_screen.dart.
///   Section 4 — Addresses: identical to B2C profile_screen.dart.
///   Section 5 — Logout: identical OutlinedButton.icon pattern.
class B2bProfileScreen extends ConsumerStatefulWidget {
  const B2bProfileScreen({super.key});

  @override
  ConsumerState<B2bProfileScreen> createState() => _B2bProfileScreenState();
}

class _B2bProfileScreenState extends ConsumerState<B2bProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchAddresses();
      // Pull the latest role (admin may have approved the application since login)
      // so the role-gated screens unlock without an app restart.
      ref.read(authProvider.notifier).refreshFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final applicationAsync = ref.watch(applicationProvider);
    final ordersCount = ref.watch(wholesaleOrdersProvider).maybeWhen(
          data: (orders) => orders.length,
          orElse: () => 0,
        );

    // Single source of truth: the real application status from the server
    // (GET /api/b2b/application). Falls back to the role hint only while the
    // request is in flight, so this screen never disagrees with the detail view.
    final appStatus = applicationAsync.maybeWhen(
      data: (app) => app?.status.toLowerCase() ?? 'pending',
      orElse: () =>
          authState.role == 'wholesale_seller' ? 'approved' : 'pending',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshFromServer();
          ref.invalidate(applicationProvider);
          await ref.read(profileProvider.notifier).fetchAddresses();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            // ----------------------------------------------------------------
            // Section 0: Hero card (ported from B2C profile_screen.dart)
            // ----------------------------------------------------------------
            _HeroCard(
              name: authState.name,
              phone: authState.phone,
              onEdit: () => context.push(AppRoutes.profileEdit),
            ),
            const SizedBox(height: AppSpace.xl), // 24dp

            // ----------------------------------------------------------------
            // Section 0.5: Stats row (orders / addresses)
            // ----------------------------------------------------------------
            Row(
              children: [
                _StatTile(
                  value: '$ordersCount',
                  label: l10n.ordersTitle,
                  onTap: () => context.go(AppRoutes.wholesaleOrders),
                ),
                const SizedBox(width: 11),
                _StatTile(
                  value: '${profileState.addresses.length}',
                  label: l10n.deliveryAddresses,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl), // 24dp

            // ----------------------------------------------------------------
            // Section 1: Channel (D-10, B2B-02)
            // ----------------------------------------------------------------
            Text(l10n.channelSectionTitle,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpace.md), // 12dp

            _TokenCard(
              child: ListTile(
                leading:
                    const Icon(Icons.swap_horiz, color: AppColors.accent),
                title: Text(l10n.switchToB2cLabel),
                subtitle: Text(l10n.switchToB2cSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.inkFaint),
                onTap: () =>
                    _showChannelSwitchSheet(context, ref, 'b2c'),
              ),
            ),

            const SizedBox(height: AppSpace.xl), // 24dp

            // ----------------------------------------------------------------
            // Section 2: B2B Application status
            // ----------------------------------------------------------------
            Text(l10n.b2bApplicationStatusTitle,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpace.md), // 12dp

            _TokenCard(
              child: ListTile(
                leading: ApplicationStatusChip(status: appStatus),
                title: Text(_applicationStatusLabel(l10n, appStatus)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.inkFaint),
                onTap: () => context.push(AppRoutes.b2bApplication),
              ),
            ),

            const SizedBox(height: AppSpace.xl), // 24dp

            // ----------------------------------------------------------------
            // Section 3: Language (identical to B2C profile_screen.dart)
            // ----------------------------------------------------------------
            Text(l10n.languageLabel, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpace.md), // 12dp
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  _LangSegment(
                    locale: 'tg',
                    label: 'Тоҷикӣ',
                    selected: authState.locale == 'tg',
                    onTap: () => _setLocale('tg'),
                  ),
                  const SizedBox(width: 4),
                  _LangSegment(
                    locale: 'ru',
                    label: 'Русский',
                    selected: authState.locale == 'ru',
                    onTap: () => _setLocale('ru'),
                  ),
                  const SizedBox(width: 4),
                  _LangSegment(
                    locale: 'en',
                    label: 'English',
                    selected: authState.locale == 'en',
                    onTap: () => _setLocale('en'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.xl), // 24dp

            // ----------------------------------------------------------------
            // Section 4: Addresses (identical to B2C profile_screen.dart)
            // ----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.deliveryAddresses,
                    style: theme.textTheme.titleLarge),
                if (profileState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.addressNew),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPlate,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add,
                              size: 14, color: AppColors.accentDeep),
                          const SizedBox(width: 4),
                          Text(
                            l10n.addAddress,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.accentDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md), // 12dp

            if (profileState.error != null)
              AppErrorWidget(
                error: profileState.error!,
                onRetry: () =>
                    ref.read(profileProvider.notifier).fetchAddresses(),
              )
            else if (profileState.addresses.isEmpty &&
                !profileState.isLoading)
              _TokenCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Text(
                    l10n.noAddressesSaved,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...profileState.addresses.map(
                (addr) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Pressable(
                    onTap: () =>
                        context.push(AppRoutes.addressEditPath(addr.id)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.accent),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addr.displayLine,
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  addr.phone,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (addr.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPlate,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.accentBorder),
                                  ),
                                  child: Text(
                                    l10n.defaultLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentDeep,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                onPressed: () =>
                                    _confirmAndDelete(context, ref, addr.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpace.xxl), // 32dp

            // ----------------------------------------------------------------
            // Section 5: Logout (identical pattern to B2C profile_screen.dart)
            // ----------------------------------------------------------------
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              icon: const Icon(Icons.logout),
              label: Text(l10n.logoutButton),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                // go_router redirect handles navigation to /onboarding
              },
            ),

            const SizedBox(height: AppSpace.xxl), // 32dp
          ],
        ),
      ),
    );
  }

  Future<void> _setLocale(String locale) async {
    try {
      await ref.read(authProvider.notifier).setLocale(locale);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.errorGeneric),
          ),
        );
      }
    }
  }

  /// Delete-confirmation gate (verbatim from addresses_screen.dart).
  Future<void> _confirmAndDelete(
      BuildContext context, WidgetRef ref, String addressId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAddressConfirmTitle),
        content: Text(l10n.deleteAddressConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.deleteConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(profileProvider.notifier).deleteAddress(addressId);
    }
  }

  String _applicationStatusLabel(
      AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.b2bStatusPending;
      case 'approved':
        return l10n.b2bStatusApproved;
      case 'rejected':
        return l10n.b2bStatusRejected;
      case 'suspended':
        return l10n.b2bStatusSuspended;
      default:
        return status;
    }
  }
}

/// Channel switch bottom sheet — shared logic (D-10).
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

/// _TokenCard — token-surface Container replacing the ad-hoc Card.
/// Mirrors the default CardTheme (AppColors.surface, AppRadii.card,
/// AppColors.line hairline border) so visuals stay identical to the bare
/// Card it replaces, while keeping the codebase free of raw Material Card.
class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      // A transparent Material sits between the cream-surface DecoratedBox and
      // any child ListTile/InkWell, so ink splashes paint on top of the surface
      // instead of being hidden behind it (ListTile asserts otherwise).
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// `.prof-lang .seg button` — single language segment (flag + label).
/// Copied verbatim from B2C profile_screen.dart (per-file duplication
/// convention already used above — no shared-widget extraction).
class _LangSegment extends StatelessWidget {
  const _LangSegment({
    required this.locale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String locale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 13,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: CustomPaint(painter: _FlagPainter(locale)),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected
                        ? const Color(0xFF05140B)
                        : AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a simple country flag for the locale (tg / ru / en) as horizontal
/// bands — no emoji, no svg dependency, renders identically everywhere.
/// Copied verbatim from profile_screen.dart (D-09 painted-flag convention).
class _FlagPainter extends CustomPainter {
  _FlagPainter(this.locale);
  final String locale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void band(double top, double bottom, Color color) {
      canvas.drawRect(
        Rect.fromLTRB(0, top * h, w, bottom * h),
        Paint()..color = color,
      );
    }

    switch (locale) {
      case 'tg': // Tajikistan: red / white(wider) / green + gold star
        band(0, 0.30, const Color(0xFFCC0000));
        band(0.30, 0.70, Colors.white);
        band(0.70, 1, const Color(0xFF006600));
        canvas.drawCircle(
          Offset(w / 2, h / 2),
          h * 0.10,
          Paint()..color = const Color(0xFFF8C300),
        );
        break;
      case 'ru': // Russia: white / blue / red
        band(0, 1 / 3, Colors.white);
        band(1 / 3, 2 / 3, const Color(0xFF0039A6));
        band(2 / 3, 1, const Color(0xFFD52B1E));
        break;
      default: // English → UK flag (simplified: blue field + red/white cross)
        band(0, 1, const Color(0xFF012169));
        final white = Paint()
          ..color = Colors.white
          ..strokeWidth = h * 0.22;
        final red = Paint()
          ..color = const Color(0xFFC8102E)
          ..strokeWidth = h * 0.12;
        // Diagonals (white then red), then the upright cross.
        canvas.drawLine(Offset.zero, Offset(w, h), white);
        canvas.drawLine(Offset(w, 0), Offset(0, h), white);
        canvas.drawLine(Offset.zero, Offset(w, h), red);
        canvas.drawLine(Offset(w, 0), Offset(0, h), red);
        canvas.drawRect(
            Rect.fromLTRB(0, h * 0.39, w, h * 0.61), Paint()..color = Colors.white);
        canvas.drawRect(
            Rect.fromLTRB(w * 0.39, 0, w * 0.61, h), Paint()..color = Colors.white);
        canvas.drawRect(
            Rect.fromLTRB(0, h * 0.44, w, h * 0.56), Paint()..color = const Color(0xFFC8102E));
        canvas.drawRect(
            Rect.fromLTRB(w * 0.44, 0, w * 0.56, h), Paint()..color = const Color(0xFFC8102E));
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.locale != locale;
}

/// `.prof-hero` — avatar + name/phone + edit button card at top of profile.
/// Copied verbatim from B2C profile_screen.dart (per-file duplication
/// convention already used above for `_LangSegment`/`_FlagPainter` — no
/// shared-widget extraction).
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.phone,
    required this.onEdit,
  });

  final String? name;
  final String? phone;
  final VoidCallback onEdit;

  /// Avatar letter: name initial → last phone digits → '?'.
  String _avatarChar() {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n.substring(0, 1).toUpperCase();
    final p = phone;
    if (p != null && p.length >= 4) {
      return p.substring(p.length - 4, p.length - 2);
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentHover],
              ),
            ),
            child: Text(
              _avatarChar(),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: AppColors.bg,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? l10n.profileAnonymous,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone!,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.accentPlate,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                l10n.profileEditCta,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.accentDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.prof-stats .s` — single stat tile. Copied verbatim from B2C
/// profile_screen.dart.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
