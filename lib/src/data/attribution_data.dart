import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/language.dart';

class AttributionData {
  // Minimal seed dataset with most common authors
  static const Map<LanguageType, Map<String, List<String>>> _seedData = {
    LanguageType.greek: {
      'Homer': [
        'Iliad',
        'Odyssey',
      ],
      'Plato': [
        'Republic',
        'Apology',
        'Phaedo',
      ],
      'Aristotle': [
        'Nicomachean Ethics',
        'Politics',
        'Poetics',
      ],
      'Sophocles': [
        'Oedipus Rex',
        'Antigone',
      ],
      'Euripides': [
        'Medea',
        'Bacchae',
      ],
      'Herodotus': [
        'Histories',
      ],
      'Thucydides': [
        'History of the Peloponnesian War',
      ],
      'New Testament': [
        'Matthew',
        'Mark',
        'Luke',
        'John',
      ],
      'Septuagint': [
        'Genesis',
        'Psalms',
        'Isaiah',
      ],
      'Anonymous': [
        'Inscriptions',
        'Papyri',
        'Fragments',
      ],
    },
    LanguageType.arabic: {
      'Quran': [
        'Sura Al-Fatiha',
        'Sura Al-Baqara',
        'Sura Al-Imran',
        'Sura Yusuf',
      ],
      'Al-Mutanabbi': [
        'Diwan',
      ],
      'Imru al-Qais': [
        'Muallaqat',
        'Diwan',
      ],
      'Ibn Sina (Avicenna)': [
        'Al-Qanun fi al-Tibb',
        'Al-Shifa',
      ],
      'Al-Ghazali': [
        'Ihya Ulum al-Din',
      ],
      'Ibn Khaldun': [
        'Muqaddimah',
      ],
      'Al-Tabari': [
        'Tarikh al-Rusul wa al-Muluk',
        'Tafsir al-Tabari',
      ],
      'Al-Bukhari': [
        'Sahih al-Bukhari',
      ],
      'Anonymous': [
        'Alf Layla wa Layla (1001 Nights)',
        'Folk Poetry',
        'Inscriptions',
      ],
    },
  };

  static const String _userDataKey = 'user_attribution_data';
  static Map<LanguageType, Map<String, List<String>>> _userData = {};
  static bool _isLoaded = false;

  /// Load user data from persistent storage
  static Future<void> _loadUserData() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString(_userDataKey);
    
    if (userDataJson != null) {
      try {
        final decoded = jsonDecode(userDataJson) as Map<String, dynamic>;
        _userData = {};
        
        for (final entry in decoded.entries) {
          final languageType = LanguageType.values.firstWhere(
            (type) => type.name == entry.key,
            orElse: () => LanguageType.greek,
          );
          
          final attributionMap = <String, List<String>>{};
          final attributions = entry.value as Map<String, dynamic>;
          
          for (final attrEntry in attributions.entries) {
            attributionMap[attrEntry.key] = List<String>.from(attrEntry.value);
          }
          
          _userData[languageType] = attributionMap;
        }
      } catch (e) {
        _userData = {};
      }
    }
    
    _isLoaded = true;
  }

  /// Save user data to persistent storage
  static Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataMap = <String, dynamic>{};
    
    for (final entry in _userData.entries) {
      userDataMap[entry.key.name] = entry.value;
    }
    
    await prefs.setString(_userDataKey, jsonEncode(userDataMap));
  }

  /// Get combined attributions (seed + user data)
  static Future<List<String>> getAttributions(LanguageType language) async {
    await _loadUserData();
    
    final seedAttributions = _seedData[language]?.keys.toList() ?? [];
    final userAttributions = _userData[language]?.keys.toList() ?? [];
    
    // Combine and deduplicate
    final combined = <String>{};
    combined.addAll(seedAttributions);
    combined.addAll(userAttributions);
    
    return combined.toList()..sort();
  }

  /// Get combined sources (seed + user data)
  static Future<List<String>> getSources(LanguageType language, String attribution) async {
    await _loadUserData();
    
    final seedSources = _seedData[language]?[attribution] ?? [];
    final userSources = _userData[language]?[attribution] ?? [];
    
    // Combine and deduplicate
    final combined = <String>{};
    combined.addAll(seedSources);
    combined.addAll(userSources);
    
    return combined.toList()..sort();
  }

  /// Add or update user attribution and sources
  static Future<void> addAttribution(LanguageType language, String attribution, List<String> sources) async {
    await _loadUserData();
    
    _userData[language] ??= {};
    _userData[language]![attribution] = sources;
    
    await _saveUserData();
  }

  /// Add a source to an existing attribution
  static Future<void> addSource(LanguageType language, String attribution, String source) async {
    await _loadUserData();
    
    _userData[language] ??= {};
    _userData[language]![attribution] ??= [];
    
    if (!_userData[language]![attribution]!.contains(source)) {
      _userData[language]![attribution]!.add(source);
      _userData[language]![attribution]!.sort();
      await _saveUserData();
    }
  }

  /// Remove user attribution (keeps seed data)
  static Future<void> removeAttribution(LanguageType language, String attribution) async {
    await _loadUserData();
    
    _userData[language]?.remove(attribution);
    await _saveUserData();
  }

  /// Remove a source from an attribution
  static Future<void> removeSource(LanguageType language, String attribution, String source) async {
    await _loadUserData();
    
    _userData[language]?[attribution]?.remove(source);
    await _saveUserData();
  }

  /// Check if an attribution exists (seed or user)
  static Future<bool> hasAttribution(LanguageType language, String attribution) async {
    await _loadUserData();
    
    return _seedData[language]?.containsKey(attribution) == true ||
           _userData[language]?.containsKey(attribution) == true;
  }

  /// Search attributions with query
  static Future<List<String>> searchAttributions(LanguageType language, String query) async {
    if (query.isEmpty) return [];
    
    final attributions = await getAttributions(language);
    final queryLower = query.toLowerCase();
    
    return attributions
        .where((attribution) => attribution.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Search sources with query
  static Future<List<String>> searchSources(LanguageType language, String attribution, String query) async {
    if (query.isEmpty) return [];
    
    final sources = await getSources(language, attribution);
    final queryLower = query.toLowerCase();
    
    return sources
        .where((source) => source.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Get user data for export
  static Future<Map<String, dynamic>> exportUserData() async {
    await _loadUserData();
    
    final exportData = <String, dynamic>{};
    for (final entry in _userData.entries) {
      exportData[entry.key.name] = entry.value;
    }
    
    return exportData;
  }

  /// Import user data
  static Future<void> importUserData(Map<String, dynamic> data, {bool merge = true}) async {
    await _loadUserData();
    
    if (!merge) {
      _userData.clear();
    }
    
    for (final entry in data.entries) {
      try {
        final languageType = LanguageType.values.firstWhere(
          (type) => type.name == entry.key,
        );
        
        final attributionMap = <String, List<String>>{};
        final attributions = entry.value as Map<String, dynamic>;
        
        for (final attrEntry in attributions.entries) {
          attributionMap[attrEntry.key] = List<String>.from(attrEntry.value);
        }
        
        if (merge) {
          _userData[languageType] ??= {};
          _userData[languageType]!.addAll(attributionMap);
        } else {
          _userData[languageType] = attributionMap;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    await _saveUserData();
  }
}