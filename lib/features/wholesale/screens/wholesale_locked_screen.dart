import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../router/app_router.dart';

/// Reusable body for 403 / SELLER_NOT_VERIFIED.
///
/// This follows the demo Zone 4 locked storefront: dark B2B header, hidden
/// wholesale cards behind the gate, and a focused CTA card.
class WholesaleLockedBody extends StatelessWidget {
  const WholesaleLockedBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height =
            constraints.hasBoundedHeight ? constraints.maxHeight : 620.0;

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Column(
                children: [
                  const _LockedB2bHeader(),
                  Expanded(
                    child: Opacity(
                      opacity: 0.34,
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                            children: const [
                              _LockedPreviewCard(),
                              _LockedPreviewCard(),
                              _LockedPreviewCard(),
                              _LockedPreviewCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPlate,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 34,
                            color: AppColors.accentDeep,
                          ),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          l10n.wholesaleLockedTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: AppColors.ink),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          l10n.wholesaleLockedBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpace.xxl + 20,
                          child: ElevatedButton(
                            onPressed: () => context.push(AppRoutes.b2bApply),
                            child: Text(l10n.wholesaleLockedCta),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LockedB2bHeader extends StatelessWidget {
  const _LockedB2bHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.34, -1),
          end: const Alignment(0.34, 1),
          colors: [
            AppColors.b2bBand,
            Color.alphaBlend(const Color(0x51163324), AppColors.b2bBand),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child:
                const Icon(Icons.factory, size: 16, color: AppColors.b2bBand),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.b2bBandLogoLabel,
              style: const TextStyle(
                fontFamily: 'Onest',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.onAccent,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              l10n.b2bSwitchPillWholesaleLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF05140B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedPreviewCard extends StatelessWidget {
  const _LockedPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: AppColors.accentPlate,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.b2bBand,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'MOQ',
                  style: TextStyle(
                    color: AppColors.onAccent,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '--------',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '-- c',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WholesaleLockedScreen extends StatelessWidget {
  const WholesaleLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: WholesaleLockedBody()),
    );
  }
}
