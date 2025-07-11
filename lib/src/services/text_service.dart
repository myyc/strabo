import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/text_snippet.dart';
import '../models/language.dart';
import '../utils/text_normalizer.dart';

class TextService extends ChangeNotifier {
  List<TextSnippet> _snippets = [];
  TextSnippet? _currentSnippet;
  static const String _snippetsKey = 'text_snippets';

  List<TextSnippet> get snippets => _snippets;
  TextSnippet? get currentSnippet => _currentSnippet;

  TextService() {
    _loadSnippets();
  }

  Future<void> _loadSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final snippetsJson = prefs.getStringList(_snippetsKey) ?? [];
    
    _snippets = snippetsJson
        .map((json) => TextSnippet.fromJson(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  Future<void> _saveSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final snippetsJson = _snippets
        .map((snippet) => jsonEncode(snippet.toJson()))
        .toList();
    
    await prefs.setStringList(_snippetsKey, snippetsJson);
  }

  Future<void> addSnippet(TextSnippet snippet) async {
    _snippets.add(snippet);
    await _saveSnippets();
    notifyListeners();
  }

  Future<void> updateSnippet(TextSnippet snippet) async {
    final index = _snippets.indexWhere((s) => s.id == snippet.id);
    if (index != -1) {
      _snippets[index] = snippet;
      await _saveSnippets();
      notifyListeners();
    }
  }

  Future<void> deleteSnippet(String id) async {
    _snippets.removeWhere((snippet) => snippet.id == id);
    if (_currentSnippet?.id == id) {
      _currentSnippet = null;
    }
    await _saveSnippets();
    notifyListeners();
  }

  void setCurrentSnippet(TextSnippet? snippet) {
    _currentSnippet = snippet;
    notifyListeners();
  }

  List<TextSnippet> getSnippetsByLanguage(LanguageType language) {
    return _snippets.where((snippet) => snippet.language == language).toList();
  }

  Future<void> updateWordStatus(String snippetId, String word, WordStatus status) async {
    final snippet = _snippets.firstWhere((s) => s.id == snippetId);
    final updatedWordStatuses = Map<String, WordEntry>.from(snippet.wordStatuses);
    
    // Use normalized form of the word for consistent tracking
    final normalizedWord = TextNormalizer.normalizeForComparison(word);
    updatedWordStatuses[normalizedWord] = WordEntry(
      originalForm: word,
      status: status,
    );
    
    final updatedSnippet = snippet.copyWith(wordStatuses: updatedWordStatuses);
    await updateSnippet(updatedSnippet);
  }

  /// Get the word status for a word, using normalized form for lookup
  WordStatus getWordStatus(String snippetId, String word) {
    final snippet = _snippets.firstWhere((s) => s.id == snippetId);
    final normalizedWord = TextNormalizer.normalizeForComparison(word);
    return snippet.wordStatuses[normalizedWord]?.status ?? WordStatus.unknown;
  }

  /// Get the original form of a word, using normalized form for lookup
  String getOriginalForm(String snippetId, String word) {
    final snippet = _snippets.firstWhere((s) => s.id == snippetId);
    final normalizedWord = TextNormalizer.normalizeForComparison(word);
    return snippet.wordStatuses[normalizedWord]?.originalForm ?? word;
  }

  /// Import a new text snippet
  Future<void> importText({
    required String title,
    required String attribution,
    required String content,
    required LanguageType language,
  }) async {
    final newSnippet = TextSnippet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      author: attribution,
      language: language,
      createdAt: DateTime.now(),
    );
    
    await addSnippet(newSnippet);
  }

  // Remove duplicate snippets based on title and author
  Future<void> removeDuplicates() async {
    final Map<String, TextSnippet> uniqueSnippets = {};
    
    for (final snippet in _snippets) {
      final key = '${snippet.title}|${snippet.author}';
      if (!uniqueSnippets.containsKey(key)) {
        uniqueSnippets[key] = snippet;
      }
    }
    
    _snippets.clear();
    _snippets.addAll(uniqueSnippets.values);
    await _saveSnippets();
    notifyListeners();
  }

  // Remove placeholder sample data (preserves user-added content)
  Future<void> removePlaceholderData() async {
    final placeholderTitles = {
      'Iliad - Book 1',
      'Odyssey - Book 1', 
      'Apology - Opening',
      'Quran - Al-Fatiha',
      'Quran',
    };
    
    final placeholderIds = {
      'sample_greek_1',
      'sample_greek_2', 
      'sample_greek_3',
      'sample_arabic_1',
      'sample_arabic_2',
      '1', '2', '3', '4', // Old numeric IDs
    };
    
    _snippets.removeWhere((snippet) => 
        placeholderTitles.contains(snippet.title) ||
        placeholderIds.contains(snippet.id)
    );
    
    await _saveSnippets();
    notifyListeners();
  }
}