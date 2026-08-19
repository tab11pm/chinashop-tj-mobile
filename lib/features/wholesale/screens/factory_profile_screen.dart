import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wholesale_provider.dart';
import '../screens/wholesale_locked_screen.dart' show WholesaleLockedBody;
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

/// FactoryProfileScreen — factory detail view (FCT-05, Phase 13 P2).
///
/// UI-SPEC §State Machine — Mobile: FactoryProfileScreen:
///   loading → data (name/country/description/contacts/moqRange) →
///   not found (404) → 403 → error
class FactoryProfileScreen extends ConsumerStatefulWidget {
  final String factoryId;

  const FactoryProfileScreen({super.key, required this.factoryId});

  @override
  ConsumerState<FactoryProfileScreen> createState() =>
      _FactoryProfileScreenState();
}

class _FactoryProfileScreenState extends ConsumerState<FactoryProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(factoryProfileProvider(widget.factoryId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: profileAsync.maybeWhen(
          data: (p) => Text(p.name),
          orElse: () => const Text(''),
        ),
      ),
      body: profileAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => _buildError(context, ref, err, l10n),
        data: (profile) => _buildContent(context, l10n, profile),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object err,
    AppLocalizations l10n,
  ) {
    if (err is DomainException) {
      if (err.code == 'SELLER_NOT_VERIFIED') {
        return const WholesaleLockedBody();
      }
      if (err.code == 'FACTORY_NOT_FOUND' ||
          err.code == 'NOT_FOUND') {
        return EmptyState(
          icon: Icons.factory_outlined,
          title: l10n.factoryNotFound,
        );
      }
    }
    return AppErrorWidget(
      error: err,
      onRetry: () => ref.refresh(factoryProfileProvider(widget.factoryId)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    FactoryProfile profile,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country row
          if (profile.country != null && profile.country!.isNotEmpty)
            _ProfileRow(
              label: l10n.factoryCountryLabel,
              value: profile.country!,
              theme: theme,
            ),

          // MOQ range row
          if (profile.moqMin != null) ...[
            const SizedBox(height: AppSpace.sm),
            _ProfileRow(
              label: '',
              value: profile.moqMax != null
                  ? l10n.factoryMoqRange(profile.moqMin!, profile.moqMax!)
                  : 'MOQ: ${profile.moqMin} шт.',
              theme: theme,
            ),
          ],

          // Description section (omit entirely if null/empty)
          if (profile.description != null &&
              profile.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xl),
            Text(
              l10n.factoryDescriptionLabel,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              profile.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.inkMuted,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.inkMuted,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
