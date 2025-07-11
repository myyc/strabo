import 'package:http/http.dart' as http;
import '../../models/dictionary_entry.dart';
import '../../models/language.dart';
import '../dictionary_provider.dart';

class PerseusProvider extends DictionaryProvider {
  static const String _baseUrl = 'http://www.perseus.tufts.edu/hopper';
  static const String _lexiconUrl = '$_baseUrl/morph';

  @override
  String get name => 'Perseus Digital Library';

  @override
  List<LanguageType> get supportedLanguages => [
    LanguageType.greek,
    // LanguageType.latin, // TODO: Add Latin support
  ];

  @override
  Future<List<DictionaryEntry>> lookup(String word, LanguageType language) async {
    if (!supportsLanguage(language)) {
      throw UnsupportedError('Perseus does not support ${language.name}');
    }

    try {
      final entries = <DictionaryEntry>[];
      
      // Try LSJ lookup for Greek
      if (language == LanguageType.greek) {
        final lsjEntries = await _lookupLSJ(word);
        entries.addAll(lsjEntries);
      }

      return entries;
    } catch (e) {
      throw Exception('Perseus lookup failed: $e');
    }
  }

  @override
  Future<List<MorphologicalInfo>> getMorphology(String word, LanguageType language) async {
    if (!supportsLanguage(language)) {
      return [];
    }

    try {
      return await _getMorphologyFromPerseus(word, language);
    } catch (e) {
      // Morphology errors are non-fatal
      return [];
    }
  }

  Future<List<DictionaryEntry>> _lookupLSJ(String word) async {
    // Perseus LSJ lookup via their morph tool
    final url = Uri.parse('$_lexiconUrl?l=$word&la=greek');
    
    print('PERSEUS: Looking up word "$word"');
    print('PERSEUS: Request URL: $url');
    
    final response = await http.get(url, headers: {
      'User-Agent': 'Strabo Language Learning App',
    });

    print('PERSEUS: Response status: ${response.statusCode}');
    print('PERSEUS: Response headers: ${response.headers}');
    print('PERSEUS: Response length: ${response.body.length} characters');
    
    // Log the FULL response to understand the structure
    print('PERSEUS: ===== FULL API RESPONSE START =====');
    print(response.body);
    print('PERSEUS: ===== FULL API RESPONSE END =====');

    if (response.statusCode != 200) {
      throw Exception('Perseus server error: ${response.statusCode}');
    }

    // Parse HTML response to extract dictionary entries
    // Note: This is a simplified parser - in production, we'd want
    // to use a proper HTML parser like html package
    final entries = <DictionaryEntry>[];
    final htmlContent = response.body;

    // Look specifically for lemma entries which contain the actual dictionary content
    print('PERSEUS: Searching for lemma entries');
    
    final lemmaPattern = RegExp(
      r'<div[^>]*class="lemma"[^>]*>(.*?)</div>(?=\s*<div|\s*</div>|\s*$)',
      dotAll: true,
    );
    
    final matches = lemmaPattern.allMatches(htmlContent);
    print('PERSEUS: Found ${matches.length} lemma entries');
    
    for (final match in matches) {
      final entryHtml = match.group(1) ?? '';
      print('PERSEUS: Processing entry HTML: ${entryHtml.length > 200 ? entryHtml.substring(0, 200) + "..." : entryHtml}');
      final entry = _parseHTMLEntry(word, entryHtml);
      if (entry != null) {
        print('PERSEUS: Successfully parsed entry: ${entry.definitions.first.text.substring(0, entry.definitions.first.text.length > 100 ? 100 : entry.definitions.first.text.length)}...');
        entries.add(entry);
      } else {
        print('PERSEUS: Failed to parse entry from HTML');
      }
    }

    print('PERSEUS: Returning ${entries.length} entries for word "$word"');
    return entries;
  }

