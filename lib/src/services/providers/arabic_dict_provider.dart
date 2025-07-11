import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/dictionary_entry.dart';
import '../../models/language.dart';
import '../dictionary_provider.dart';

class ArabicDictProvider extends DictionaryProvider {
  static const String _baseUrl = 'https://raw.githubusercontent.com/abdorahmanmahmoudd/SpokenArabicDictionary/master/Arabic-Words.json';
  
  // Cache for the dictionary data
  static Map<String, dynamic>? _dictionaryCache;
  static DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(hours: 24);

  @override
  String get name => 'Arabic Dictionary';

  @override
  List<LanguageType> get supportedLanguages => [LanguageType.arabic];

  @override
  Future<List<DictionaryEntry>> lookup(String word, LanguageType language) async {
    if (!supportsLanguage(language)) {
      throw UnsupportedError('Arabic Dictionary does not support ${language.name}');
    }

    try {
      print('ARABIC_DICT: Looking up word "$word"');
      
      // Load dictionary data if not cached or expired
      await _loadDictionaryData();
      
      if (_dictionaryCache == null) {
        print('ARABIC_DICT: Dictionary data not available');
        return [];
      }

      final entries = <DictionaryEntry>[];
      final words = _dictionaryCache!['words'] as List?;
      
      if (words == null) {
        print('ARABIC_DICT: No words array found in dictionary data');
        return [];
      }
      
      // Search for matches in the words array
      for (final wordEntry in words) {
        if (wordEntry is Map<String, dynamic>) {
          final arabicWord = wordEntry['WORD']?.toString() ?? '';
          
          // Check for exact match or if the word contains our search term
          if (arabicWord == word || arabicWord.contains(word) || word.contains(arabicWord)) {
            entries.add(_createDictionaryEntry(arabicWord, wordEntry));
            
            // Limit results to avoid too many matches
            if (entries.length >= 10) break;
          }
        }
      }
      
      if (entries.isNotEmpty) {
        print('ARABIC_DICT: Found ${entries.length} matches for "$word"');
      } else {
        print('ARABIC_DICT: No matches found for "$word"');
      }
      
      return entries;
    } catch (e) {
      print('ARABIC_DICT: Error looking up "$word": $e');
      return [];
    }
  }

  @override
  Future<List<MorphologicalInfo>> getMorphology(String word, LanguageType language) async {
    // This simple dictionary doesn't provide morphological analysis
    return [];
  }

  DictionaryEntry _createDictionaryEntry(String word, Map<String, dynamic> wordData) {
    final definitions = <Definition>[];
    
    // Extract information from the word data
    final partOfSpeech = _getPartOfSpeech(wordData['PART_OF_SPEECH']);
    final plural = wordData['PLURAL']?.toString();
    final root = wordData['ROOT']?.toString();
    final conjugation = wordData['CONJUGATION']?.toString();
    
    // Build definition text from available information
    final definitionParts = <String>[];
    
    if (root != null && root.isNotEmpty) {
      definitionParts.add('Root: $root');
    }
    
    if (plural != null && plural.isNotEmpty && plural != word) {
      definitionParts.add('Plural: $plural');
    }
    
    if (conjugation != null && conjugation.isNotEmpty) {
      definitionParts.add('Conjugation: $conjugation');
    }
    
    // Create definition text
    String definitionText = definitionParts.isNotEmpty 
        ? definitionParts.join(', ')
        : 'Arabic word';
    
    definitions.add(Definition(
      text: definitionText,
      partOfSpeech: partOfSpeech,
    ));

    return DictionaryEntry(
      word: word,
      lemma: word,
      definitions: definitions,
      source: name,
    );
  }
  
  String? _getPartOfSpeech(dynamic pos) {
    if (pos == null) return null;
    
    // Convert numeric part of speech codes to readable strings
    final posCode = pos is num ? pos.toInt() : int.tryParse(pos.toString());
    
    switch (posCode) {
      case 1: return 'Noun';
      case 2: return 'Verb';
      case 3: return 'Adjective';
      case 4: return 'Adverb';
      case 5: return 'Preposition';
      case 6: return 'Noun'; // Another noun type
      case 7: return 'Pronoun';
      case 8: return 'Particle';
      default: return pos.toString();
    }
  }

  Future<void> _loadDictionaryData() async {
    // Check if cache is still valid
    if (_dictionaryCache != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
      return;
    }

    try {
      print('ARABIC_DICT: Loading dictionary data from GitHub...');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'User-Agent': 'Strabo Language Learning App'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData is Map<String, dynamic>) {
          _dictionaryCache = jsonData;
          _cacheTime = DateTime.now();
          
          // Debug: show what we actually loaded
          final words = _dictionaryCache!['words'] as List?;
          final wordCount = words?.length ?? 0;
          print('ARABIC_DICT: Loaded dictionary with ${_dictionaryCache!.keys.length} top-level keys');
          print('ARABIC_DICT: Found ${wordCount} words in the dictionary');
          
          // Show first few entries for debugging
          if (words != null && words.isNotEmpty) {
            print('ARABIC_DICT: Sample entries:');
            for (int i = 0; i < words.length && i < 3; i++) {
              final entry = words[i];
              if (entry is Map) {
                print('ARABIC_DICT:   Entry $i: ${entry['WORD']} (${entry['PART_OF_SPEECH']})');
              }
            }
          }
        } else {
          print('ARABIC_DICT: Invalid dictionary data format: ${jsonData.runtimeType}');
        }
      } else {
        print('ARABIC_DICT: Failed to load dictionary data: ${response.statusCode}');
      }
    } catch (e) {
      print('ARABIC_DICT: Error loading dictionary data: $e');
    }
  }
}