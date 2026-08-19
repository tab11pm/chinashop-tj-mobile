import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/b2b_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

class B2bApplicationScreen extends ConsumerWidget {
  const B2bApplicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final applicationAsync = ref.watch(applicationProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.b2bStatusTitle),
        leading: const BackButton(),
      ),
      body: applicationAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => AppErrorWidget(
          error: err,
          onRetry: () => ref.refresh(applicationProvider),
        ),
        data: (application) {
          if (application == null) {
            return EmptyState(
              icon: Icons.storefront_outlined,
              title: l10n.b2bNoApplicationTitle,
              subtitle: l10n.b2bNoApplicationBody,
              actionLabel: l10n.b2bSubmitApplication,
              onAction: () => context.push(AppRoutes.b2bApply),
            );
          }
          return _ApplicationDetail(application: application);
        },
      ),
    );
  }
}

class _ApplicationDetail extends StatelessWidget {
  const _ApplicationDetail({required this.application});

  final WholesaleApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = application.status.toLowerCase();
    final isRejected = status == 'rejected';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusPanel(
              status: status,
              title: _statusLabel(l10n, status),
              subtitle: isRejected
                  ? ((application.rejectionNote ?? '').isNotEmpty
                      ? application.rejectionNote!
                      : l10n.b2bRejectionLabel)
                  : _bodyForStatus(status, l10n),
            ),
            _DataField(
              label: l10n.b2bShopNameLabel,
              value: application.shopName,
            ),
            _DataField(label: l10n.b2bTaxIdLabel, value: application.taxId),
            _DataField(label: l10n.b2bCityLabel, value: application.city),
            if ((application.expectedVolume ?? '').isNotEmpty)
              _DataField(
                label: l10n.b2bVolumeLabel,
                value: application.expectedVolume!,
              ),
            if (isRejected) ...[
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.b2bReapply),
                  onPressed: () => context.push(AppRoutes.b2bApply),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _bodyForStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case 'approved':
        return l10n.b2bApprovedBody;
      case 'suspended':
        return l10n.b2bSuspendedBody;
      case 'pending':
      default:
        return l10n.b2bPendingBody;
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'approved':
        return l10n.b2bStatusApproved;
      case 'rejected':
        return l10n.b2bStatusRejected;
      case 'suspended':
        return l10n.b2bStatusSuspended;
      case 'pending':
      default:
        return l10n.b2bStatusPending;
    }
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.status,
    required this.title,
    required this.subtitle,
  });

  final String status;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tone(status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tone.icon, color: tone.fg, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusTone _tone(String status) {
    switch (status) {
      case 'approved':
        return const _StatusTone(
          bg: AppColors.accentPlate,
          border: AppColors.accentBorder,
          fg: AppColors.accentDeep,
          icon: Icons.check_circle_outline,
        );
      case 'rejected':
        return _StatusTone(
          bg: AppColors.danger.withValues(alpha: 0.10),
          border: AppColors.danger.withValues(alpha: 0.30),
          fg: AppColors.danger,
          icon: Icons.cancel_outlined,
        );
      case 'suspended':
        return const _StatusTone(
          bg: AppColors.bg,
          border: AppColors.line,
          fg: AppColors.inkMuted,
          icon: Icons.pause_circle_outline,
        );
      case 'pending':
      default:
        return const _StatusTone(
          bg: Color(0xFFFEF6E7),
          border: Color(0xFFFCE4B6),
          fg: Color(0xFF92400E),
          icon: Icons.hourglass_top,
        );
    }
  }
}

class _DataField extends StatelessWidget {
  const _DataField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTone {
  const _StatusTone({
    required this.bg,
    required this.border,
    required this.fg,
    required this.icon,
  });

  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;
}
