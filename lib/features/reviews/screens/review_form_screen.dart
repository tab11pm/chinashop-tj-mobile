import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';
import '../models/review_models.dart';
import '../providers/review_eligibility_provider.dart';
import '../providers/review_form_provider.dart';
import '../providers/review_list_provider.dart';
import '../widgets/star_rating_input.dart';

/// ReviewFormScreen — dedicated create/edit review screen (UI-SPEC C-7,
/// D-09..D-12). Local `State` owns rating/text/photos so a failed submit
/// never loses user input (D-18); [reviewFormProvider] only reports
/// submit status/result.
class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.orderItemId,
    this.existingReview,
  });

  final String productId;
  final String productName;
  final String? productImageUrl;
  final String orderItemId;
  final Review? existingReview;

  bool get isEdit => existingReview != null;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final ImagePicker _picker = ImagePicker();
  late int _rating;
  late final TextEditingController _textController;
  final List<XFile> _newPhotos = [];
  final List<ReviewPhoto> _existingPhotos = [];
  bool _photosChanged = false;
  bool _showCelebration = false;

  static const int _maxPhotos = 5;
  static const int _textMaxLength = 1000;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    _rating = existing?.rating ?? 0;
    _textController = TextEditingController(text: existing?.text ?? '');
    if (existing != null) {
      _existingPhotos.addAll(existing.photos);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _totalPhotoCount => _existingPhotos.length + _newPhotos.length;

  bool get _isDirty {
    if (!widget.isEdit) {
      return _rating != 0 ||
          _textController.text.trim().isNotEmpty ||
          _newPhotos.isNotEmpty;
    }
    final existing = widget.existingReview!;
    return _rating != existing.rating ||
        _textController.text.trim() != (existing.text ?? '') ||
        _photosChanged;
  }

  String _ratingLabel(AppLocalizations l10n, int rating) {
    switch (rating) {
      case 1:
        return l10n.reviewRatingLabel1;
      case 2:
        return l10n.reviewRatingLabel2;
      case 3:
        return l10n.reviewRatingLabel3;
      case 4:
        return l10n.reviewRatingLabel4;
      case 5:
        return l10n.reviewRatingLabel5;
      default:
        return '';
    }
  }

  Future<void> _openPhotoSourceSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final remaining = _maxPhotos - _totalPhotoCount;
    if (remaining <= 0) return;

    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.reviewPhotoSourceCamera),
              onTap: () => Navigator.pop(sheetContext, _PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.reviewPhotoSourceGallery),
              onTap: () => Navigator.pop(sheetContext, _PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    if (source == _PhotoSource.camera) {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _newPhotos.add(picked);
          _photosChanged = true;
        });
      }
    } else {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1920,
        imageQuality: 85,
        limit: _maxPhotos - _totalPhotoCount,
      );
      if (picked.isNotEmpty && mounted) {
        setState(() {
          _newPhotos.addAll(picked);
          _photosChanged = true;
        });
      }
    }
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
      _photosChanged = true;
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
      _photosChanged = true;
    });
  }

  Future<void> _submit() async {
    final notifier = ref.read(reviewFormProvider.notifier);
    final result = await notifier.submit(
      isEdit: widget.isEdit,
      reviewId: widget.existingReview?.id,
      orderItemId: widget.orderItemId,
      rating: _rating,
      text: _textController.text.trim().isEmpty
          ? null
          : _textController.text.trim(),
      photos: _newPhotos,
      photosChanged: _photosChanged,
    );

    if (!mounted) return;

    if (result != null) {
      // D-17: refresh the read-side providers (they DO populate author).
      ref.invalidate(reviewListProvider(widget.productId));
      ref.invalidate(reviewEligibilityProvider(widget.productId));
      setState(() => _showCelebration = true);
      return;
    }

    // D-18: error handling. REVIEW_ALREADY_EXISTS and REVIEW_PHOTO_INVALID
    // render dedicated inline UI (built from `formState` in build()); any
    // other code (including bare NETWORK) gets a retry snackbar here.
    final code = ref.read(reviewFormProvider).errorCode;
    if (code != 'REVIEW_ALREADY_EXISTS' &&
        code != 'REVIEW_PHOTO_INVALID' &&
        mounted) {
      final l10n = AppLocalizations.of(context)!;
      final msg = localizedError(context, code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: l10n.reviewRetryCta,
            onPressed: _submit,
          ),
        ),
      );
    }
  }

  Future<void> _handleAlreadyExists() async {
    // Per Pitfall 4: the eligibility check is the source of truth for which
    // order-item already has a review. Re-navigating directly into edit mode
    // needs that review's id, which this screen does not have on a fresh
    // REVIEW_ALREADY_EXISTS response — invalidate eligibility so the caller
    // screen (product/order) re-renders without a create CTA, then pop back
    // to let the user reach the existing review from the review list (D-04:
    // edit only from the review list).
    ref.invalidate(reviewEligibilityProvider(widget.productId));
    if (mounted) context.pop();
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reviewDiscardTitle),
        content: Text(l10n.reviewDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.reviewDiscardStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.reviewDiscardExit),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formState = ref.watch(reviewFormProvider);
    final isSubmitting = formState.status == ReviewFormStatus.submitting;
    final errorCode =
        formState.status == ReviewFormStatus.error ? formState.errorCode : null;
    final textLength = _textController.text.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _confirmDiscard();
        if (canPop && context.mounted) context.pop();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              title: Text(
                widget.isEdit
                    ? l10n.reviewFormTitleEdit
                    : l10n.reviewFormTitleCreate,
              ),
              leading: const BackButton(),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Product header ──────────────────────────
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: widget.productImageUrl != null &&
                                          widget.productImageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: widget.productImageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const ColoredBox(
                                                  color: AppColors.bg),
                                          errorWidget: (_, __, ___) =>
                                              const ColoredBox(
                                            color: AppColors.accentPlate,
                                          ),
                                        )
                                      : const ColoredBox(
                                          color: AppColors.accentPlate),
                                ),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Text(
                                  widget.productName,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.xl),

                          // ── Star input ───────────────────────────────
                          StarRatingInput(
                            value: _rating,
                            onChanged: (v) => setState(() => _rating = v),
                          ),
                          if (_rating > 0) ...[
                            const SizedBox(height: AppSpace.xs),
                            Center(
                              child: Text(
                                _ratingLabel(l10n, _rating),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.inkMuted),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpace.xl),

                          // ── Text field ───────────────────────────────
                          TextField(
                            controller: _textController,
                            minLines: 4,
                            maxLines: 8,
                            maxLength: _textMaxLength,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: l10n.reviewTextHint,
                              counterText: textLength >= 900
                                  ? '$textLength/$_textMaxLength'
                                  : '',
                              counterStyle: TextStyle(
                                color: textLength >= _textMaxLength
                                    ? AppColors.danger
                                    : AppColors.inkFaint,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpace.xl),

                          // ── Photo block ──────────────────────────────
                          Container(
                            padding: errorCode == 'REVIEW_PHOTO_INVALID'
                                ? const EdgeInsets.all(AppSpace.sm)
                                : EdgeInsets.zero,
                            decoration: errorCode == 'REVIEW_PHOTO_INVALID'
                                ? BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.danger, width: 1.5),
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.control),
                                  )
                                : null,
                            child: Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.sm,
                              children: [
                                for (var i = 0; i < _existingPhotos.length; i++)
                                  _PhotoTile(
                                    imageUrl: _existingPhotos[i].url,
                                    onRemove: () => _removeExistingPhoto(i),
                                  ),
                                for (var i = 0; i < _newPhotos.length; i++)
                                  _PhotoTile(
                                    filePath: _newPhotos[i].path,
                                    onRemove: () => _removeNewPhoto(i),
                                  ),
                                if (_totalPhotoCount < _maxPhotos)
                                  _AddPhotoTile(onTap: _openPhotoSourceSheet),
                              ],
                            ),
                          ),
                          if (errorCode == 'REVIEW_PHOTO_INVALID') ...[
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              l10n.errReviewPhotoInvalid,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.danger),
                            ),
                          ],
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            l10n.reviewPhotoHelper,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkFaint),
                          ),

                          if (errorCode == 'REVIEW_ALREADY_EXISTS') ...[
                            const SizedBox(height: AppSpace.lg),
                            _AlreadyExistsBanner(
                              l10n: l10n,
                              theme: theme,
                              onOpenExisting: _handleAlreadyExists,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Submit bar ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSubmitting) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            l10n.reviewSubmitting,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpace.sm),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_rating == 0 || isSubmitting)
                                ? null
                                : _submit,
                            child: Text(l10n.reviewSubmitCta),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCelebration)
            _ReviewCelebration(
              onDismissed: () {
                if (mounted) {
                  context.pop();
                }
              },
            ),
        ],
      ),
    );
  }
}

