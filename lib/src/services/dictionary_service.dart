import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/dictionary_entry.dart';
import '../models/language.dart';
import 'dictionary_provider.dart';
import 'providers/perseus_provider.dart';
import 'providers/wiktionary_provider.dart';

class DictionaryService extends ChangeNotifier {
  final List<DictionaryProvider> _providers = [];
  final Map<String, DictionaryLookupResult> _cache = {};
  static const String _cacheKey = 'dictionary_cache';
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(days: 7);

  DictionaryService() {
    _initializeProviders();
    // _loadCache(); // Disabled for debugging
    clearCache(); // Clear any existing cache
  }

  void _initializeProviders() {
    // Add dictionary providers in order of preference
    _providers.addAll([
      PerseusProvider(),
      // ArabicDictProvider(), // Disabled: contains romanized text, not Arabic script
      WiktionaryProvider(),
    ]);
  }

  /// Get available providers for a language
  List<DictionaryProvider> getProvidersForLanguage(LanguageType language) {
    return _providers.where((p) => p.supportsLanguage(language)).toList();
  }

  /// Look up a word using all available providers
  Future<DictionaryLookupResult> lookup(String word, LanguageType language) async {
    print('DICTIONARY_SERVICE: Starting lookup for word "$word" in ${language.name}');
    
    final cacheKey = '${language.name}:${word.toLowerCase()}';
    
    // Check cache first (DISABLED FOR DEBUGGING)
    // if (_cache.containsKey(cacheKey)) {
    //   final cached = _cache[cacheKey]!;
    //   if (DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
    //     print('DICTIONARY_SERVICE: Found cached result for "$word" (age: ${DateTime.now().difference(cached.timestamp).inMinutes} minutes)');
    //     return cached;
    //   } else {
    //     print('DICTIONARY_SERVICE: Cached result for "$word" expired, removing from cache');
    //     _cache.remove(cacheKey);
    //   }
    // }
    print('DICTIONARY_SERVICE: Cache disabled for debugging');

    final providers = getProvidersForLanguage(language);
    print('DICTIONARY_SERVICE: Found ${providers.length} providers for ${language.name}: ${providers.map((p) => p.name).toList()}');
    
    if (providers.isEmpty) {
      print('DICTIONARY_SERVICE: No providers available for ${language.name}');
      return DictionaryLookupResult(
        query: word,
        language: language,
        entries: [],
        morphology: [],
        timestamp: DateTime.now(),
        error: 'No dictionary providers available for ${language.name}',
      );
    }

    // Try providers in order until we get results
    List<DictionaryEntry> allEntries = [];
    List<MorphologicalInfo> allMorphology = [];
    String? lastError;

    // Clean word by removing punctuation and try both original and lowercase
    final cleanWord = word.replaceAll(RegExp(r'[^\p{L}\p{M}]', unicode: true), '');
    print('DICTIONARY_SERVICE: Cleaned word from "$word" to "$cleanWord"');
    
    final wordsToTry = [cleanWord];
    if (cleanWord != cleanWord.toLowerCase()) {
      wordsToTry.add(cleanWord.toLowerCase());
      print('DICTIONARY_SERVICE: Will also try lowercase version: "${cleanWord.toLowerCase()}"');
    }
    
    // For Arabic, apply transformations in correct hierarchy: prefixes → suffixes → dagger alif → diacritics
    if (language == LanguageType.arabic) {
      // Start with original word (with diacritics intact)
      final morphVariants = <String>[cleanWord];
      
      // 1. Apply prefix stripping to original word (keep diacritics)
      final arabicVariants = _getArabicPrefixVariants(cleanWord);
      morphVariants.addAll(arabicVariants);
      
      // 2. Apply suffix stripping to all current variants (keep diacritics) 
      final currentVariants = [...morphVariants];
      for (final variant in currentVariants) {
        final suffixVariants = _getArabicSuffixVariants(variant);
        for (final suffixVariant in suffixVariants) {
          if (!morphVariants.contains(suffixVariant)) {
            morphVariants.add(suffixVariant);
          }
        }
      }
      
      // 3. Apply dagger alif replacement to ALL current variants (including suffix-stripped)
      final variantsWithDaggerAlif = [...morphVariants];
      for (final variant in variantsWithDaggerAlif) {
        final daggerAlifVariants = _getArabicDaggerAlifVariants(variant);
        for (final daggerVariant in daggerAlifVariants) {
          if (!morphVariants.contains(daggerVariant)) {
            morphVariants.add(daggerVariant);
            print('DICTIONARY_SERVICE: Added dagger alif variant: "$variant" -> "$daggerVariant"');
          }
        }
      }
      
      // 4. Finally, strip diacritics from ALL variants and add to wordsToTry
      for (final variant in morphVariants) {
        if (!wordsToTry.contains(variant)) {
          wordsToTry.add(variant);
        }
        
        final noDiacritics = _stripArabicDiacritics(variant);
        if (noDiacritics != variant && !wordsToTry.contains(noDiacritics)) {
          wordsToTry.add(noDiacritics);
        }
      }
      
      print('DICTIONARY_SERVICE: Added ${arabicVariants.length} Arabic prefix variants: $arabicVariants');
      print('DICTIONARY_SERVICE: Generated ${morphVariants.length} total Arabic morphological variants');
    }

    for (final provider in providers) {
      for (final wordVariant in wordsToTry) {
        try {
          print('DICTIONARY_SERVICE: Trying provider ${provider.name} for word "$wordVariant"');
          final entries = await provider.lookup(wordVariant, language);
          print('DICTIONARY_SERVICE: ${provider.name} returned ${entries.length} entries for "$wordVariant"');
          
          final morphology = await provider.getMorphology(wordVariant, language);
          print('DICTIONARY_SERVICE: ${provider.name} returned ${morphology.length} morphological analyses for "$wordVariant"');
          
          allEntries.addAll(entries);
          allMorphology.addAll(morphology);
          
          // If we got results from this word variant, try next provider
          // (we want to try all providers before stopping)
          if (entries.isNotEmpty) {
            print('DICTIONARY_SERVICE: Got ${entries.length} results from ${provider.name} for "$wordVariant"');
            break; // Try next provider
          }
        } catch (e) {
          lastError = e.toString();
          print('DICTIONARY_SERVICE: Error from ${provider.name} for "$wordVariant": $e');
          debugPrint('Error from ${provider.name} for "$wordVariant": $e');
        }
      }
      
      // If we got results from this provider, we can stop trying other providers
      if (allEntries.isNotEmpty) {
        print('DICTIONARY_SERVICE: Got total ${allEntries.length} results, stopping provider chain');
        break;
      }
    }

    // Process morphological references and expand with lemma definitions
    await _expandMorphologicalReferences(allEntries, language, [word]); // Pass visited words to prevent circular lookups

    final result = DictionaryLookupResult(
      query: word,
      language: language,
      entries: allEntries,
      morphology: allMorphology,
      timestamp: DateTime.now(),
      error: allEntries.isEmpty ? lastError : null,
    );

    print('DICTIONARY_SERVICE: Final result for "$word": ${allEntries.length} entries, ${allMorphology.length} morphology, error: ${result.error}');

    // Cache the result (DISABLED FOR DEBUGGING)
    // _cacheResult(cacheKey, result);
    print('DICTIONARY_SERVICE: Caching disabled for debugging');
    
    return result;
  }

