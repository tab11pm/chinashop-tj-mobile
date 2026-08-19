import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../providers/review_report_provider.dart';

/// Report bottom sheet (UI-SPEC C-8, D-15). Top-level function — there is no
/// existing modal-bottom-sheet-with-form precedent in this codebase to reuse,
/// so this is built fresh (matches `_openPhotoSourceSheet`'s
/// `showModalBottomSheet` call shape, extended with form state).
///
/// Pass [existingReport] to pre-fill category/comment for the "Изменить
/// жалобу" re-open case; submitting always upserts (never creates a
/// duplicate) per the server contract.
Future<void> showReportBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  required String reviewId,
  required String productId,
  MyReport? existingReport,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (sheetContext) => _ReportBottomSheetContent(
      reviewId: reviewId,
      productId: productId,
      existingReport: existingReport,
    ),
  );
}

class _ReportBottomSheetContent extends ConsumerStatefulWidget {
  const _ReportBottomSheetContent({
    required this.reviewId,
    required this.productId,
    this.existingReport,
  });

  final String reviewId;
  final String productId;
  final MyReport? existingReport;

  @override
  ConsumerState<_ReportBottomSheetContent> createState() =>
      _ReportBottomSheetContentState();
}

class _ReportBottomSheetContentState
    extends ConsumerState<_ReportBottomSheetContent> {
  ReviewReportCategory? _selected;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _selected = widget.existingReport?.category;
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _labelFor(AppLocalizations l10n, ReviewReportCategory category) {
    switch (category) {
      case ReviewReportCategory.spamAdvertising:
        return l10n.reportCategorySpam;
      case ReviewReportCategory.abusiveContent:
        return l10n.reportCategoryAbusive;
      case ReviewReportCategory.falseOrIrrelevant:
        return l10n.reportCategoryFalse;
      case ReviewReportCategory.inappropriatePhoto:
        return l10n.reportCategoryPhoto;
      case ReviewReportCategory.other:
        return l10n.reportCategoryOther;
    }
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null) return;
    final notifier = ref.read(reviewReportProvider.notifier);
    final comment = _commentController.text.trim();
    final ok = await notifier.submit(
      reviewId: widget.reviewId,
      category: selected,
      comment: comment.isEmpty ? null : comment,
    );

    if (!mounted) return;

    if (ok) {
      // Invalidate so the card's reported marker appears immediately.
      ref.invalidate(myReportsProvider(widget.productId));
      Navigator.pop(context);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportSubmittedToast)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final submitState = ref.watch(reviewReportProvider);
    final isSubmitting =
        submitState.status == ReviewReportSubmitStatus.submitting;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpace.lg),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Text(l10n.reportSheetTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpace.md),
              RadioGroup<ReviewReportCategory>(
                groupValue: _selected,
                onChanged: (value) => setState(() => _selected = value),
                child: Column(
                  children: [
                    for (final category in ReviewReportCategory.values)
                      SizedBox(
                        height: 48,
                        child: RadioListTile<ReviewReportCategory>(
                          value: category,
                          activeColor: AppColors.accent,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _labelFor(l10n, category),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: l10n.reportCommentHint,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_selected == null || isSubmitting) ? null : _submit,
                  child: Text(l10n.reportSubmitBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
