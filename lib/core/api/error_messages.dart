import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'api_exception.dart';

/// Extracts a machine-readable error code from any thrown error.
///
/// - [DomainException] → its `code`
/// - [DioException] wrapping a DomainException → that code; otherwise 'NETWORK'
/// - a bare code String (as stored in provider state) → itself
/// - anything else → 'GENERIC'
String errorCodeOf(Object? error) {
  if (error is DomainException) return error.code;
  if (error is DioException) {
    final inner = error.error;
    if (inner is DomainException) return inner.code;
    return 'NETWORK';
  }
  if (error is String) return error;
  return 'GENERIC';
}

/// Maps an error (or an already-extracted code) to a localized, user-friendly
/// message.
///
/// - Known API code → localized string.
/// - Unknown code that is actually a plain message String (e.g. a screen set a
///   localized validation message directly) → returned as-is.
/// - Anything else → generic message.
String localizedError(BuildContext context, Object? error) {
  final l10n = AppLocalizations.of(context)!;
  switch (errorCodeOf(error)) {
    case 'NETWORK':
      return l10n.errorNetwork;
    case 'CART_EMPTY':
      return l10n.errCartEmpty;
    case 'OUT_OF_STOCK':
      return l10n.errOutOfStock;
    case 'PRODUCT_UNAVAILABLE':
      return l10n.errProductUnavailable;
    case 'ORDER_ALREADY_PAID':
      return l10n.errOrderAlreadyPaid;
    case 'ORDER_NOT_FOUND':
      return l10n.errOrderNotFound;
    case 'PAYMENT_NOT_FOUND':
      return l10n.errPaymentNotFound;
    case 'NO_FX_RATE':
    case 'PRICING_NOT_INITIALIZED':
      return l10n.errNoFxRate;
    case 'VALIDATION_FAILED':
      return l10n.errValidation;
    case 'UNAUTHORIZED':
      return l10n.errUnauthorized;
    case 'FORBIDDEN':
      return l10n.errForbidden;
    case 'EMAIL_IN_USE':
      return l10n.errEmailInUse;
    case 'PHONE_IN_USE':
      return l10n.errPhoneInUse;
    case 'CONFLICT':
      return l10n.errConflict;
    case 'NOT_FOUND':
      return l10n.errNotFound;
    case 'SELLER_APPLICATION_ALREADY_EXISTS':
      return l10n.errorApplicationExists;
    case 'SELLER_NOT_VERIFIED':
      return l10n.errSellerNotVerified;
    case 'MOQ_NOT_MET':
      // Try to extract qty from DomainException.message (e.g. "Минимум 10 единиц").
      // Inline banners in checkout/cart screens use localizedMoqError() with the full error
      // object for richer messaging. This fallback covers the generic error widget path.
      final qty = _extractMoqQty(error);
      if (qty != null) return l10n.wholesaleMoqError(qty);
      return l10n.wholesaleMoqError(0);
    case 'FACTORY_PRODUCT_UNAVAILABLE':
      return l10n.errProductUnavailable;
    case 'WHOLESALE_CART_EMPTY':
      return l10n.errCartEmpty;
    // Phase 16 — payment-link & receipt upload codes.
    case 'DUPLICATE_RECEIPT':
      return l10n.errDuplicateReceipt;
    case 'RECEIPT_FILE_INVALID':
      return l10n.errReceiptFileInvalid;
    case 'PAYMENT_NOT_PENDING':
      return l10n.errPaymentNotPending;
    case 'RECEIPT_NOT_FOUND':
      return l10n.errReceiptNotFound;
    case 'RECEIPT_UPLOAD_SUSPENDED':
      return l10n.errReceiptUploadSuspended;
    // Phase 24 — review write-path codes. REVIEW_ALREADY_EXISTS is
    // intentionally NOT handled here — the review form screen renders a
    // dedicated inline action banner for it instead of this generic path.
    case 'REVIEW_NOT_ELIGIBLE':
      return l10n.errReviewNotEligible;
    case 'REVIEW_NOT_FOUND':
      return l10n.errReviewNotFound;
    case 'REVIEW_PHOTO_INVALID':
      return l10n.errReviewPhotoInvalid;
    case 'REVIEW_PHOTO_LIMIT':
      return l10n.errReviewPhotoLimit;
  }
  // Not a known code. If the caller stored a plain (likely already-localized)
  // message string — and it does NOT look like a raw API code — surface it.
  // Otherwise show the generic message (never leak codes like INTERNAL to UI).
  if (error is String && error.trim().isNotEmpty && !_looksLikeCode(error)) {
    return error;
  }
  return l10n.errorGeneric;
}

/// True for ALL_CAPS_UNDERSCORE tokens — i.e. raw machine error codes that must
/// never be shown to the user (INTERNAL, NO_FX_RATE, …).
bool _looksLikeCode(String s) =>
    RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(s.trim());

/// Attempts to extract a numeric MOQ value from a DomainException message.
/// The API sends messages like "Минимум 10 единиц" — we parse the integer.
int? _extractMoqQty(Object? error) {
  String? msg;
  if (error is DomainException) {
    msg = error.message;
  } else if (error is DioException) {
    final inner = error.error;
    if (inner is DomainException) msg = inner.message;
  }
  if (msg == null) return null;
  final match = RegExp(r'\d+').firstMatch(msg);
  if (match == null) return null;
  return int.tryParse(match.group(0) ?? '');
}

/// Returns a localized MOQ_NOT_MET message, extracting qty from the error
/// object when available. Used by checkout / cart inline banners for richer UX.
String? localizedMoqError(BuildContext context, Object? error) {
  if (errorCodeOf(error) != 'MOQ_NOT_MET') return null;
  final l10n = AppLocalizations.of(context)!;
  final qty = _extractMoqQty(error) ?? 0;
  return l10n.wholesaleMoqError(qty);
}
