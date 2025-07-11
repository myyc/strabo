import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/dictionary_entry.dart';
import '../../models/language.dart';
import '../dictionary_provider.dart';

class WiktionaryProvider extends DictionaryProvider {
  static const String _baseUrl = 'https://en.wiktionary.org/api/rest_v1';
  static const String _searchApiUrl = 'https://en.wiktionary.org/w/api.php';

  @override
  String get name => 'Wiktionary';

  @override
  List<LanguageType> get supportedLanguages => [
    LanguageType.greek,
    LanguageType.arabic,
  ];

  @override
  Future<List<DictionaryEntry>> lookup(String word, LanguageType language) async {
    if (!supportsLanguage(language)) {
      throw UnsupportedError('Wiktionary does not support ${language.name}');
    }

    try {
      // Use Wiktionary's definition API
      final url = Uri.parse('$_baseUrl/page/definition/$word');
      
      print('WIKTIONARY: Looking up word "$word" for language ${language.name}');
      print('WIKTIONARY: Request URL: $url');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Strabo Language Learning App',
      });

      print('WIKTIONARY: Response status: ${response.statusCode}');
      print('WIKTIONARY: Response length: ${response.body.length} characters');

      if (response.statusCode == 404) {
        print('WIKTIONARY: Word "$word" not found (404), trying content search...');
        // Fallback to content search for inflected forms
        return await _searchInContent(word, language);
      }

      if (response.statusCode != 200) {
        print('WIKTIONARY: Server error: ${response.statusCode}');
        throw Exception('Wiktionary server error: ${response.statusCode}');
      }

      print('WIKTIONARY: Response body preview: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...');

      final data = jsonDecode(response.body);
      print('WIKTIONARY: Parsed JSON structure: ${data.runtimeType}');
      print('WIKTIONARY: JSON keys: ${data is Map ? data.keys.toList() : "Not a map"}');
      
