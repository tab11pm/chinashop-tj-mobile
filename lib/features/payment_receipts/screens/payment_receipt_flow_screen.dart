import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';
import '../../../shared/widgets/price_tag.dart';
import '../providers/payment_receipt_provider.dart';

/// PaymentReceiptFlowScreen — reusable retail + wholesale payment-link + receipt
/// upload UI (PAYLINK-03).
///
/// Flow (the order is the whole point):
///   1. Show the amount + an "Open payment link" button (launchUrl externally).
///   2. Make it EXPLICIT that opening the link is NOT payment confirmation —
///      the receipt upload is the next required step.
///   3. Let the user pick/take a receipt image → multipart upload → status.
///   4. On success the receipt is "awaiting review"; only then offer the
///      [onDone] CTA (retail → order screen, wholesale → wholesale orders).
///
/// The [initiation] carries the pay.dc.tj redirectUrl + paymentId. No secrets
/// (phone/token) are placed in the route — the redirect link comes only from the
/// backend (threat_model: "Mobile route leaks sensitive data").
class PaymentReceiptFlowScreen extends ConsumerStatefulWidget {
  const PaymentReceiptFlowScreen({
    super.key,
    required this.initiation,
    required this.onDone,
  });

  final PaymentInitiation initiation;

  /// Called after the receipt upload succeeds, when the user taps Done. Wholesale
  /// and retail pass different navigation targets here.
  final void Function(BuildContext context) onDone;

  @override
  ConsumerState<PaymentReceiptFlowScreen> createState() =>
      _PaymentReceiptFlowScreenState();
}

