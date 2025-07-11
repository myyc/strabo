class TextNormalizer {
  static const Map<String, String> _greekDiacritics = {
    // Greek vowels with diacritics
    'ά': 'α', 'ἀ': 'α', 'ἁ': 'α', 'ἂ': 'α', 'ἃ': 'α', 'ἄ': 'α', 'ἅ': 'α', 'ἆ': 'α', 'ἇ': 'α',
    'ᾰ': 'α', 'ᾱ': 'α', 'ᾳ': 'α', 'ᾲ': 'α', 'ᾴ': 'α', 'ᾶ': 'α', 'ᾷ': 'α',
    'Ά': 'Α', 'Ἀ': 'Α', 'Ἁ': 'Α', 'Ἂ': 'Α', 'Ἃ': 'Α', 'Ἄ': 'Α', 'Ἅ': 'Α', 'Ἆ': 'Α', 'Ἇ': 'Α',
    'ᾈ': 'Α', 'ᾉ': 'Α', 'ᾊ': 'Α', 'ᾋ': 'Α', 'ᾌ': 'Α', 'ᾍ': 'Α', 'ᾎ': 'Α', 'ᾏ': 'Α',
    'Ᾰ': 'Α', 'Ᾱ': 'Α', 'Ὰ': 'Α', 'ᾼ': 'Α',
    
    'έ': 'ε', 'ἐ': 'ε', 'ἑ': 'ε', 'ἒ': 'ε', 'ἓ': 'ε', 'ἔ': 'ε', 'ἕ': 'ε',
    'Έ': 'Ε', 'Ἐ': 'Ε', 'Ἑ': 'Ε', 'Ἒ': 'Ε', 'Ἓ': 'Ε', 'Ἔ': 'Ε', 'Ἕ': 'Ε',
    'Ὲ': 'Ε',
    
    'ή': 'η', 'ἠ': 'η', 'ἡ': 'η', 'ἢ': 'η', 'ἣ': 'η', 'ἤ': 'η', 'ἥ': 'η', 'ἦ': 'η', 'ἧ': 'η',
    'ῃ': 'η', 'ῂ': 'η', 'ῄ': 'η', 'ῆ': 'η', 'ῇ': 'η',
    'Ή': 'Η', 'Ἠ': 'Η', 'Ἡ': 'Η', 'Ἢ': 'Η', 'Ἣ': 'Η', 'Ἤ': 'Η', 'Ἥ': 'Η', 'Ἦ': 'Η', 'Ἧ': 'Η',
    'ᾘ': 'Η', 'ᾙ': 'Η', 'ᾚ': 'Η', 'ᾛ': 'Η', 'ᾜ': 'Η', 'ᾝ': 'Η', 'ᾞ': 'Η', 'ᾟ': 'Η',
    'Ὴ': 'Η', 'ῌ': 'Η',
    
    'ί': 'ι', 'ἰ': 'ι', 'ἱ': 'ι', 'ἲ': 'ι', 'ἳ': 'ι', 'ἴ': 'ι', 'ἵ': 'ι', 'ἶ': 'ι', 'ἷ': 'ι',
    'ῐ': 'ι', 'ῑ': 'ι', 'ῒ': 'ι', 'ΐ': 'ι', 'ῖ': 'ι', 'ῗ': 'ι',
    'Ί': 'Ι', 'Ἰ': 'Ι', 'Ἱ': 'Ι', 'Ἲ': 'Ι', 'Ἳ': 'Ι', 'Ἴ': 'Ι', 'Ἵ': 'Ι', 'Ἶ': 'Ι', 'Ἷ': 'Ι',
    'Ῐ': 'Ι', 'Ῑ': 'Ι', 'Ὶ': 'Ι',
    
    'ό': 'ο', 'ὀ': 'ο', 'ὁ': 'ο', 'ὂ': 'ο', 'ὃ': 'ο', 'ὄ': 'ο', 'ὅ': 'ο',
    'Ό': 'Ο', 'Ὀ': 'Ο', 'Ὁ': 'Ο', 'Ὂ': 'Ο', 'Ὃ': 'Ο', 'Ὄ': 'Ο', 'Ὅ': 'Ο',
    'Ὸ': 'Ο',
    
    'ύ': 'υ', 'ὐ': 'υ', 'ὑ': 'υ', 'ὒ': 'υ', 'ὓ': 'υ', 'ὔ': 'υ', 'ὕ': 'υ', 'ὖ': 'υ', 'ὗ': 'υ',
    'ῠ': 'υ', 'ῡ': 'υ', 'ῢ': 'υ', 'ΰ': 'υ', 'ῦ': 'υ', 'ῧ': 'υ',
    'Ύ': 'Υ', 'Ὑ': 'Υ', 'Ὓ': 'Υ', 'Ὕ': 'Υ', 'Ὗ': 'Υ',
    'Ῠ': 'Υ', 'Ῡ': 'Υ', 'Ὺ': 'Υ',
    
    'ώ': 'ω', 'ὠ': 'ω', 'ὡ': 'ω', 'ὢ': 'ω', 'ὣ': 'ω', 'ὤ': 'ω', 'ὥ': 'ω', 'ὦ': 'ω', 'ὧ': 'ω',
    'ῳ': 'ω', 'ῲ': 'ω', 'ῴ': 'ω', 'ῶ': 'ω', 'ῷ': 'ω',
    'Ώ': 'Ω', 'Ὠ': 'Ω', 'Ὡ': 'Ω', 'Ὢ': 'Ω', 'Ὣ': 'Ω', 'Ὤ': 'Ω', 'Ὥ': 'Ω', 'Ὦ': 'Ω', 'Ὧ': 'Ω',
    'ᾨ': 'Ω', 'ᾩ': 'Ω', 'ᾪ': 'Ω', 'ᾫ': 'Ω', 'ᾬ': 'Ω', 'ᾭ': 'Ω', 'ᾮ': 'Ω', 'ᾯ': 'Ω',
    'Ὼ': 'Ω', 'ῼ': 'Ω',
    
    // Greek consonants with diacritics
    'ῤ': 'ρ', 'ῥ': 'ρ', 'Ῥ': 'Ρ',
  };

  static const Map<String, String> _arabicDiacritics = {
    // Arabic tashkeel (diacritics)
    'ً': '', // tanween fath
    'ٌ': '', // tanween dam
    'ٍ': '', // tanween kasr
    'َ': '', // fatha
    'ُ': '', // damma
    'ِ': '', // kasra
    'ّ': '', // shadda
    'ْ': '', // sukun
    'ٰ': '', // alef khanjariyyah
    'ٱ': 'ا', // alef wasla
    'آ': 'ا', // alef with madda
    'أ': 'ا', // alef with hamza above
    'إ': 'ا', // alef with hamza below
    'ء': '', // hamza
    'ؤ': 'و', // waw with hamza above
    'ئ': 'ي', // yeh with hamza above
    'ة': 'ه', // teh marbuta
    'ى': 'ي', // alef maksura
  };

  static const Map<String, String> _latinDiacritics = {
    // Latin vowels with diacritics
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ă': 'a', 'ą': 'a',
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A', 'Ā': 'A', 'Ă': 'A', 'Ą': 'A',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e', 'ě': 'e',
    'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E', 'Ĕ': 'E', 'Ė': 'E', 'Ę': 'E', 'Ě': 'E',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'ĭ': 'i', 'į': 'i', 'ĩ': 'i',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I', 'Ī': 'I', 'Ĭ': 'I', 'Į': 'I', 'Ĩ': 'I',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ō': 'o', 'ŏ': 'o', 'ő': 'o', 'ø': 'o',
    'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O', 'Ō': 'O', 'Ŏ': 'O', 'Ő': 'O', 'Ø': 'O',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ŭ': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u', 'ũ': 'u',
    'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', 'Ū': 'U', 'Ŭ': 'U', 'Ů': 'U', 'Ű': 'U', 'Ų': 'U', 'Ũ': 'U',
    'ỳ': 'y', 'ý': 'y', 'ŷ': 'y', 'ÿ': 'y', 'ȳ': 'y', 'ỹ': 'y',
    'Ỳ': 'Y', 'Ý': 'Y', 'Ŷ': 'Y', 'Ÿ': 'Y', 'Ȳ': 'Y', 'Ỹ': 'Y',
    
    // Latin consonants with diacritics
    'ç': 'c', 'ć': 'c', 'ĉ': 'c', 'ċ': 'c', 'č': 'c',
    'Ç': 'C', 'Ć': 'C', 'Ĉ': 'C', 'Ċ': 'C', 'Č': 'C',
    'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n', 'ṅ': 'n', 'ṇ': 'n', 'ṉ': 'n', 'ṋ': 'n',
    'Ñ': 'N', 'Ń': 'N', 'Ň': 'N', 'Ņ': 'N', 'Ṅ': 'N', 'Ṇ': 'N', 'Ṉ': 'N', 'Ṋ': 'N',
  };

  /// Removes diacritics from Greek text
  static String removeGreekDiacritics(String text) {
    String result = text;
    for (final entry in _greekDiacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Removes diacritics from Arabic text
  static String removeArabicDiacritics(String text) {
    String result = text;
    for (final entry in _arabicDiacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Removes diacritics from Latin text
  static String removeLatinDiacritics(String text) {
    String result = text;
    for (final entry in _latinDiacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Removes diacritics from text in all supported languages
  static String removeAllDiacritics(String text) {
    String result = text;
    result = removeGreekDiacritics(result);
    result = removeArabicDiacritics(result);
    result = removeLatinDiacritics(result);
    return result;
  }

  /// Normalizes text for word comparison by removing diacritics and converting to lowercase
  static String normalizeForComparison(String text) {
    return removeAllDiacritics(text).toLowerCase().trim();
  }

  /// Detects the primary script of the text
  static String detectScript(String text) {
    if (text.isEmpty) return 'unknown';
    
    int greekCount = 0;
    int arabicCount = 0;
    int latinCount = 0;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      
      // Greek and Coptic block: U+0370-U+03FF
      // Greek Extended block: U+1F00-U+1FFF
      if ((code >= 0x0370 && code <= 0x03FF) || (code >= 0x1F00 && code <= 0x1FFF)) {
        greekCount++;
      }
      // Arabic block: U+0600-U+06FF
      // Arabic Supplement: U+0750-U+077F
      else if ((code >= 0x0600 && code <= 0x06FF) || (code >= 0x0750 && code <= 0x077F)) {
        arabicCount++;
      }
      // Basic Latin: U+0000-U+007F
      // Latin-1 Supplement: U+0080-U+00FF
      // Latin Extended-A: U+0100-U+017F
      // Latin Extended-B: U+0180-U+024F
      else if ((code >= 0x0041 && code <= 0x007A) || 
               (code >= 0x0080 && code <= 0x024F)) {
        latinCount++;
      }
    }
    
    if (greekCount > arabicCount && greekCount > latinCount) {
      return 'greek';
    } else if (arabicCount > greekCount && arabicCount > latinCount) {
      return 'arabic';
    } else if (latinCount > greekCount && latinCount > arabicCount) {
      return 'latin';
    }
    
    return 'mixed';
  }
}