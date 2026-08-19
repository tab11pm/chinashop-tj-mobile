import '../../../l10n/app_localizations.dart';

/// Maps a backend receipt-rejection CATEGORY code to a localized, client-safe
/// message (tj/ru/en). The API returns only the coarse category for pure-AI
/// rejections (no operator note) so the exact expected amount is never exposed.
///
/// Returns null for an unknown/absent category — the caller then falls back to
/// the generic rejected body text.
String? receiptRejectionMessage(AppLocalizations l10n, String? category) {
  switch (category) {
    case 'amount_mismatch':
      return l10n.receiptRejectedReasonAmountMismatch;
    case 'reference_missing':
      return l10n.receiptRejectedReasonReferenceMissing;
    case 'duplicate':
      return l10n.receiptRejectedReasonDuplicate;
    case 'generic':
      return l10n.receiptRejectedReasonGeneric;
    default:
      return null;
  }
}
