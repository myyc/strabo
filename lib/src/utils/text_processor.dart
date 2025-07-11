import '../models/language.dart';

class TextProcessor {
  /// Process raw text content with various cleaning options
  static String processText(
    String rawText, {
    required LanguageType language,
    bool removeVerseNumbers = true,
    bool preserveLineBreaks = true,
    bool cleanWhitespace = true,
  }) {
    if (rawText.isEmpty) return rawText;
    
    String result = rawText;
    
    // Remove verse numbers if requested
    if (removeVerseNumbers) {
      result = _removeVerseNumbers(result);
    }
    
    // Handle line breaks
    if (preserveLineBreaks) {
      result = _preserveLineBreaks(result);
    } else {
      result = _mergeLines(result);
    }
    
    // Clean whitespace
    if (cleanWhitespace) {
      result = _cleanWhitespace(result);
    }
    
    // Language-specific processing
    result = _processLanguageSpecific(result, language);
    
    return result.trim();
  }

  /// Remove common verse numbering patterns
  static String _removeVerseNumbers(String text) {
    String result = text;
    
    // Remove patterns like "1. ", "1 ", "[1] ", "(1) " at start of lines
    result = result.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\s*\d+\s+', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\s*\[\d+\]\s*', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\s*\(\d+\)\s*', multiLine: true), '');
    
    // Remove inline verse numbers like "1word" -> "word"
    result = result.replaceAllMapped(RegExp(r'\b\d+(\w)'), (match) => match.group(1) ?? '');
    
    // Remove standalone numbers between words, preserve line structure
    result = result.replaceAll(RegExp(r'(?<=\s)\d+(?=\s)'), '');
    
    // Remove numbers at start/end of lines
    result = result.replaceAll(RegExp(r'^\d+\s*', multiLine: true), '');
    result = result.replaceAll(RegExp(r'\s*\d+$', multiLine: true), '');
    
    // Clean up multiple spaces but preserve line breaks
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    return result;
  }

  /// Preserve line breaks for poetry
  static String _preserveLineBreaks(String text) {
    // Normalize line endings
    String result = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Remove excessive blank lines (more than 2 consecutive)
    result = result.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    
    return result;
  }

  /// Merge lines for prose (paragraph-style)
  static String _mergeLines(String text) {
    String result = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Replace single line breaks with spaces, preserve double line breaks
    result = result.replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), ' ');
    
    // Clean up excessive spaces
    result = result.replaceAll(RegExp(r' +'), ' ');
    
    return result;
  }

  /// Clean up whitespace issues
  static String _cleanWhitespace(String text) {
    String result = text;
    
    // Remove trailing whitespace from lines
    result = result.replaceAll(RegExp(r'[ \t]+$', multiLine: true), '');
    
    // Remove leading whitespace from lines (except intentional indentation)
    result = result.replaceAll(RegExp(r'^[ \t]+', multiLine: true), '');
    
    // Replace multiple spaces with single space
    result = result.replaceAll(RegExp(r' +'), ' ');
    
    // Replace tabs with spaces
    result = result.replaceAll('\t', ' ');
    
    return result;
  }

  /// Language-specific processing
  static String _processLanguageSpecific(String text, LanguageType language) {
    switch (language) {
      case LanguageType.greek:
        return _processGreek(text);
      case LanguageType.arabic:
        return _processArabic(text);
      default:
        return text;
    }
  }

  /// Greek-specific processing
  static String _processGreek(String text) {
    String result = text;
    
    // Normalize Greek punctuation
    result = result.replaceAll('·', '·'); // Ensure proper middle dot
    result = result.replaceAll(';', '·'); // Replace semicolon with middle dot
    
    // Handle common Greek text artifacts
    result = result.replaceAll('ϊ', 'ϊ'); // Normalize diaeresis
    result = result.replaceAll('ϋ', 'ϋ'); // Normalize diaeresis
    
    // Remove any remaining Arabic numerals (Greek texts use Greek numerals if any)
    result = result.replaceAll(RegExp(r'\d+'), '');
    
    // Clean up extra spaces but preserve line breaks
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    return result;
  }

  /// Arabic-specific processing
  static String _processArabic(String text) {
    String result = text;
    
    // Normalize Arabic punctuation
    result = result.replaceAll('،', '،'); // Ensure proper Arabic comma
    result = result.replaceAll('؛', '؛'); // Ensure proper Arabic semicolon
    result = result.replaceAll('؟', '؟'); // Ensure proper Arabic question mark
    
    // Handle common Arabic text artifacts
    result = result.replaceAll('ك', 'ك'); // Normalize kaf
    result = result.replaceAll('ي', 'ي'); // Normalize yeh
    
    return result;
  }


  /// Extract potential title from first line
  static String? extractTitle(String text) {
    if (text.isEmpty) return null;
    
    final lines = text.split('\n');
    final firstLine = lines.first.trim();
    
    // If first line is short and likely a title
    if (firstLine.length > 3 && firstLine.length < 100) {
      // Check if it looks like a title (not starting with numbers, etc.)
      if (!RegExp(r'^\d+').hasMatch(firstLine)) {
        return firstLine;
      }
    }
    
    return null;
  }

  /// Basic language detection based on script
  static LanguageType? detectLanguage(String text) {
    if (text.isEmpty) return null;
    
    int greekCount = 0;
    int arabicCount = 0;
    int latinCount = 0;
    
    for (int i = 0; i < text.length && i < 200; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      
      // Greek and Greek Extended blocks
      if ((code >= 0x0370 && code <= 0x03FF) || (code >= 0x1F00 && code <= 0x1FFF)) {
        greekCount++;
      }
      // Arabic block
      else if (code >= 0x0600 && code <= 0x06FF) {
        arabicCount++;
      }
      // Latin blocks
      else if ((code >= 0x0041 && code <= 0x007A) || 
               (code >= 0x0080 && code <= 0x024F)) {
        latinCount++;
      }
    }
    
    if (greekCount > 5 && greekCount > arabicCount && greekCount > latinCount) {
      return LanguageType.greek;
    } else if (arabicCount > 5 && arabicCount > greekCount && arabicCount > latinCount) {
      return LanguageType.arabic;
    }
    
    return null;
  }
}