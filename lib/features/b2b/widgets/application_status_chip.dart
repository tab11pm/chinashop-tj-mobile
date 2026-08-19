import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// ApplicationStatusChip — localized, token-tinted status pill for a wholesale
/// application status.
///
/// Reuses the exact 4-tone scheme from `OrderStatusChip` (neutral / progress /
/// success / danger) built from design tokens, so the app stays green-centric
/// with no off-token colors. Status → tone (UI-SPEC):
///   pending → progress, approved → success, rejected → danger,
///   suspended → neutral.
class ApplicationStatusChip extends StatelessWidget {
  final String status;

  const ApplicationStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = _resolve(l10n, status.toLowerCase());
    final c = _toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.$1,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: c.$2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.$3,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, _Tone) _resolve(AppLocalizations l10n, String s) {
    switch (s) {
      case 'pending':
        return (l10n.b2bStatusPending, _Tone.progress);
      case 'approved':
        return (l10n.b2bStatusApproved, _Tone.success);
      case 'rejected':
        return (l10n.b2bStatusRejected, _Tone.danger);
      case 'suspended':
        return (l10n.b2bStatusSuspended, _Tone.neutral);
      default:
        return (s, _Tone.neutral);
    }
  }

  /// (background, border, text)
  (Color, Color, Color) _toneColors(_Tone t) {
    switch (t) {
      case _Tone.success:
        return (
          AppColors.accentPlate,
          AppColors.accentBorder,
          AppColors.accentDeep
        );
      case _Tone.progress:
        return (
          AppColors.accent.withValues(alpha: 0.10),
          AppColors.accent.withValues(alpha: 0.30),
          AppColors.accentHover,
        );
      case _Tone.danger:
        return (
          AppColors.danger.withValues(alpha: 0.10),
          AppColors.danger.withValues(alpha: 0.30),
          AppColors.danger,
        );
      case _Tone.neutral:
        return (AppColors.bg, AppColors.line, AppColors.inkMuted);
    }
  }
}

enum _Tone { neutral, progress, success, danger }
