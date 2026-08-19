import 'package:flutter/material.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../theme/app_tokens.dart';
import '../models/review_models.dart';

/// RatingHistogram — 5 tappable star-count rows (UI-SPEC C-4/D-07).
///
/// Renders rows 5..1, each: star number + 12px star glyph + a 6px-high pill
/// progress bar (track AppColors.line, fill AppColors.rating, width
/// proportional to count/max(1, totalCount)) + count text. Tapping a row
/// toggles the star filter: tapping the already-selected row clears it
/// (onSelectStar(null)); tapping a different row selects that star.
class RatingHistogram extends StatelessWidget {
  final RatingDistribution distribution;
  final int? selectedStar;
  final ValueChanged<int?> onSelectStar;

  const RatingHistogram({
    super.key,
    required this.distribution,
    required this.selectedStar,
    required this.onSelectStar,
  });

  @override
  Widget build(BuildContext context) {
    final total = distribution.totalCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 5; star >= 1; star--)
          _HistogramRow(
            star: star,
            count: distribution.countFor(star),
            total: total,
            isSelected: selectedStar == star,
            onTap: () => onSelectStar(star == selectedStar ? null : star),
          ),
      ],
    );
  }
}

class _HistogramRow extends StatelessWidget {
  const _HistogramRow({
    required this.star,
    required this.count,
    required this.total,
    required this.isSelected,
    required this.onTap,
  });

  final int star;
  final int count;
  final int total;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = count / (total > 0 ? total : 1);

    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm, vertical: AppSpace.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPlate : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              child: Text(
                '$star',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            const Icon(Icons.star_rounded, size: 12, color: AppColors.rating),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      const ColoredBox(color: AppColors.line),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: const ColoredBox(color: AppColors.rating),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              width: 28,
              child: Text(
                '$count',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
