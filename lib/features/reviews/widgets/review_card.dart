import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/product_card.dart' show LoadingDot;
import '../../../theme/app_tokens.dart';
import '../models/review_models.dart';
import 'star_rating_display.dart';

/// ReviewCard — full review list-item (UI-SPEC C-5).
///
/// This widget only ever receives [Review] instances sourced from
/// `reviewListProvider` (read-path), where `author` is always populated —
/// but `review.author` is still typed nullable per the shared model
/// contract, so every read here is null-safe (`review.author?.displayName`)
/// rather than a force-unwrap, so this widget cannot crash if a future
/// caller ever feeds it a write-path-sourced [Review].
///
/// No hardcoded ru/tj/en copy strings live in this file — all copy is
/// passed in as params from the screen (localized there), matching every
/// other shared widget in this codebase.
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwnReview;
  final bool isAuthenticated;
  final bool isReported;
  final int? maxLines;
  final ValueChanged<int>? onTapPhoto;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  /// Localized copy — passed by the screen (never hardcoded here).
  final String ownReviewLabel;
  final String editLabel;
  final String deleteLabel;
  final String reportLabel;
  final String changeReportLabel;
  final String reportedLabel;
  final String dateLocale;

  const ReviewCard({
    super.key,
    required this.review,
    required this.isOwnReview,
    required this.isAuthenticated,
    required this.isReported,
    this.maxLines,
    this.onTapPhoto,
    this.onEdit,
    this.onDelete,
    this.onReport,
    required this.ownReviewLabel,
    required this.editLabel,
    required this.deleteLabel,
    required this.reportLabel,
    required this.changeReportLabel,
    required this.reportedLabel,
    required this.dateLocale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showMenu = isOwnReview || isAuthenticated;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    Text(
                      review.author?.displayName ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (isOwnReview) _OwnReviewBadge(text: ownReviewLabel),
                    Text(_formattedDate(), style: theme.textTheme.bodyMedium),
                    _LanguageBadge(language: review.language),
                  ],
                ),
              ),
              if (showMenu)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: PopupMenuButton<String>(
                    icon:
                        const Icon(Icons.more_vert, color: AppColors.inkMuted),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                        case 'delete':
                          onDelete?.call();
                        case 'report':
                          onReport?.call();
                      }
                    },
                    itemBuilder: (context) {
                      if (isOwnReview) {
                        return [
                          PopupMenuItem(value: 'edit', child: Text(editLabel)),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              deleteLabel,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ];
                      }
                      return [
                        PopupMenuItem(
                          value: 'report',
                          child: Text(
                              isReported ? changeReportLabel : reportLabel),
                        ),
                      ];
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          StarRatingDisplay(
              rating: review.rating.toDouble(), size: 16, allowHalf: false),
          if (review.text != null && review.text!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              review.text!,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.ink),
            ),
          ],
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (context, index) {
                  final photo = review.photos[index];
                  return GestureDetector(
                    onTap: onTapPhoto == null ? null : () => onTapPhoto!(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: photo.url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        fadeInDuration: AppMotion.enter,
                        placeholder: (context, url) => const ColoredBox(
                          color: AppColors.bg,
                          child: LoadingDot(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (isReported) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 14, color: AppColors.inkMuted),
                const SizedBox(width: AppSpace.xs),
                Text(reportedLabel, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formattedDate() {
    final parsed = DateTime.tryParse(review.createdAt);
    if (parsed == null) return '';
    return DateFormat('d MMM yyyy', _intlDateLocale(dateLocale)).format(parsed);
  }

  String _intlDateLocale(String locale) => locale == 'tg' ? 'ru' : locale;
}

class _OwnReviewBadge extends StatelessWidget {
  const _OwnReviewBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentPlate,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: AppColors.accentDeep,
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        language.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
