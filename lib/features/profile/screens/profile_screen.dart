import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../router/app_router.dart';

/// ProfileScreen — language selection, stats, quick menu, and logout.
///
/// Layout follows the master demo profile (`.prof-*`): a cream header, a
/// horizontal language segment, a stats row (orders / favorites), a grouped
/// menu list, and
/// a bordered logout button.
///
/// APP-02 + APP-03:
///   Language: authProvider.setLocale(locale) → SecureStorage
///   Logout: authProvider.logout() → go_router redirects to /onboarding
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pull fresh name/phone/channel/role so the hero card and the edit form
      // pre-populate even right after an OTP login (when _initialize's refresh
      // didn't run because there was no token yet).
      ref.read(authProvider.notifier).refreshFromServer();
      // Load counts for the stats row (orders / favorites).
      ref.read(ordersProvider.notifier).fetchOrders();
      ref.read(favoritesProvider.notifier).fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final ordersCount = ref.watch(ordersProvider).orders.length;
    final favoritesCount = ref.watch(favoritesProvider).favorites.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(authProvider.notifier).refreshFromServer(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: Text(
                  l10n.profileTitle,
                  style: const TextStyle(
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: AppColors.ink,
                  ),
                ),
              ),

              // ----- Hero card (.prof-hero) -----
              const SizedBox(height: 12),
              _HeroCard(
                name: authState.name,
                phone: authState.phone,
                onEdit: () => context.push(AppRoutes.profileEdit),
              ),

              // ----- Language segment (.prof-lang) -----
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.languageLabel.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.4,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 7),
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
                  ],
                ),
              ),

              // ----- Stats row (.prof-stats) -----
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(
                  children: [
                    _StatTile(
                      value: '$ordersCount',
                      label: l10n.ordersTitle,
                      onTap: () => context.push(AppRoutes.orders),
                    ),
                    const SizedBox(width: 11),
                    _StatTile(
                      value: '$favoritesCount',
                      label: l10n.favoritesTitle,
                      onTap: () => context.push(AppRoutes.favorites),
                    ),
                  ],
                ),
              ),

              // ----- Quick menu (.prof-menu) -----
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: _MenuGroup(
                  children: [
                    _MenuRow(
                      icon: Icons.receipt_long_outlined,
                      label: l10n.ordersTitle,
                      onTap: () => context.push(AppRoutes.orders),
                    ),
                    _MenuRow(
                      icon: Icons.favorite_border,
                      label: l10n.favoritesTitle,
                      onTap: () => context.push(AppRoutes.favorites),
                    ),
                    _MenuRow(
                      icon: Icons.notifications_none,
                      label: l10n.notificationsTitle,
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    _MenuRow(
                      icon: Icons.business_outlined,
                      label: l10n.profileWholesaleMenuLabel,
                      tag: l10n.wholesaleLockedCta,
                      onTap: () => _showChannelSwitchSheet(context, ref, 'b2b'),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // ----- Logout (.prof-logout) -----
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: GestureDetector(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      l10n.logoutButton,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Channel switch bottom sheet — D-10 / B2B-02 symmetric entry from B2C.
  Future<void> _showChannelSwitchSheet(
      BuildContext context, WidgetRef ref, String targetChannel) async {
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
                height: AppSpace.xxl + 20,
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
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
          );
        }
      }
    }
  }

  Future<void> _setLocale(String locale) async {
    try {
      await ref.read(authProvider.notifier).setLocale(locale);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }
}

/// `.prof-lang .seg button` — single language segment (flag + label).
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
                    color:
                        selected ? const Color(0xFF05140B) : AppColors.inkMuted,
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

/// `.prof-stats .s` — single stat tile.
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

/// `.prof-hero` — avatar + name/phone + edit button card at top of profile.
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
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
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

/// `.prof-menu` — grouped menu card.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// `.prof-menu a` — single menu row (icon · label · chevron|tag).
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tag,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tag;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: AppColors.ink),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (tag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentPlate,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  tag!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    color: AppColors.accentDeep,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Draws a simple country flag for the locale (tg / ru / en) as horizontal
/// bands — no emoji, no svg dependency, renders identically everywhere.
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
        canvas.drawLine(Offset.zero, Offset(w, h), white);
        canvas.drawLine(Offset(w, 0), Offset(0, h), white);
        canvas.drawLine(Offset.zero, Offset(w, h), red);
        canvas.drawLine(Offset(w, 0), Offset(0, h), red);
        canvas.drawRect(Rect.fromLTRB(0, h * 0.39, w, h * 0.61),
            Paint()..color = Colors.white);
        canvas.drawRect(Rect.fromLTRB(w * 0.39, 0, w * 0.61, h),
            Paint()..color = Colors.white);
        canvas.drawRect(Rect.fromLTRB(0, h * 0.44, w, h * 0.56),
            Paint()..color = const Color(0xFFC8102E));
        canvas.drawRect(Rect.fromLTRB(w * 0.44, 0, w * 0.56, h),
            Paint()..color = const Color(0xFFC8102E));
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.locale != locale;
}