      final result = _parseWiktionaryResponse(word, data, language);
      print('WIKTIONARY: Returning ${result.length} entries for word "$word"');
      return result;
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      throw Exception('Wiktionary lookup failed: $e');
    }
  }

  @override
  Future<List<MorphologicalInfo>> getMorphology(String word, LanguageType language) async {
    // Wiktionary doesn't provide structured morphological analysis
    // but we could potentially extract some info from definitions
    return [];
  }

  List<DictionaryEntry> _parseWiktionaryResponse(String word, dynamic data, LanguageType language) {
    final entries = <DictionaryEntry>[];
    
    try {
      print('WIKTIONARY: Parsing response structure for word "$word"');
      
      if (data is Map) {
        // Check for different possible structures
        final keys = data.keys.toList();
        print('WIKTIONARY: Available keys: $keys');
        
        // Try multiple possible structures
        for (final key in keys) {
          final sectionData = data[key];
          print('WIKTIONARY: Processing section "$key" with type ${sectionData.runtimeType}');
          
          if (sectionData is List) {
            for (final section in sectionData) {
              if (section is Map) {
                print('WIKTIONARY: Section contains: ${section.keys.toList()}');
                
                // Look for definitions in various places
                dynamic definitionsData;
                if (section.containsKey('definitions')) {
                  definitionsData = section['definitions'];
                } else if (section.containsKey('definition')) {
                  definitionsData = [section]; // Wrap single definition
                }
                
                if (definitionsData != null) {
                  final definitions = _parseDefinitions(definitionsData, language);
                  if (definitions.isNotEmpty) {
                    print('WIKTIONARY: Found ${definitions.length} definitions in section "$key"');
                    entries.add(DictionaryEntry(
                      word: word,
                      lemma: word,
                      definitions: definitions,
                      source: name,
                    ));
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('WIKTIONARY: Parse error: $e');
    }

    return entries;
  }

  List<Definition> _parseDefinitions(dynamic definitionsData, LanguageType language) {
    final definitions = <Definition>[];
    
    print('WIKTIONARY: Parsing definitions data: ${definitionsData.runtimeType}');
    
    if (definitionsData is List) {
      for (final def in definitionsData) {
        if (def is Map) {
          print('WIKTIONARY: Definition map keys: ${def.keys.toList()}');
          
          String? text;
          String? partOfSpeech;
          
          // Try different possible keys for definition text
          if (def.containsKey('definition')) {
            text = def['definition'].toString();
          } else if (def.containsKey('definitions')) {
            // Handle nested definitions
            final nestedDefs = def['definitions'];
            if (nestedDefs is List && nestedDefs.isNotEmpty) {
              text = nestedDefs.first.toString();
            }
          }
          
          // Try different possible keys for part of speech
          if (def.containsKey('partOfSpeech')) {
            partOfSpeech = def['partOfSpeech'].toString();
          }
          
          if (text != null && text.isNotEmpty) {
            // Check if this is a morphological description and extract lemma info
            final morphInfo = _analyzeMorphologicalDescription(text, language);
            
            // Clean up HTML tags from definition text  
            final cleanText = text
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            
            if (cleanText.isNotEmpty) {
              print('WIKTIONARY: Adding definition: ${cleanText.substring(0, cleanText.length > 100 ? 100 : cleanText.length)}...');
              if (morphInfo != null) {
                print('WIKTIONARY: Detected morphological reference to lemma: ${morphInfo['lemma']}');
              }
              
              // For Arabic, handle multiple lemmas (Form I/II verbs, etc.)
              if (morphInfo != null && language == LanguageType.arabic && morphInfo.containsKey('allLemmas')) {
                final allLemmas = morphInfo['allLemmas']!.split(',');
                // Create separate definitions for each lemma reference
                for (final lemma in allLemmas) {
                  definitions.add(Definition(
                    text: cleanText,
                    partOfSpeech: partOfSpeech,
                    isMorphological: true,
                    referencedLemma: lemma.trim(),
                  ));
                }
              } else {
                definitions.add(Definition(
                  text: cleanText,
                  partOfSpeech: partOfSpeech,
                  isMorphological: morphInfo != null,
                  referencedLemma: morphInfo?['lemma'],
                ));
              }
            }
          }
        }
      }
    }
    
    print('WIKTIONARY: Parsed ${definitions.length} definitions');
    return definitions;
  }

  String _getLanguageCode(LanguageType language) {
    switch (language) {
      case LanguageType.greek:
        return 'Greek'; // Ancient Greek in Wiktionary
      case LanguageType.arabic:
        return 'Arabic';
    }
  }

  /// Analyzes definition text to detect morphological descriptions and extract lemma references
  Map<String, String>? _analyzeMorphologicalDescription(String htmlText, LanguageType targetLanguage) {
    final allLemmas = <String>[];
    
    // Extract lemma from HTML links first - find ALL links in target language
    final linkMatches = RegExp(r'<a[^>]*href="[^"]*\/wiki\/([^"]+)"[^>]*>([^<]+)</a>')
        .allMatches(htmlText);
    
    for (final linkMatch in linkMatches) {
      final lemmaFromLink = linkMatch.group(2)?.trim();
      if (lemmaFromLink != null && lemmaFromLink.isNotEmpty) {
        // Only follow links that contain characters in the target language
        if (_containsTargetLanguageCharacters(lemmaFromLink, targetLanguage)) {
          allLemmas.add(lemmaFromLink);
          print('WIKTIONARY: Found ${targetLanguage.name} lemma link: $lemmaFromLink');
        } else {
          print('WIKTIONARY: Skipping non-${targetLanguage.name} link: $lemmaFromLink');
        }
      }
    }
    
    // For Arabic, also look for morphological patterns that indicate verb forms
    if (targetLanguage == LanguageType.arabic) {
      // Arabic-specific patterns for verb forms and morphological descriptions
      final arabicPatterns = [
        // "third-person masculine plural non-past active indicative of [verb]"
        RegExp(r'(?:first|second|third)-person\s+(?:masculine|feminine)\s+(?:singular|plural|dual)\s+(?:past|non-past)\s+(?:active|passive)\s+(?:indicative|subjunctive|jussive)\s+of\s+([^\s<\(,]+)', caseSensitive: false),
        // "Form I/II/III etc."
        RegExp(r'Form\s+[IVX]+\s+of\s+([^\s<\(,]+)', caseSensitive: false),
        // "masculine plural of [word]"
        RegExp(r'(?:masculine|feminine)\s+(?:singular|plural|dual)\s+of\s+([^\s<\(,]+)', caseSensitive: false),
        // Generic Arabic "of [word]" pattern
        RegExp(r'\bof\s+([^\s<\(,]+)', caseSensitive: false),
      ];
      
      for (final pattern in arabicPatterns) {
        final matches = pattern.allMatches(htmlText);
        for (final match in matches) {
          final lemma = match.group(1)?.trim();
          if (lemma != null && lemma.isNotEmpty) {
            if (_containsTargetLanguageCharacters(lemma, targetLanguage)) {
              allLemmas.add(lemma);
              print('WIKTIONARY: Found Arabic lemma from pattern: $lemma');
            }
          }
        }
      }
    } else {
      // Greek and other language patterns
      final patterns = [
        // Generic "of [word]" pattern - should catch most cases
        RegExp(r'\bof\s+([^\s<\(]+)', caseSensitive: false),
        // "third person singular of φημί"
        RegExp(r'(?:first|second|third)\s+person\s+(?:singular|plural|dual)\s+.*?\s+of\s+([^\s<\(]+)', caseSensitive: false),
        // "genitive plural of δῶρον"
        RegExp(r'(?:nominative|genitive|dative|accusative|vocative)\s+(?:singular|plural|dual)\s+of\s+([^\s<\(]+)', caseSensitive: false),
        // "aorist indicative of λέγω"
        RegExp(r'(?:present|aorist|imperfect|perfect|pluperfect|future)\s+(?:indicative|subjunctive|optative|imperative|infinitive|participle)\s+of\s+([^\s<\(]+)', caseSensitive: false),
        // "comparative form of καλός"
        RegExp(r'(?:comparative|superlative)\s+(?:form\s+)?of\s+([^\s<\(]+)', caseSensitive: false),
        // "feminine of ἀγαθός"
        RegExp(r'(?:masculine|feminine|neuter)\s+(?:form\s+)?of\s+([^\s<\(]+)', caseSensitive: false),
        // "apocopic form of δέ"
        RegExp(r'(?:apocopic|contracted|augmented)\s+(?:form\s+)?of\s+([^\s<\(]+)', caseSensitive: false),
        // Generic "X of Y" pattern as fallback
        RegExp(r'\b(?:form|variant)\s+of\s+([^\s<\(]+)', caseSensitive: false),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(htmlText);
        if (match != null) {
          final lemma = match.group(1)?.trim();
          if (lemma != null && lemma.isNotEmpty) {
            if (_containsTargetLanguageCharacters(lemma, targetLanguage)) {
              allLemmas.add(lemma);
              print('WIKTIONARY: Found ${targetLanguage.name} lemma from pattern: $lemma');
            }
          }
        }
      }
    }
    
    // Return the first lemma found, or null if none
    if (allLemmas.isNotEmpty) {
      // For Arabic, prefer the first lemma found (prioritize links over patterns)
      return {'lemma': allLemmas.first, 'allLemmas': allLemmas.join(',')};
    }
    
    return null;
  }

  /// Check if a string contains characters for the target language
  bool _containsTargetLanguageCharacters(String text, LanguageType targetLanguage) {
    switch (targetLanguage) {
      case LanguageType.greek:
        return _containsGreekCharacters(text);
      case LanguageType.arabic:
        return _containsArabicCharacters(text);
      default:
        return false;
    }
  }

  /// Check if a string contains Greek characters (Unicode Greek and Extended blocks)
  bool _containsGreekCharacters(String text) {
    // Greek Unicode blocks: 
    // - Greek and Coptic: U+0370-U+03FF
    // - Greek Extended: U+1F00-U+1FFF
    // - Combining Diacriticals: U+0300-U+036F (for diaeresis, etc.)
    // Be more permissive - if it contains ANY Greek characters, consider it Greek
    final greekPattern = RegExp(r'[\u0370-\u03FF\u1F00-\u1FFF]');
    final hasGreek = greekPattern.hasMatch(text);
    
    // Debug logging for Greek character detection
    print('WIKTIONARY: Checking if "$text" contains Greek characters: $hasGreek');
    if (hasGreek) {
      // Show which characters matched
      final matches = greekPattern.allMatches(text);
      for (final match in matches) {
        final char = match.group(0);
        final codeUnit = char?.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
        print('WIKTIONARY: Found Greek character "$char" (U+$codeUnit)');
      }
    } else {
      // Show what characters we found instead
      print('WIKTIONARY: Characters in "$text":');
      for (int i = 0; i < text.length; i++) {
        final char = text[i];
        final codeUnit = char.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
        print('WIKTIONARY:   "$char" (U+$codeUnit)');
      }
    }
    
    return hasGreek;
  }

  /// Check if a string contains Arabic characters (Unicode Arabic blocks)
  bool _containsArabicCharacters(String text) {
    // Arabic Unicode blocks:
    // - Arabic: U+0600-U+06FF
    // - Arabic Supplement: U+0750-U+077F
    // - Arabic Extended-A: U+08A0-U+08FF
    // - Arabic Presentation Forms-A: U+FB50-U+FDFF
    // - Arabic Presentation Forms-B: U+FE70-U+FEFF
    final arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    final hasArabic = arabicPattern.hasMatch(text);
    
    // Debug logging for Arabic character detection
    print('WIKTIONARY: Checking if "$text" contains Arabic characters: $hasArabic');
    if (hasArabic) {
      // Show which characters matched
      final matches = arabicPattern.allMatches(text);
      for (final match in matches) {
        final char = match.group(0);
        final codeUnit = char?.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
        print('WIKTIONARY: Found Arabic character "$char" (U+$codeUnit)');
      }
    } else {
      // Show what characters we found instead
      print('WIKTIONARY: Characters in "$text":');
      for (int i = 0; i < text.length; i++) {
        final char = text[i];
        final codeUnit = char.codeUnitAt(0).toRadixString(16).padLeft(4, '0');
        print('WIKTIONARY:   "$char" (U+$codeUnit)');
      }
    }
    
    return hasArabic;
  }

  /// Search for inflected forms within page content using MediaWiki search API
  Future<List<DictionaryEntry>> _searchInContent(String word, LanguageType language) async {
    try {
      print('WIKTIONARY: Searching for "$word" in page content...');
      
      // Use MediaWiki search API with content search
      final searchUrl = Uri.parse(_searchApiUrl).replace(queryParameters: {
        'action': 'query',
        'list': 'search',
        'srwhat': 'text',
        'srsearch': word, // Search without quotes for broader matches
        'srlimit': '10', // Limit results to avoid too many API calls
        'format': 'json',
      });
      
      print('WIKTIONARY: Content search URL: $searchUrl');
      
      final response = await http.get(searchUrl, headers: {
        'User-Agent': 'Strabo Language Learning App',
      });
      
      print('WIKTIONARY: Content search response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('WIKTIONARY: Content search failed: ${response.statusCode}');
        return [];
      }
      
      final data = jsonDecode(response.body);
      print('WIKTIONARY: Content search response keys: ${data.keys.toList()}');
      
      if (data['query'] == null || data['query']['search'] == null) {
        print('WIKTIONARY: No search results found in content, trying broader search...');
        // Try a broader search by removing diacritics
        return await _searchInContentBroader(word, language);
      }
      
      final searchResults = data['query']['search'] as List;
      print('WIKTIONARY: Found ${searchResults.length} content search results');
      
      // Process search results to find potential lemmas
      final entries = <DictionaryEntry>[];
      
      for (final result in searchResults) {
        if (result is Map<String, dynamic>) {
          final title = result['title'] as String?;
          final snippet = result['snippet'] as String?;
          
          if (title != null && _isPotentialLemma(title, language)) {
            print('WIKTIONARY: Processing potential lemma: "$title"');
            
            // Try to get the definition for this lemma
            final lemmaEntries = await _lookupLemmaForInflectedForm(title, word, language, snippet);
            entries.addAll(lemmaEntries);
            
            // Limit to avoid too many API calls
            if (entries.length >= 3) break;
          }
        }
      }
      
      print('WIKTIONARY: Content search returned ${entries.length} entries');
      return entries;
      
    } catch (e) {
      print('WIKTIONARY: Content search error: $e');
      return [];
    }
  }

  /// Check if a page title is likely to be a lemma for the given language
  bool _isPotentialLemma(String title, LanguageType language) {
    // Filter out non-main namespace pages and non-target language pages
    if (title.contains(':') || title.contains('/')) {
      return false;
    }
    
    // Check if title contains characters from target language
    if (!_containsTargetLanguageCharacters(title, language)) {
      return false;
    }
    
    // Language-specific heuristics for lemma identification
    switch (language) {
      case LanguageType.greek:
        // Greek verbs often end in -ω, -μι
        // Nouns and adjectives have various endings
        return title.length >= 2 && title.length <= 20;
        
      case LanguageType.arabic:
        // Arabic roots are typically 3-4 consonants
        // Prefer shorter forms that are more likely to be lemmas
        return title.length >= 2 && title.length <= 15;
    }
  }

  /// Lookup a lemma and create morphological entry for the inflected form
  Future<List<DictionaryEntry>> _lookupLemmaForInflectedForm(
    String lemmaTitle, 
    String inflectedForm, 
    LanguageType language,
    String? searchSnippet,
  ) async {
    try {
      // Try to get the lemma's definition using the REST API
      final url = Uri.parse('$_baseUrl/page/definition/$lemmaTitle');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Strabo Language Learning App',
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lemmaEntries = _parseWiktionaryResponse(lemmaTitle, data, language);
        
        // Create morphological entries that reference the lemma
        final morphEntries = <DictionaryEntry>[];
        
        for (final lemmaEntry in lemmaEntries) {
          // Create a morphological definition that points to the lemma
          final morphDefinition = Definition(
            text: 'Inflected form of $lemmaTitle',
            isMorphological: true,
            referencedLemma: lemmaTitle,
            lemmaDefinitions: lemmaEntry.definitions,
          );
          
          morphEntries.add(DictionaryEntry(
            word: inflectedForm,
            lemma: lemmaTitle,
            definitions: [morphDefinition],
            source: name,
          ));
        }
        
        return morphEntries;
      }
      
    } catch (e) {
      print('WIKTIONARY: Error looking up lemma "$lemmaTitle": $e');
    }
    
    return [];
  }

  /// Broader content search using stripped diacritics or morphological variants
  Future<List<DictionaryEntry>> _searchInContentBroader(String word, LanguageType language) async {
    try {
      print('WIKTIONARY: Trying broader search for "$word"...');
      
      // Try searching for the word without diacritics
      String searchTerm = word;
      if (language == LanguageType.arabic) {
        // Strip Arabic diacritics for broader search
        final diacriticPattern = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED\u08D3-\u08E1\u08E3-\u08FF]');
        searchTerm = word.replaceAll(diacriticPattern, '');
      } else if (language == LanguageType.greek) {
        // For Greek, try searching with basic characters
        searchTerm = word.toLowerCase();
      }
      
      if (searchTerm != word) {
        print('WIKTIONARY: Searching with simplified form: "$searchTerm"');
        
        final searchUrl = Uri.parse(_searchApiUrl).replace(queryParameters: {
          'action': 'query',
          'list': 'search',
          'srwhat': 'text',
          'srsearch': searchTerm,
          'srlimit': '5', // Fewer results for broader search
          'format': 'json',
        });
        
        final response = await http.get(searchUrl, headers: {
          'User-Agent': 'Strabo Language Learning App',
        });
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['query'] != null && data['query']['search'] != null) {
            final searchResults = data['query']['search'] as List;
            print('WIKTIONARY: Found ${searchResults.length} broader search results');
            
            final entries = <DictionaryEntry>[];
            
            for (final result in searchResults) {
              if (result is Map<String, dynamic>) {
                final title = result['title'] as String?;
                
                if (title != null && _isPotentialLemma(title, language)) {
                  print('WIKTIONARY: Processing broader search lemma: "$title"');
                  
                  final lemmaEntries = await _lookupLemmaForInflectedForm(title, word, language, null);
                  entries.addAll(lemmaEntries);
                  
                  if (entries.length >= 2) break; // Limit for broader search
                }
              }
            }
            
            return entries;
          }
        }
      }
      
    } catch (e) {
      print('WIKTIONARY: Broader search error: $e');
    }
    
    return [];
  }
}