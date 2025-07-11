class DictionaryEntry {
  final String word;
  final String lemma;
  final List<Definition> definitions;
  final List<String> etymologies;
  final MorphologicalInfo? morphology;
  final String? pronunciation;
  final String source;

  const DictionaryEntry({
    required this.word,
    required this.lemma,
    required this.definitions,
    this.etymologies = const [],
    this.morphology,
    this.pronunciation,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'lemma': lemma,
      'definitions': definitions.map((d) => d.toJson()).toList(),
      'etymologies': etymologies,
      'morphology': morphology?.toJson(),
      'pronunciation': pronunciation,
      'source': source,
    };
  }

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word'],
      lemma: json['lemma'],
      definitions: (json['definitions'] as List)
          .map((d) => Definition.fromJson(d))
          .toList(),
      etymologies: List<String>.from(json['etymologies'] ?? []),
      morphology: json['morphology'] != null
          ? MorphologicalInfo.fromJson(json['morphology'])
          : null,
      pronunciation: json['pronunciation'],
      source: json['source'],
    );
  }
}

class Definition {
  final String text;
  final String? partOfSpeech;
  final List<String> examples;
  final String? register; // formal, colloquial, etc.
  final bool isMorphological; // true if this is a morphological description
  final String? referencedLemma; // the lemma this morphological form refers to
  final List<Definition> lemmaDefinitions; // definitions of the referenced lemma

  const Definition({
    required this.text,
    this.partOfSpeech,
    this.examples = const [],
    this.register,
    this.isMorphological = false,
    this.referencedLemma,
    this.lemmaDefinitions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'partOfSpeech': partOfSpeech,
      'examples': examples,
      'register': register,
      'isMorphological': isMorphological,
      'referencedLemma': referencedLemma,
      'lemmaDefinitions': lemmaDefinitions.map((d) => d.toJson()).toList(),
    };
  }

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      text: json['text'],
      partOfSpeech: json['partOfSpeech'],
      examples: List<String>.from(json['examples'] ?? []),
      register: json['register'],
      isMorphological: json['isMorphological'] ?? false,
      referencedLemma: json['referencedLemma'],
      lemmaDefinitions: (json['lemmaDefinitions'] as List? ?? [])
          .map((d) => Definition.fromJson(d))
          .toList(),
    );
  }
}

class MorphologicalInfo {
  final String? partOfSpeech;
  final String? case_;
  final String? number;
  final String? gender;
  final String? tense;
  final String? voice;
  final String? mood;
  final String? person;
  final String? degree; // for adjectives
  final Map<String, String> additionalFeatures;

  const MorphologicalInfo({
    this.partOfSpeech,
    this.case_,
    this.number,
    this.gender,
    this.tense,
    this.voice,
    this.mood,
    this.person,
    this.degree,
    this.additionalFeatures = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'partOfSpeech': partOfSpeech,
      'case': case_,
      'number': number,
      'gender': gender,
      'tense': tense,
      'voice': voice,
      'mood': mood,
      'person': person,
      'degree': degree,
      'additionalFeatures': additionalFeatures,
    };
  }

  factory MorphologicalInfo.fromJson(Map<String, dynamic> json) {
    return MorphologicalInfo(
      partOfSpeech: json['partOfSpeech'],
      case_: json['case'],
      number: json['number'],
      gender: json['gender'],
      tense: json['tense'],
      voice: json['voice'],
      mood: json['mood'],
      person: json['person'],
      degree: json['degree'],
      additionalFeatures: Map<String, String>.from(json['additionalFeatures'] ?? {}),
    );
  }

  String get displayText {
    final parts = <String>[];
    
    if (partOfSpeech != null) parts.add(partOfSpeech!);
    if (case_ != null) parts.add(case_!);
    if (number != null) parts.add(number!);
    if (gender != null) parts.add(gender!);
    if (tense != null) parts.add(tense!);
    if (voice != null) parts.add(voice!);
    if (mood != null) parts.add(mood!);
    if (person != null) parts.add('${person!} person');
    if (degree != null) parts.add(degree!);
    
    return parts.join(', ');
  }
}