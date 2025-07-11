enum LanguageType {
  greek,
  arabic,
}

class Language {
  final LanguageType type;
  final String name;
  final String nativeName;
  final String code;
  final bool isRtl;
  final String? fontFamily;

  const Language({
    required this.type,
    required this.name,
    required this.nativeName,
    required this.code,
    required this.isRtl,
    this.fontFamily,
  });

  static const List<Language> supportedLanguages = [
    Language(
      type: LanguageType.greek,
      name: 'Greek',
      nativeName: 'Greek',
      code: 'grc',
      isRtl: false,
    ),
    Language(
      type: LanguageType.arabic,
      name: 'Arabic',
      nativeName: 'Arabic',
      code: 'ar',
      isRtl: true,
    ),
  ];

  static Language fromType(LanguageType type) {
    return supportedLanguages.firstWhere((lang) => lang.type == type);
  }
}