import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../constants/app_constants.dart';
import 'app_localizations.dart';

final class LanguageController extends ValueNotifier<Locale> {
  LanguageController._() : super(const Locale('id'));

  static final instance = LanguageController._();

  Box<dynamic>? _settingsBox;

  void initialize(Box<dynamic> settingsBox) {
    _settingsBox = settingsBox;
    final savedLanguage = settingsBox.get(AppConstants.languageKey) as String?;
    if (savedLanguage == 'id' || savedLanguage == 'en') {
      value = Locale(savedLanguage!);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'id' && languageCode != 'en') return;
    if (value.languageCode != languageCode) value = Locale(languageCode);
    await _settingsBox?.put(AppConstants.languageKey, languageCode);
  }

  String translate(String key, [Map<String, Object>? arguments]) =>
      AppLocalizations(value).translate(key, arguments);
}