enum _PhotoSource { camera, gallery }

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({this.imageUrl, this.filePath, required this.onRemove});

  final String? imageUrl;
  final String? filePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                  : Image.file(File(filePath!), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            size: 22, color: AppColors.inkMuted),
      ),
    );
  }
}

class _AlreadyExistsBanner extends StatelessWidget {
  const _AlreadyExistsBanner({
    required this.l10n,
    required this.theme,
    required this.onOpenExisting,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onOpenExisting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.errReviewAlreadyExists,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            onPressed: onOpenExisting,
            child: Text(l10n.reviewOpenExistingCta),
          ),
        ],
      ),
    );
  }
}

/// Static celebration overlay for a successful review submit (UI-SPEC C-9).
/// Re-themed sibling of `DeliveredCelebration` (star icon, amber plate) — a
/// separate widget rather than adding params to `DeliveredCelebration` to
/// keep that widget's existing `delivered` call site untouched.
class _ReviewCelebration extends StatefulWidget {
  const _ReviewCelebration({required this.onDismissed});

  final VoidCallback onDismissed;

  /// Matches `DeliveredCelebration`'s default auto-dismiss duration.
  static const _dismissDelay = Duration(milliseconds: 2500);

  @override
  State<_ReviewCelebration> createState() => _ReviewCelebrationState();
}

class _ReviewCelebrationState extends State<_ReviewCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    Future.delayed(_ReviewCelebration._dismissDelay, () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = CurvedAnimation(parent: _ctrl, curve: AppMotion.curveStrong);
    final fade = CurvedAnimation(parent: _ctrl, curve: AppMotion.curve);

    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(scale),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.accentBorder),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPlate,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.rating,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Text(
                    l10n.reviewSubmitCelebrationTitle,
                    style: const TextStyle(
                      fontFamily: 'Onest',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
