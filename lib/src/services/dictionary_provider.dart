import '../models/dictionary_entry.dart';
import '../models/language.dart';

/// Abstract base class for dictionary providers
abstract class DictionaryProvider {
  String get name;
  List<LanguageType> get supportedLanguages;
  
  /// Look up a word in the dictionary
  Future<List<DictionaryEntry>> lookup(String word, LanguageType language);
  
  /// Get morphological analysis for a word
  Future<List<MorphologicalInfo>> getMorphology(String word, LanguageType language);
  
  /// Check if this provider supports the given language
  bool supportsLanguage(LanguageType language) {
    return supportedLanguages.contains(language);
  }
}

/// Result wrapper for dictionary lookups
class DictionaryLookupResult {
  final String query;
  final LanguageType language;
  final List<DictionaryEntry> entries;
  final List<MorphologicalInfo> morphology;
  final DateTime timestamp;
  final String? error;

  const DictionaryLookupResult({
    required this.query,
    required this.language,
    required this.entries,
    required this.morphology,
    required this.timestamp,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasEntries => entries.isNotEmpty;
  bool get hasMorphology => morphology.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'language': language.name,
      'entries': entries.map((e) => e.toJson()).toList(),
      'morphology': morphology.map((m) => m.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }

  factory DictionaryLookupResult.fromJson(Map<String, dynamic> json) {
    return DictionaryLookupResult(
      query: json['query'],
      language: LanguageType.values.firstWhere((e) => e.name == json['language']),
      entries: (json['entries'] as List)
          .map((e) => DictionaryEntry.fromJson(e))
          .toList(),
      morphology: (json['morphology'] as List)
          .map((m) => MorphologicalInfo.fromJson(m))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
      error: json['error'],
    );
  }

  DictionaryLookupResult copyWith({
    String? query,
    LanguageType? language,
    List<DictionaryEntry>? entries,
    List<MorphologicalInfo>? morphology,
    DateTime? timestamp,
    String? error,
  }) {
    return DictionaryLookupResult(
      query: query ?? this.query,
      language: language ?? this.language,
      entries: entries ?? this.entries,
      morphology: morphology ?? this.morphology,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
    );
  }
}