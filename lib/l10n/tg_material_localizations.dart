import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ships no built-in [GlobalMaterialLocalizations] /
/// [GlobalCupertinoLocalizations] for Tajik (`tg`). Without these, framework
/// widgets (date pickers, dialogs, tooltips, text-selection menus) throw the
/// "locale tg is not supported by all of its localization delegates" warning
/// and fall back to unlocalized strings.
///
/// Tajik users are near-universally fluent in Russian, and `ru` is fully
/// supported by Flutter, so we serve Russian Material/Cupertino strings for the
/// `tg` locale. App-specific copy still comes from our own AppLocalizations
/// (tj/ru/en); only framework-level widget labels fall back to Russian.

/// Material localizations for `tg`, backed by the Russian translations.
class TgMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const TgMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ru'));

  @override
  bool shouldReload(TgMaterialLocalizationsDelegate old) => false;
}

/// Cupertino localizations for `tg`, backed by the Russian translations.
class TgCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const TgCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ru'));

  @override
  bool shouldReload(TgCupertinoLocalizationsDelegate old) => false;
}