  /// Quick morphology lookup (cached, may not be complete)
  Future<List<MorphologicalInfo>> getMorphology(String word, LanguageType language) async {
    final cacheKey = '${language.name}:${word.toLowerCase()}';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!.morphology;
    }

    // If not cached, do a full lookup
    final result = await lookup(word, language);
    return result.morphology;
  }

  /// Check if a word has been looked up before
  bool isWordCached(String word, LanguageType language) {
    final cacheKey = '${language.name}:${word.toLowerCase()}';
    return _cache.containsKey(cacheKey);
  }

  /// Get cached entry without triggering network request
  DictionaryLookupResult? getCachedLookup(String word, LanguageType language) {
    final cacheKey = '${language.name}:${word.toLowerCase()}';
    return _cache[cacheKey];
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _saveCache();
    notifyListeners();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) < _cacheExpiry) {
        validCount++;
      } else {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'maxSize': _maxCacheSize,
    };
  }

  void _cacheResult(String key, DictionaryLookupResult result) {
    // Remove oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.reduce((a, b) => 
        _cache[a]!.timestamp.isBefore(_cache[b]!.timestamp) ? a : b);
      _cache.remove(oldestKey);
    }

    _cache[key] = result;
    _saveCache();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson != null) {
        final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
        
        for (final entry in cacheData.entries) {
          try {
            final result = DictionaryLookupResult.fromJson(entry.value);
            // Only load non-expired entries
            if (DateTime.now().difference(result.timestamp) < _cacheExpiry) {
              _cache[entry.key] = result;
            }
          } catch (e) {
            debugPrint('Error loading cached entry ${entry.key}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading dictionary cache: $e');
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = <String, dynamic>{};
      
      for (final entry in _cache.entries) {
        cacheData[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error saving dictionary cache: $e');
    }
  }

  /// Expands morphological references by looking up referenced lemmas
  Future<void> _expandMorphologicalReferences(
    List<DictionaryEntry> entries, 
    LanguageType language, 
    List<String> visitedWords,
  ) async {
    for (int entryIndex = 0; entryIndex < entries.length; entryIndex++) {
      final entry = entries[entryIndex];
      final updatedDefinitions = <Definition>[];
      bool hasUpdates = false;
      
      for (final definition in entry.definitions) {
        if (definition.isMorphological && 
            definition.referencedLemma != null && 
            definition.referencedLemma!.isNotEmpty) {
          
          final lemma = definition.referencedLemma!;
          
          // Prevent circular lookups
          if (visitedWords.contains(lemma.toLowerCase())) {
            print('DICTIONARY_SERVICE: Skipping circular lookup for lemma: $lemma');
            updatedDefinitions.add(definition);
            continue;
          }
          
          print('DICTIONARY_SERVICE: Looking up referenced lemma: $lemma');
          
          try {
            // Recursively look up the lemma
            final lemmaResult = await _lookupLemma(lemma, language, [...visitedWords, lemma.toLowerCase()]);
            
            if (lemmaResult.isNotEmpty) {
              print('DICTIONARY_SERVICE: Found ${lemmaResult.length} definitions for lemma: $lemma');
              
              // Create an updated definition with lemma definitions
              final updatedDefinition = Definition(
                text: definition.text,
                partOfSpeech: definition.partOfSpeech,
                examples: definition.examples,
                register: definition.register,
                isMorphological: definition.isMorphological,
                referencedLemma: definition.referencedLemma,
                lemmaDefinitions: lemmaResult,
              );
              
              updatedDefinitions.add(updatedDefinition);
              hasUpdates = true;
            } else {
              updatedDefinitions.add(definition);
            }
          } catch (e) {
            print('DICTIONARY_SERVICE: Error looking up lemma $lemma: $e');
            updatedDefinitions.add(definition);
          }
        } else {
          updatedDefinitions.add(definition);
        }
      }
      
      // Replace the entry if we have updates
      if (hasUpdates) {
        final updatedEntry = DictionaryEntry(
          word: entry.word,
          lemma: entry.lemma,
          definitions: updatedDefinitions,
          etymologies: entry.etymologies,
          morphology: entry.morphology,
          pronunciation: entry.pronunciation,
          source: entry.source,
        );
        entries[entryIndex] = updatedEntry;
      }
    }
  }

  /// Helper method to lookup a lemma with circular protection
  Future<List<Definition>> _lookupLemma(
    String lemma, 
    LanguageType language, 
    List<String> visitedWords,
  ) async {
    final providers = getProvidersForLanguage(language);
    final allDefinitions = <Definition>[];
    
    // For Arabic, try multiple variants of the lemma
    final lemmasToTry = <String>[lemma];
    if (language == LanguageType.arabic) {
      // Try without diacritics
      final noDiacritics = _stripArabicDiacritics(lemma);
      if (noDiacritics != lemma) {
        lemmasToTry.add(noDiacritics);
      }
      
      // Try with prefix removal for Arabic verbs
      final prefixVariants = _getArabicPrefixVariants(lemma);
      for (final variant in prefixVariants) {
        if (!lemmasToTry.contains(variant)) {
          lemmasToTry.add(variant);
          // Also try variant without diacritics
          final variantNoDiacritics = _stripArabicDiacritics(variant);
          if (variantNoDiacritics != variant && !lemmasToTry.contains(variantNoDiacritics)) {
            lemmasToTry.add(variantNoDiacritics);
          }
        }
      }
    }
    
    for (final provider in providers) {
      for (final lemmaVariant in lemmasToTry) {
        try {
          final entries = await provider.lookup(lemmaVariant, language);
          for (final entry in entries) {
            // Only include non-morphological definitions to avoid infinite recursion
            final nonMorphDefs = entry.definitions.where((d) => !d.isMorphological).toList();
            allDefinitions.addAll(nonMorphDefs);
          }
          
          // If we got some definitions, that's enough for expansion
          if (allDefinitions.isNotEmpty) {
            print('DICTIONARY_SERVICE: Found definitions for lemma variant: $lemmaVariant');
            break;
          }
        } catch (e) {
          print('DICTIONARY_SERVICE: Error from ${provider.name} for lemma variant $lemmaVariant: $e');
        }
      }
      
      // If we got definitions from this provider, stop trying other providers
      if (allDefinitions.isNotEmpty) {
        break;
      }
    }
    
    return allDefinitions;
  }

  /// Generate Arabic word variants by progressively stripping common prefixes
  List<String> _getArabicPrefixVariants(String word) {
    final variants = <String>[];
    
    // Debug: show the word characters and their Unicode values
    print('DICTIONARY_SERVICE: Analyzing Arabic word "$word" for prefixes');
    for (int i = 0; i < word.length && i < 5; i++) {
      final char = word[i];
      final codeUnit = char.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
      print('DICTIONARY_SERVICE:   Char $i: "$char" (U+$codeUnit)');
    }
    
    // Common Arabic prefixes in order of preference (longer first)
    // Note: ٱ (U+0671) is alif wasla, different from regular alif ا (U+0627)
    final prefixes = [
      'لِلْ',     // lil (li + al) - for/to the
      'ٱلْ',      // al- with alif wasla (more common in Quranic text)
      'الْ',      // al- with regular alif
      'ٱل',       // al- with alif wasla (no sukun)
      'ال',       // al- with regular alif (no sukun)
      'لـ',       // li- for/to  
      'بـ',       // bi- with/by
      'فـ',       // fa- and/so
      'كـ',       // ka- like/as
      'وَ',       // wa- and
    ];
    
    for (final prefix in prefixes) {
      if (word.startsWith(prefix)) {
        final stripped = word.substring(prefix.length);
        if (stripped.isNotEmpty) {
          variants.add(stripped);
          print('DICTIONARY_SERVICE: Arabic prefix variant: removed "$prefix" from "$word" -> "$stripped"');
        }
      }
    }
    
    // If no prefix matched, also try a more generic approach for definite article
    // Look for al- pattern with any alif variant
    if (variants.isEmpty && word.length > 2) {
      // Check for alif + lam pattern at start
      final firstChar = word[0];
      final secondChar = word[1];
      
      // Various alif characters: ا (U+0627), ٱ (U+0671), أ (U+0623), etc.
      final isAlif = firstChar.codeUnitAt(0) == 0x0627 || // regular alif
                     firstChar.codeUnitAt(0) == 0x0671 || // alif wasla
                     firstChar.codeUnitAt(0) == 0x0623;   // alif with hamza above
      
      final isLam = secondChar.codeUnitAt(0) == 0x0644; // lam
      
      if (isAlif && isLam) {
        // Try stripping first 2 characters (alif + lam)
        final stripped = word.substring(2);
        if (stripped.isNotEmpty) {
          variants.add(stripped);
          print('DICTIONARY_SERVICE: Arabic generic al- variant: removed "${word.substring(0, 2)}" from "$word" -> "$stripped"');
        }
      }
    }
    
    print('DICTIONARY_SERVICE: Generated ${variants.length} Arabic variants: $variants');
    return variants;
  }

  /// Strip Arabic diacritical marks from a word for dictionary lookup
  String _stripArabicDiacritics(String word) {
    // Arabic diacritical marks (tashkeel) Unicode ranges:
    // U+064B to U+065F: Arabic diacritics
    // U+0670: Arabic letter superscript alef
    // U+06D6 to U+06ED: Arabic small high marks and other diacritics
    // U+06DF to U+06E8: More Arabic diacritics
    // U+06EA to U+06ED: Arabic empty centre marks
    // U+08D3 to U+08E1: Arabic small high marks
    // U+08E3 to U+08FF: More Arabic diacritics
    
    final diacriticPattern = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED\u08D3-\u08E1\u08E3-\u08FF]');
    final stripped = word.replaceAll(diacriticPattern, '');
    
    if (stripped != word) {
      print('DICTIONARY_SERVICE: Stripped diacritics: "$word" -> "$stripped"');
    }
    
    return stripped;
  }

  /// Generate Arabic word variants by progressively stripping common suffixes (personal pronouns)
  List<String> _getArabicSuffixVariants(String word) {
    final variants = <String>[];
    
    // Debug: show the word characters and their Unicode values
    print('DICTIONARY_SERVICE: Analyzing Arabic word "$word" for suffixes');
    
    // Common Arabic personal pronoun suffixes in Classical Arabic (longer first for better matching)
    final suffixes = [
      'هُمَا',   // -humā (their - dual)
      'كُمَا',   // -kumā (your - dual)
      'هُنَّ',   // -hunna (their - feminine plural)
      'كُنَّ',   // -kunna (your - feminine plural)
      'تُمَا',   // -tumā (you - dual)
      'هِمۡ',    // -him (their - with small high meem, Quranic)
      'هُمْ',    // -hum (their - masculine plural)
      'كُمْ',    // -kum (your - masculine plural)
      'تُمْ',    // -tum (you - masculine plural)
      'تُنَّ',   // -tunna (you - feminine plural)
      'نِي',     // -nī (me)
      'كَ',      // -ka (your - masculine)
      'كِ',      // -ki (your - feminine)
      'هُ',      // -hu (his)
      'هِ',      // -hi (her/its)
      'هَا',     // -hā (her/its)
      'نَا',     // -nā (our/us)
      'كُمُ',    // -kumu (variant of -kum)
      'هُمُ',    // -humu (variant of -hum)
    ];
    
    // First try with diacritics intact (preserves dagger alif!)
    for (final suffix in suffixes) {
      if (word.endsWith(suffix)) {
        final stripped = word.substring(0, word.length - suffix.length);
        if (stripped.isNotEmpty) {
          variants.add(stripped);
          print('DICTIONARY_SERVICE: Arabic suffix variant (with diacritics): removed "$suffix" from "$word" -> "$stripped"');
        }
      }
    }
    
    // Then try matching suffixes without diacritics but preserve the root structure
    final noDiacriticsWord = _stripArabicDiacritics(word);
    if (noDiacriticsWord != word) {
      final noDiacriticsSuffixes = [
        'هما',   // humā
        'كما',   // kumā  
        'هن',    // hunna
        'كن',    // kunna
        'تما',   // tumā
        'هم',    // hum (including him with small high meem)
        'كم',    // kum
        'تم',    // tum
        'تن',    // tunna
        'ني',    // nī
        'ك',     // ka/ki
        'ه',     // hu/hi
        'ها',    // hā
        'نا',    // nā
      ];
      
      for (final suffix in noDiacriticsSuffixes) {
        if (noDiacriticsWord.endsWith(suffix)) {
          // Strip suffix from original word, not the diacritics-free version
          // This preserves dagger alif and other important diacritics
          final suffixLength = suffix.length;
          if (word.length > suffixLength) {
            // Find where to cut in the original word by working backwards
            final originalStripped = _stripSuffixFromOriginal(word, suffix, noDiacriticsWord);
            if (originalStripped != null && !variants.contains(originalStripped)) {
              variants.add(originalStripped);
              print('DICTIONARY_SERVICE: Arabic suffix variant (mapped from no-diacritics): removed "$suffix" -> "$originalStripped"');
            }
          }
        }
      }
    }
    
    print('DICTIONARY_SERVICE: Generated ${variants.length} Arabic suffix variants: $variants');
    return variants;
  }

  /// Generate Arabic word variants by replacing dagger alif with regular alif (Quranic → modern spelling)
  List<String> _getArabicDaggerAlifVariants(String word) {
    final variants = <String>[];
    
    // Check if the word contains dagger alif (ٰ - U+0670)
    if (word.contains('\u0670')) {
      print('DICTIONARY_SERVICE: Analyzing Arabic word "$word" for dagger alif replacement');
      
      // Replace dagger alif (ٰ) with regular alif (ا)
      final withRegularAlif = word.replaceAll('\u0670', '\u0627');
      if (withRegularAlif != word) {
        variants.add(withRegularAlif);
        print('DICTIONARY_SERVICE: Dagger alif variant: "$word" -> "$withRegularAlif"');
        
        // Also try the variant without any diacritics
        final withoutDiacritics = _stripArabicDiacritics(withRegularAlif);
        if (withoutDiacritics != withRegularAlif && !variants.contains(withoutDiacritics)) {
          variants.add(withoutDiacritics);
          print('DICTIONARY_SERVICE: Dagger alif variant (no diacritics): "$withRegularAlif" -> "$withoutDiacritics"');
        }
      }
    }
    
    print('DICTIONARY_SERVICE: Generated ${variants.length} Arabic dagger alif variants: $variants');
    return variants;
  }

  /// Helper method to strip suffix from original word while preserving diacritics structure
  String? _stripSuffixFromOriginal(String originalWord, String suffix, String noDiacriticsWord) {
    // Work backwards from the end to find where to cut the original word
    // The suffix was found in the no-diacritics version, so we need to map back
    final suffixLength = suffix.length;
    final noDiacriticsLength = noDiacriticsWord.length;
    final originalLength = originalWord.length;
    
    // Simple approach: remove the last few characters that correspond to the suffix
    // This preserves diacritics in the root while removing the suffix
    if (originalLength > suffixLength) {
      // Calculate how many characters to remove from original
      // This is a heuristic since diacritics can affect the mapping
      final cutPosition = originalLength - suffixLength;
      final stripped = originalWord.substring(0, cutPosition);
      
      // Verify this makes sense by checking the stripped version
      final strippedNoDiacritics = _stripArabicDiacritics(stripped);
      final expectedRoot = noDiacriticsWord.substring(0, noDiacriticsLength - suffixLength);
      
      if (strippedNoDiacritics == expectedRoot) {
        return stripped;
      }
    }
    
    return null;
  }
}