  DictionaryEntry? _parseHTMLEntry(String word, String html) {
    // Skip navigation links and empty divs
    if (html.contains('new_window_link') || html.trim().isEmpty) {
      return null;
    }
    
    // Extract Greek word from <h4 class="greek"> tag
    String? greekWord;
    final greekWordMatch = RegExp(r'<h4[^>]*class="greek"[^>]*>(.*?)</h4>').firstMatch(html);
    if (greekWordMatch != null) {
      greekWord = greekWordMatch.group(1)?.trim();
    }
    
    // Extract definition from <span class="lemma_definition"> tag
    String? definition;
    final definitionMatch = RegExp(r'<span[^>]*class="lemma_definition"[^>]*>(.*?)</span>', dotAll: true).firstMatch(html);
    if (definitionMatch != null) {
      definition = definitionMatch.group(1)
          ?.replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    
    // If we couldn't extract structured content, fall back to basic extraction
    if (definition == null || definition.isEmpty) {
      final textContent = html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      if (textContent.isEmpty || textContent.length < 10) {
        return null;
      }
      definition = textContent;
    }
    
    // Skip entries that are just "[definition unavailable]"
    if (definition.contains('[definition unavailable]') && definition.length < 30) {
      return null;
    }

    final definitions = [
      Definition(
        text: definition,
        partOfSpeech: _extractPartOfSpeech(html),
      ),
    ];

    return DictionaryEntry(
      word: word,
      lemma: greekWord ?? word, // Use extracted Greek word as lemma
      definitions: definitions,
      source: name,
    );
  }

  String? _extractPartOfSpeech(String html) {
    // Look for common part of speech indicators in Perseus HTML
    final posPattern = RegExp(r'\b(noun|verb|adj|adv|prep|conj|part|pron)\b', caseSensitive: false);
    final match = posPattern.firstMatch(html);
    return match?.group(0);
  }

  Future<List<MorphologicalInfo>> _getMorphologyFromPerseus(String word, LanguageType language) async {
    final langCode = language == LanguageType.greek ? 'greek' : 'latin';
    final url = Uri.parse('$_lexiconUrl?l=$word&la=$langCode');
    
    final response = await http.get(url, headers: {
      'User-Agent': 'Strabo Language Learning App',
    });

    if (response.statusCode != 200) {
      return [];
    }

    // Parse morphological information from Perseus response
    final morphInfoList = <MorphologicalInfo>[];
    final htmlContent = response.body;

    // Look for morphology tables in Perseus HTML
    final morphPattern = RegExp(
      r'<table[^>]*class="[^"]*analysis[^"]*"[^>]*>(.*?)</table>',
      dotAll: true,
    );

    final matches = morphPattern.allMatches(htmlContent);
    
    for (final match in matches) {
      final tableHtml = match.group(1) ?? '';
      final morphInfo = _parseMorphologyTable(tableHtml);
      if (morphInfo != null) {
        morphInfoList.add(morphInfo);
      }
    }

    return morphInfoList;
  }

  MorphologicalInfo? _parseMorphologyTable(String tableHtml) {
    // Parse Perseus morphology table
    // This is simplified - in production we'd parse the actual table structure
    
    final features = <String, String>{};
    
    // Look for common morphological features
    if (tableHtml.contains('nominative')) features['case'] = 'nominative';
    if (tableHtml.contains('genitive')) features['case'] = 'genitive';
    if (tableHtml.contains('dative')) features['case'] = 'dative';
    if (tableHtml.contains('accusative')) features['case'] = 'accusative';
    if (tableHtml.contains('vocative')) features['case'] = 'vocative';
    
    if (tableHtml.contains('singular')) features['number'] = 'singular';
    if (tableHtml.contains('plural')) features['number'] = 'plural';
    if (tableHtml.contains('dual')) features['number'] = 'dual';
    
    if (tableHtml.contains('masculine')) features['gender'] = 'masculine';
    if (tableHtml.contains('feminine')) features['gender'] = 'feminine';
    if (tableHtml.contains('neuter')) features['gender'] = 'neuter';

    if (features.isEmpty) return null;

    return MorphologicalInfo(
      case_: features['case'],
      number: features['number'],
      gender: features['gender'],
      additionalFeatures: features,
    );
  }
}