class _PaymentReceiptFlowScreenState
    extends ConsumerState<PaymentReceiptFlowScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _linkOpened = false;
  String? _localError; // launchUrl / no-link error (separate from upload error)

  Future<void> _openPaymentLink() async {
    final l10n = AppLocalizations.of(context)!;
    final url = widget.initiation.redirectUrl;
    if (url == null || url.trim().isEmpty) {
      setState(() => _localError = l10n.paymentNoLinkError);
      return;
    }
    setState(() => _localError = null);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      setState(() => _localError = l10n.paymentLinkOpenFailed);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (ok) {
      // Opening the link is NOT confirmation — we only unlock the receipt step.
      setState(() => _linkOpened = true);
    } else {
      setState(() => _localError = l10n.paymentLinkOpenFailed);
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    setState(() => _localError = null);
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return; // user cancelled
    await ref.read(paymentReceiptProvider.notifier).uploadReceipt(
          paymentId: widget.initiation.paymentId,
          filePath: picked.path,
          fileName: picked.name,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uploadState = ref.watch(paymentReceiptProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentReceiptTitle),
        leading: const BackButton(),
      ),
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount ───────────────────────────────────────────────
            Text(
              l10n.paymentAmountLabel,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpace.xs),
            // Money is a string from the API — do NOT double.parse (D-07).
            // Ink Nunito-900, currency 'с' (сомони) — never green.
            PriceTag(
              value: widget.initiation.amountTjs,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // ── Step 1: open the payment link ────────────────────────
            _OpenLinkCard(
              theme: theme,
              l10n: l10n,
              linkOpened: _linkOpened,
              onOpen: _openPaymentLink,
            ),

            const SizedBox(height: AppSpace.lg),

            // ── Step 2: upload the receipt ───────────────────────────
            _ReceiptStep(
              theme: theme,
              l10n: l10n,
              state: uploadState,
              onPickGallery: () => _pickReceipt(ImageSource.gallery),
              onTakePhoto: () => _pickReceipt(ImageSource.camera),
              onRetry: () => ref.read(paymentReceiptProvider.notifier).reset(),
              onDone: () => widget.onDone(context),
            ),

            // ── Local (link/no-link) error ───────────────────────────
            if (_localError != null) ...[
              const SizedBox(height: AppSpace.lg),
              _ErrorBanner(theme: theme, message: _localError!),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 card — open link + the "this is NOT confirmation" note.
// ---------------------------------------------------------------------------

class _OpenLinkCard extends StatelessWidget {
  const _OpenLinkCard({
    required this.theme,
    required this.l10n,
    required this.linkOpened,
    required this.onOpen,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool linkOpened;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.paymentOpenLinkCta),
              onPressed: onOpen,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          // EXPLICIT: opening the link is not payment confirmation.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.inkMuted),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  l10n.paymentLinkOpenedNote,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — receipt upload, with all four visible statuses.
// ---------------------------------------------------------------------------

class _ReceiptStep extends StatelessWidget {
  const _ReceiptStep({
    required this.theme,
    required this.l10n,
    required this.state,
    required this.onPickGallery,
    required this.onTakePhoto,
    required this.onRetry,
    required this.onDone,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final ReceiptUploadState state;
  final VoidCallback onPickGallery;
  final VoidCallback onTakePhoto;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ReceiptFlowStatus.uploading:
        return _StatusCard(
          theme: theme,
          icon: Icons.cloud_upload_outlined,
          iconColor: AppColors.accentHover,
          title: l10n.receiptUploading,
          tone: _StatusTone.accent,
          child: const Padding(
            padding: EdgeInsets.only(top: AppSpace.md),
            child: LinearProgressIndicator(),
          ),
        );

      // Phase 17 Plan 04 (D-04): AI verification states
      case ReceiptFlowStatus.checking:
        return _StatusCard(
          theme: theme,
          icon: Icons.autorenew,
          iconColor: AppColors.accentHover,
          title: l10n.receiptCheckingTitle,
          tone: _StatusTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpace.md),
                child: LinearProgressIndicator(),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                l10n.receiptCheckingBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        );

      case ReceiptFlowStatus.approvedByAi:
        return _StatusCard(
          theme: theme,
          icon: Icons.check_circle_outline,
          iconColor: AppColors.accentDeep,
          title: l10n.receiptApprovedTitle,
          tone: _StatusTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.sm),
              Text(
                l10n.receiptApprovedBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onDone,
                  child: Text(l10n.receiptDoneCta),
                ),
              ),
            ],
          ),
        );

      case ReceiptFlowStatus.needsReview:
        return _StatusCard(
          theme: theme,
          icon: Icons.pending_outlined,
          iconColor: AppColors.accentHover,
          title: l10n.receiptNeedsReviewTitle,
          tone: _StatusTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.sm),
              Text(
                l10n.receiptNeedsReviewBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onDone,
                  child: Text(l10n.receiptDoneCta),
                ),
              ),
            ],
          ),
        );

      case ReceiptFlowStatus.rejected:
        return _StatusCard(
          theme: theme,
          icon: Icons.cancel_outlined,
          iconColor: AppColors.danger,
          title: l10n.receiptRejectedTitle,
          tone: _StatusTone.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.sm),
              Text(
                state.rejectionCategory == 'not_receipt'
                    ? l10n.receiptRejectedReasonNotReceipt
                    : l10n.receiptRejectedBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.danger),
              ),
              // ADMREC-04: show admin rejection reason when present (T-18-11).
              // Reason comes only from the customer's own receipt status endpoint
              // (owner-scoped — no information leakage).
              if (state.reason != null && state.reason!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.receiptRejectedReasonLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        state.reason!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ],
              if (state.blockedUntil != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  l10n.errReceiptUploadSuspended,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              // Primary CTA: upload a replacement for the SAME payment (D-13/D-14).
              // This calls reset() then the user picks a new file — same paymentId,
              // no new payment or order is initiated.
              if (state.blockedUntil == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(l10n.receiptRejectedUploadNewCta),
                    onPressed: onRetry,
                  ),
                ),
            ],
          ),
        );

      case ReceiptFlowStatus.error:
        final msg = localizedError(context, state.errorCode);
        return _StatusCard(
          theme: theme,
          icon: Icons.error_outline,
          iconColor: AppColors.danger,
          title: l10n.receiptUploadFailed,
          tone: _StatusTone.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.sm),
              Text(
                msg,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.danger),
              ),
              const SizedBox(height: AppSpace.lg),
              if (state.errorCode != 'RECEIPT_UPLOAD_SUSPENDED')
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(l10n.receiptRetryCta),
                ),
            ],
          ),
        );

      case ReceiptFlowStatus.awaitingReceipt:
        return Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.receiptStepTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.receiptStepSubtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.receiptChooseFromGallery),
                  onPressed: onPickGallery,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(l10n.receiptTakePhoto),
                  onPressed: onTakePhoto,
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Tone of the status card — drives the token-tinted background and border
/// following the order_screen banner pattern (L107-218).
enum _StatusTone { accent, danger, neutral }

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.tone = _StatusTone.neutral,
  });

  final ThemeData theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  /// Token-tinted decoration tone: accent (in-progress), danger (rejected/error),
  /// neutral (white surface, e.g. approved/needsReview with CTA).
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    // Token-tinted bg/border per order_screen banner pattern.
    final Color bg;
    final Color border;
    switch (tone) {
      case _StatusTone.accent:
        bg = AppColors.accent.withValues(alpha: 0.10);
        border = AppColors.accent.withValues(alpha: 0.30);
      case _StatusTone.danger:
        bg = AppColors.danger.withValues(alpha: 0.10);
        border = AppColors.danger.withValues(alpha: 0.30);
      case _StatusTone.neutral:
        bg = AppColors.surface;
        border = AppColors.line;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: tone == _StatusTone.neutral ? AppShadows.soft : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.theme, required this.message});

  final ThemeData theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
      ),
    );
  }
}
