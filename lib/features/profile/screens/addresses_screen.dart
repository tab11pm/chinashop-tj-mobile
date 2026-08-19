import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../router/app_router.dart';

/// AddressesScreen — dedicated list screen for delivery addresses.
///
/// Layout: Scaffold + AppBar («Адреса доставки») + RefreshIndicator + ListView.
/// The list header contains a «+ Добавить адрес» pill (D-05).
/// The body renders a state-ladder: error → empty → cream address cards (D-06).
/// Lifecycle: fetchAddresses() on initState + pull-to-refresh (D-08).
/// Data: existing profileProvider — no new provider (D-07).
///
/// APP-03: GET/POST/PATCH/DELETE /api/users/addresses (unchanged backend).
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.deliveryAddresses),
        leading: const BackButton(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileProvider.notifier).fetchAddresses(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            // ----- «+ Добавить адрес» pill (D-05) -----
            // Transferred verbatim from profile_screen.dart:215-242.
            if (profileState.isLoading)
              const SizedBox(
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

            const SizedBox(height: 12),

            // ----- State-ladder (D-06) -----
            if (profileState.error != null)
              AppErrorWidget(
                error: profileState.error!,
                onRetry: () =>
                    ref.read(profileProvider.notifier).fetchAddresses(),
              )
            else if (profileState.addresses.isEmpty && !profileState.isLoading)
              EmptyState(
                icon: Icons.location_on_outlined,
                title: l10n.noAddressesSaved,
                actionLabel: l10n.addFirstAddressCta,
                onAction: () => context.push(AppRoutes.addressNew),
              )
            else
              // ----- Cream address cards (verbatim from profile_screen.dart:305-377) -----
              Column(
                children: profileState.addresses
                    .map(
                      (addr) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Delete-confirmation gate (verbatim from profile_screen.dart:453-479).
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
}
