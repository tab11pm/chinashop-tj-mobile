/// DomainException maps the API's { error: string, code: string } error shape
/// to a typed Flutter exception. All API errors surface through this class.
///
/// Per D-07: the API always returns { "error": "...", "code": "SOME_CODE" } on failure.
/// The Dio AuthInterceptor extracts these fields and wraps them in DomainException.
class DomainException implements Exception {
  /// Machine-readable error code from the API (e.g. 'OTP_INVALID', 'PRODUCT_NOT_FOUND').
  final String code;

  /// Human-readable error message from the API error body.
  final String message;

  const DomainException({required this.code, required this.message});

  @override
  String toString() => 'DomainException(code: $code, message: $message)';
}
