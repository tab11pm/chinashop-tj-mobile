import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

/// OnboardingScreen — first screen shown to unauthenticated users.
///
/// APP-01: Language selection before auth.
/// APP-02: Locale is persisted to SecureStorage via authProvider.setLocale().
///
/// Three language options: Тоҷикӣ (tg), Русский (ru), English (en).
/// On selection: writes locale to SecureStorage, then navigates to /auth.
/// M4 fix: navigation to /auth is guaranteed even if SecureStorage throws.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 96).clamp(0.0, double.infinity),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // Logo / brand
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.onAccent,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                l10n.appTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.accentDeep,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Аз Чин харид кунед · Купить из Китая · Shop from China',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.accentDeep,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 56),

              Text(
                'Забонро интихоб кунед\nВыберите язык · Select language',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Language options — painted-flag chips (CustomPaint, no emoji),
              // same pattern as profile_screen's _LanguageTile/_FlagPainter.
              _LanguageButton(
                locale: 'tg',
                label: 'Тоҷикӣ',
                sublabel: 'Tajik',
                onTap: () => _selectLocale(context, ref, 'tg'),
              ),
              const SizedBox(height: 12),
              _LanguageButton(
                locale: 'ru',
                label: 'Русский',
                sublabel: 'Russian',
                onTap: () => _selectLocale(context, ref, 'ru'),
              ),
              const SizedBox(height: 12),
              _LanguageButton(
                locale: 'en',
                label: 'English',
                sublabel: 'English',
                onTap: () => _selectLocale(context, ref, 'en'),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLocale(
    BuildContext context,
    WidgetRef ref,
    String locale,
  ) async {
    // M4 fix: wrap setLocale in try/catch so navigation always proceeds even
    // if SecureStorage throws (e.g. low-storage or permission error on device).
    try {
      await ref.read(authProvider.notifier).setLocale(locale);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric),
          ),
        );
      }
    } finally {
      // Navigate to /auth regardless of whether setLocale succeeded or threw.
      if (context.mounted) {
        context.go(AppRoutes.auth);
      }
    }
  }
}

class _LanguageButton extends StatelessWidget {
  final String locale;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.locale,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Painted-flag chip (CustomPaint, no emoji) — same pattern as
                // profile_screen's _LanguageTile leading container.
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(painter: _FlagPainter(locale)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a simple country flag for the locale (tg / ru / en) as horizontal
/// bands — no emoji, no svg dependency, renders identically everywhere.
/// Copied verbatim from profile_screen._FlagPainter (same painted-flag canon).
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
