import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../shared/widgets/pressable.dart';

/// ChannelChoiceScreen — shown once after first OTP verification when
/// channelChosen == false. Lets the user select B2C (retail) or B2B
/// (wholesale) channel. Skip defaults to B2C.
///
/// D-03 / B2B-01: channel choice entry point.
/// setChannel() optimistically writes SecureStorage + state → GoRouter
/// refreshListenable fires → redirect to correct shell root.
class ChannelChoiceScreen extends ConsumerStatefulWidget {
  const ChannelChoiceScreen({super.key});

  @override
  ConsumerState<ChannelChoiceScreen> createState() =>
      _ChannelChoiceScreenState();
}

class _ChannelChoiceScreenState extends ConsumerState<ChannelChoiceScreen> {
  bool _isLoading = false;

  Future<void> _selectChannel(String channel) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).setChannel(channel);
      // GoRouter redirect fires automatically via refreshListenable.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 96×96dp medallion — accent green, storefront icon, accent shadow
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.onAccent,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),

              // App title + subtitle
              Text(
                l10n.appTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.accentDeep,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.channelChoiceTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),

              // 40dp gap before prompt
              const SizedBox(height: 40),

              // Prompt text
              Text(
                l10n.channelChoiceSubtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpace.xl), // 24dp

              // B2C channel card
              _ChannelCard(
                icon: Icons.shopping_bag_outlined,
                label: l10n.channelB2cLabel,
                sublabel: l10n.channelB2cSublabel,
                highlighted: false,
                onTap: _isLoading ? () {} : () => _selectChannel('b2c'),
              ),
              const SizedBox(height: AppSpace.sm), // 8dp between cards

              // B2B channel card — highlighted option (one-accent rule)
              _ChannelCard(
                icon: Icons.business_outlined,
                label: l10n.channelB2bLabel,
                sublabel: l10n.channelB2bSublabel,
                highlighted: true,
                onTap: _isLoading ? () {} : () => _selectChannel('b2b'),
              ),

              const SizedBox(height: AppSpace.xxl), // 32dp

              // Skip button — defaults to B2C
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                )
              else
                TextButton(
                  onPressed: () => _selectChannel('b2c'),
                  child: Text(
                    l10n.channelSkip,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// _ChannelCard — Pressable token card for channel selection.
/// Pattern mirrors _LanguageButton in onboarding_screen.dart.
///
/// [highlighted] applies the accent border to the recommended (B2B) option
/// only — one-accent rule, no double accents.
class _ChannelCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool highlighted;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: highlighted ? AppColors.accentBorder : AppColors.line,
              width: highlighted ? 1.5 : 1,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, // 16dp
              vertical: AppSpace.lg, // 16dp
            ),
            child: Row(
              children: [
                // 48×48dp circular icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.accentPlate,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.accentDeep),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
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
                          fontSize: 14,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
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
