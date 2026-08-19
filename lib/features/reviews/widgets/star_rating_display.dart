import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

/// StarRatingDisplay — read-only row of 5 star glyphs (UI-SPEC C-2).
///
/// Rounds [rating] to the nearest 0.5 before deciding fill state: filled
/// stars for the integer part, one half-star glyph for a 0.5 remainder
/// (only when [allowHalf] is true), empty stars otherwise. Per-review
/// ratings are integers — callers pass `allowHalf: false` there so a half
/// star glyph can never render for an individual review.
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final bool allowHalf;

  /// Optional localized semantics label (e.g. "Оценка 4.5 из 5"). Falls back
  /// to a plain, non-localized default built from [rating] when omitted —
  /// actual l10n wiring happens at the call site via AppLocalizations.
  final String? semanticLabel;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 16,
    this.allowHalf = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rounded = (rating * 2).round() / 2;
    final fullStars = rounded.floor();
    final hasHalfStar = allowHalf && (rounded - fullStars) == 0.5;

    return Semantics(
      label: semanticLabel ?? 'Оценка $rounded из 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            IconData icon;
            Color color;
            if (index < fullStars) {
              icon = Icons.star_rounded;
              color = AppColors.rating;
            } else if (index == fullStars && hasHalfStar) {
              icon = Icons.star_half_rounded;
              color = AppColors.rating;
            } else {
              icon = Icons.star_outline_rounded;
              color = AppColors.inkFaint;
            }
            return Icon(icon, size: size, color: color);
          }),
        ),
      ),
    );
  }
}
