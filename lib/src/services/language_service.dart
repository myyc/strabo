import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

class LanguageService extends ChangeNotifier {
  Language _currentLanguage = Language.supportedLanguages.first;
  static const String _languageKey = 'current_language';

  Language get currentLanguage => _currentLanguage;

  LanguageService() {
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      try {
        final languageType = LanguageType.values.firstWhere(
          (type) => Language.fromType(type).code == languageCode,
        );
        _currentLanguage = Language.fromType(languageType);
        notifyListeners();
      } catch (e) {
        // If saved language is not found, keep default
      }
    }
  }

  Future<void> setCurrentLanguage(Language language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }

  List<Language> getSupportedLanguages() {
    return Language.supportedLanguages;
  }
}