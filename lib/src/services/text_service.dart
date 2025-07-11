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

  // Sample data for demonstration
  Future<void> loadSampleData() async {
    final sampleGreek1 = TextSnippet(
      id: '1',
      title: 'Iliad - Book 1',
      content: 'Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος οὐλομένην, ἣ μυρί᾽ Ἀχαιοῖς ἄλγε᾽ ἔθηκε, πολλὰς δ᾽ ἰφθίμους ψυχὰς Ἅϊδι προΐαψεν ἡρώων, αὐτοὺς δὲ ἑλώρια τεῦχε κύνεσσιν οἰωνοῖσί τε πᾶσι, Διὸς δ᾽ ἐτελείετο βουλή, ἐξ οὗ δὴ τὰ πρῶτα διαστήτην ἐρίσαντε Ἀτρεΐδης τε ἄναξ ἀνδρῶν καὶ δῖος Ἀχιλλεύς.',
      author: 'Homer',
      language: LanguageType.greek,
      createdAt: DateTime.now(),
    );

    final sampleGreek2 = TextSnippet(
      id: '2',
      title: 'Odyssey - Book 1',
      content: 'Ἄνδρα μοι ἔννεπε, Μοῦσα, πολύτροπον, ὃς μάλα πολλὰ πλάγχθη, ἐπεὶ Τροίης ἱερὸν πτολίεθρον ἔπερσε· πολλῶν δ᾽ ἀνθρώπων ἴδεν ἄστεα καὶ νόον ἔγνω, πολλὰ δ᾽ ὅ γ᾽ ἐν πόντῳ πάθεν ἄλγεα ὃν κατὰ θυμόν, ἀρνύμενος ἥν τε ψυχὴν καὶ νόστον ἑταίρων.',
      author: 'Homer',
      language: LanguageType.greek,
      createdAt: DateTime.now(),
    );

    final sampleGreek3 = TextSnippet(
      id: '3',
      title: 'Apology - Opening',
      content: 'Ὅτι μὲν ὑμεῖς, ὦ ἄνδρες Ἀθηναῖοι, πεπόνθατε ὑπὸ τῶν ἐμῶν κατηγόρων, οὐκ οἶδα· ἐγὼ δ᾽ οὖν καὶ αὐτὸς ὑπ᾽ αὐτῶν ὀλίγου ἐμαυτοῦ ἐπελαθόμην, οὕτω πιθανῶς ἔλεγον. Καίτοι ἀληθές γε ὡς ἔπος εἰπεῖν οὐδὲν εἰρήκασιν.',
      author: 'Plato',
      language: LanguageType.greek,
      createdAt: DateTime.now(),
    );

    final sampleArabic = TextSnippet(
      id: '4',
      title: 'Quran - Al-Fatiha',
      content: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      author: 'Quran',
      language: LanguageType.arabic,
      createdAt: DateTime.now(),
    );

    await addSnippet(sampleGreek1);
    await addSnippet(sampleGreek2);
    await addSnippet(sampleGreek3);
    await addSnippet(sampleArabic);
  }
}