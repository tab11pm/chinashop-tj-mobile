/// Maps the Flutter UI locale code to the code the API expects.
///
/// The Flutter app uses `tg` (ISO 639-1 for Tajik). The backend, however, stores
/// translations and validates `?lang=` against `tj` (catalog query enums +
/// ProductTranslation.locale = 'tj'). Sending `tg` to the API → 400 on
/// enum-guarded routes and no translation match elsewhere. Translate at the
/// boundary so the UI keeps the correct `tg` while the API gets `tj`.
String apiLang(String uiLocale) => uiLocale == 'tg' ? 'tj' : uiLocale;

/// Maps the API locale code back to Flutter's UI locale code.
String uiLang(String apiLocale) => apiLocale == 'tj' ? 'tg' : apiLocale;
